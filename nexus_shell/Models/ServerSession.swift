//
//  ServerSession.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
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
    @Published var connectionMode: SSHConnectionMode = .simulated

    let createdAt: Date

    /// 终端输出缓冲区常量
    private enum TerminalConstants {
        static let outputBufferLimit = 100000
        static let outputBufferTrimPoint = 50000
        static let commandHistoryLimit = 100
    }

    #if canImport(NMSSH)
    private(set) var realSSHConnection: RealSSHConnection?
    #endif
    private var simulatedSSHConnection: SSHConnection?

    private let monitor = ServerMonitor()
    @Published var isMonitoring: Bool = false

    private var sshConfig: SSHConfig
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts: Int = 0

    /// 命令历史持久化键
    private var commandHistoryKey: String {
        "commandHistory_\(server.id.uuidString)"
    }

    enum SSHConnectionMode {
        #if canImport(NMSSH)
        case real
        #endif
        case simulated
    }

    init(server: Server) {
        self.server = server
        self.createdAt = Date()
        self.sshConfig = AppSettings.shared.defaultSSHConfig

        // 加载持久化的命令历史
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
            let mode = AppSettings.shared.sshMode

            if mode == .simulated {
                try await connectSimulated()
            } else {
                try await connectWithFallback()
            }
        } catch {
            state = .error(error.localizedDescription)
            appendOutput("Connection failed: \(error.localizedDescription)\n")
            server.status = .offline
        }
    }

    private func connectSimulated() async throws {
        simulatedSSHConnection = try await SSHClientManager.shared.createConnection(
            host: server.host,
            port: server.port,
            username: server.username,
            authMethod: server.authMethod,
            serverId: server.id
        )

        await simulatedSSHConnection?.setOutputHandler { [weak self] output in
            Task { @MainActor [weak self] in
                self?.appendOutput(output)
            }
        }

        state = .connected
        connectionMode = .simulated
        appendOutput("Connected (Simulated Mode).\n")

        server.status = .online
        server.lastConnectedAt = Date()
        reconnectAttempts = 0
        startMonitoring()
    }

    private func connectWithFallback() async throws {
        do {
            let mode = try await SSHClientManager.shared.createConnection(
                host: server.host,
                port: server.port,
                username: server.username,
                authMethod: server.authMethod,
                serverId: server.id,
                config: sshConfig
            )

            switch mode {
            #if canImport(NMSSH)
            case .real(let connection):
                realSSHConnection = connection
                connectionMode = .real
                await setupRealConnection()
            #endif
            case .simulated(let connection):
                simulatedSSHConnection = connection
                connectionMode = .simulated
                await setupSimulatedConnection()
            }
        } catch {
            appendOutput("Real SSH connection failed, trying simulated mode...\n")
            try await connectSimulated()
        }
    }

    #if canImport(NMSSH)
    private func setupRealConnection() async {
        guard let connection = realSSHConnection else { return }

        await connection.setOutputHandler { [weak self] output in
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
    }
    #endif

    private func setupSimulatedConnection() async {
        guard let connection = simulatedSSHConnection else { return }

        await connection.setOutputHandler { [weak self] output in
            Task { @MainActor [weak self] in
                self?.appendOutput(output)
            }
        }

        state = .connected
        appendOutput("Connected (Simulated Mode).\n")

        server.status = .online
        server.lastConnectedAt = Date()
        reconnectAttempts = 0
        startMonitoring()
    }

    // MARK: - Disconnect

    func disconnect() {
        guard state != .disconnected else { return }

        isMonitoring = false
        reconnectTask?.cancel()
        reconnectTask = nil

        Task {
            await monitor.stopMonitoring(server.id)
            #if canImport(NMSSH)
            await realSSHConnection?.disconnect()
            #endif
            await simulatedSSHConnection?.disconnect()
        }

        #if canImport(NMSSH)
        realSSHConnection = nil
        #endif
        simulatedSSHConnection = nil

        state = .disconnected
        appendOutput("\nConnection closed.\n")

        server.status = .unknown

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

            // 保存命令历史到 UserDefaults
            Self.saveCommandHistory(commandHistory, for: server.id)
        }

        appendOutput("$ " + command.trimmingCharacters(in: .whitespacesAndNewlines) + "\n")

        Task {
            do {
                switch connectionMode {
                #if canImport(NMSSH)
                case .real:
                    if let connection = realSSHConnection {
                        _ = try await connection.execute(command: command)
                    }
                #endif
                case .simulated:
                    if let connection = simulatedSSHConnection {
                        _ = try await connection.execute(command: command)
                    }
                }
            } catch {
                appendOutput("Error: \(error.localizedDescription)\n")
                await handleConnectionError(error)
            }
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

                await reconnect()
            } catch {
                // Reconnect cancelled or failed
            }
        }
    }

    private func reconnect() async {
        do {
            switch connectionMode {
            #if canImport(NMSSH)
            case .real:
                if let connection = realSSHConnection {
                    try await connection.reconnect()
                    await setupRealConnection()
                }
            #endif
            case .simulated:
                if let connection = simulatedSSHConnection {
                    try await connection.connect()
                    await setupSimulatedConnection()
                }
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

        Task {
            switch connectionMode {
            #if canImport(NMSSH)
            case .real:
                if let connection = realSSHConnection {
                    await monitor.startMonitoring(serverId: server.id, realConnection: connection)
                }
            #endif
            case .simulated:
                if let connection = simulatedSSHConnection {
                    await monitor.startMonitoring(serverId: server.id, simulatedConnection: connection)
                }
            }
        }
    }

    // MARK: - Terminal

    func clearTerminal() {
        outputBuffer = ""
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
        // 保留最近 100 条命令历史
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
