//
//  ServerSession.swift
//  nexus_shell
//
//  SSH Session Manager
//

import Foundation
import SwiftUI
import Combine

/// SSH 会话状态
enum SessionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case error(String)

    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected):
            return true
        case (.connecting, .connecting):
            return true
        case (.connected, .connected):
            return true
        case (.reconnecting(let l1, let m1), .reconnecting(let l2, let m2)):
            return l1 == l2 && m1 == m2
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting(let attempt, let maxAttempts):
            return "Reconnecting (\(attempt)/\(maxAttempts))..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// SSH 会话管理类
/// 管理单个 SSH 连接的生命周期
@MainActor
class ServerSession: ObservableObject {
    let server: Server

    @Published var state: SessionState = .disconnected
    @Published var outputBuffer: String = ""
    @Published var commandHistory: [String] = []
    @Published var isShellActive: Bool = false

    let createdAt: Date

    /// 终端输出缓冲区常量
    private enum TerminalConstants {
        static let outputBufferLimit = 100000
        static let outputBufferTrimPoint = 50000
        static let commandHistoryLimit = 100
    }

    private(set) var sshConnection: RealSSHConnection?

    private let monitor = ServerMonitor()
    @Published var isMonitoring: Bool = false

    private var sshConfig: SSHConfig
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts: Int = 0

    /// 命令历史持久化键
    private var commandHistoryKey: String {
        "commandHistory_\(server.id.uuidString)"
    }

    init(server: Server) {
        self.server = server
        self.createdAt = Date()
        self.sshConfig = AppSettings.shared.defaultSSHConfig

        self.commandHistory = Self.loadCommandHistory(for: server.id)

        outputBuffer = """
        ┌─────────────────────────────────────────┐
        │  Nexus Shell - SSH Terminal             │
        │  Server: \(server.name)
        │  Host: \(server.displayAddress)
        └─────────────────────────────────────────┘

        """

        Task { [weak self] in
            guard let self else { return }
            await self.monitor.setUpdateHandler { [weak self] update in
                Task { @MainActor [weak self] in
                    guard let self, self.server.id == update.serverId else { return }

                    self.server.cpuUsage = update.cpuUsage
                    self.server.memoryUsage = update.memoryUsage
                    self.server.status = update.status
                }
            }
        }
    }

    // MARK: - Connection

    func connect() async {
        guard state != .connected && state != .connecting else { return }

        state = .connecting
        appendOutput("Connecting to \(server.host)...\n")

        do {
            let connection = try SSHClientManager.shared.createConnection(
                host: server.host,
                port: server.port,
                username: server.username,
                authMethod: server.authMethod,
                serverId: server.id,
                config: sshConfig
            )

            sshConnection = connection
            setupConnection()

        } catch {
            state = .error(error.localizedDescription)
            appendOutput("Connection failed: \(error.localizedDescription)\n")
            server.status = .offline
            LogStore.shared.logConnection(serverId: server.id, serverName: server.name, success: false)
        }
    }

    private func setupConnection() {
        guard let connection = sshConnection else { return }

        connection.setOutputHandler { [weak self] output in
            Task { @MainActor [weak self] in
                self?.appendOutput(output)
            }
        }

        state = .connected
        appendOutput("Connected (Real SSH).\n")

        server.status = .online
        server.lastConnectedAt = Date()
        reconnectAttempts = 0
        startMonitoring()
        LogStore.shared.logConnection(serverId: server.id, serverName: server.name, success: true)

        do {
            try connection.startShell()
            isShellActive = true
            appendOutput("Interactive shell started.\n")
        } catch {
            appendOutput("Warning: Failed to start interactive shell: \(error.localizedDescription)\n")
            appendOutput("Falling back to command execution mode.\n")
        }
    }

    // MARK: - Disconnect

    func disconnect() {
        guard state != .disconnected else { return }

        isMonitoring = false
        reconnectTask?.cancel()
        reconnectTask = nil

        if isShellActive {
            sshConnection?.closeShell()
        }
        sshConnection?.disconnect()

        isShellActive = false
        sshConnection = nil

        state = .disconnected
        appendOutput("\nConnection closed.\n")

        server.status = .unknown
        LogStore.shared.logDisconnect(serverId: server.id, serverName: server.name)

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Command Execution

    func sendCommand(_ command: String) {
        guard state == .connected else {
            appendOutput("Error: Not connected to server.\n")
            return
        }

        if !command.isEmpty && command != "\n" {
            let trimmedCommand = command.trimmingCharacters(in: .newlines)
            commandHistory.append(trimmedCommand)

            Self.saveCommandHistory(commandHistory, for: server.id)
        }

        if isShellActive {
            sshConnection?.sendInput(command + "\n")
        } else {
            if let connection = sshConnection {
                _ = try? connection.execute(command: command)
            }
        }

        LogStore.shared.logCommand(serverId: server.id, command: command)

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func sendKeyToSession(_ key: String) {
        guard state == .connected else { return }

        if isShellActive {
            sshConnection?.sendInput(key)
        }
    }

    // MARK: - Reconnection

    private func handleConnectionError(_ error: Error) async {
        guard sshConfig.autoReconnect, reconnectAttempts < sshConfig.maxReconnectAttempts else {
            return
        }

        reconnectAttempts += 1
        state = .reconnecting(attempt: reconnectAttempts, maxAttempts: sshConfig.maxReconnectAttempts)

        appendOutput("Connection lost. Reconnecting (\(reconnectAttempts)/\(sshConfig.maxReconnectAttempts))...\n")

        reconnectTask = Task {
            do {
                try await Task.sleep(for: .seconds(sshConfig.reconnectDelay))

                guard !Task.isCancelled else { return }

                reconnect()
            } catch {
                // Reconnect cancelled or failed
            }
        }
    }

    private func reconnect() {
        do {
            if let connection = sshConnection {
                try connection.reconnect()
                setupConnection()
            }
        } catch {
            state = .error("Reconnection failed: \(error.localizedDescription)")
            server.status = .offline
        }
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard state == .connected else { return }

        isMonitoring = true

        if let connection = sshConnection {
            Task {
                await monitor.startMonitoring(serverId: server.id, connection: connection)
            }
        }
    }

    // MARK: - Terminal

    func clearTerminal() {
        outputBuffer = ""
    }

    func resizeTerminal(width: Int, height: Int) {
        if isShellActive, let connection = sshConnection {
            connection.resizeTerminal(width: width, height: height)
        }
    }

    private func appendOutput(_ text: String) {
        outputBuffer += text

        if outputBuffer.count > TerminalConstants.outputBufferLimit {
            let startIndex = outputBuffer.index(outputBuffer.startIndex, offsetBy: TerminalConstants.outputBufferTrimPoint)
            outputBuffer = String(outputBuffer[startIndex...])
        }
    }

    // MARK: - Command History

    func getPreviousCommand() -> String? {
        if commandHistory.isEmpty { return nil }
        return commandHistory.last
    }

    func getCommand(at index: Int) -> String? {
        if index < 0 || index >= commandHistory.count { return nil }
        return commandHistory[commandHistory.count - 1 - index]
    }

    /// 加载命令历史
    private static func loadCommandHistory(for serverId: UUID) -> [String] {
        let key = "commandHistory_\(serverId.uuidString)"
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// 保存命令历史
    private static func saveCommandHistory(_ history: [String], for serverId: UUID) {
        let key = "commandHistory_\(serverId.uuidString)"
        let trimmedHistory = Array(history.suffix(100))
        UserDefaults.standard.set(trimmedHistory, forKey: key)
    }

    /// 清除命令历史
    func clearCommandHistory() {
        commandHistory = []
        let key = "commandHistory_\(server.id.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}
