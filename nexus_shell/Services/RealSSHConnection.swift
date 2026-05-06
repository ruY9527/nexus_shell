//
//  RealSSHConnection.swift
//  nexus_shell
//
//  SSH connection using Citadel library
//

import Foundation
import Citadel

/// 真实 SSH 连接类 (Citadel)
actor RealSSHConnection {

    // MARK: - Properties

    let host: String
    let port: Int
    let authConfig: SSHAuthConfig
    let serverId: UUID
    var config: SSHConfig

    private var client: SSHClient?
    private var _isConnected: Bool = false
    private var _currentDirectory: String = ""
    private let homeDirectory: String
    private var outputHandler: ((String) -> Void)?
    private var shellTask: Task<Void, Never>?
    private var ptyStdin: TTYStdinWriter?
    private var isShellActive: Bool = false

    // MARK: - Initialization

    init(
        host: String,
        port: Int,
        authConfig: SSHAuthConfig,
        serverId: UUID,
        config: SSHConfig = .default
    ) {
        self.host = host
        self.port = port
        self.authConfig = authConfig
        self.serverId = serverId
        self.config = config
        self.homeDirectory = "/home/\(authConfig.username)"
        self._currentDirectory = homeDirectory
    }

    // MARK: - Connection State

    var isConnected: Bool {
        _isConnected
    }

    var currentDirectory: String {
        _currentDirectory
    }

    // MARK: - Connection Management

    func connect() async throws {
        guard !_isConnected else { return }

        let handler = outputHandler
        await MainActor.run {
            handler?("Connecting to \(self.host):\(self.port)...\n")
        }

        do {
            let settings = SSHClientSettings(
                host: self.host,
                port: self.port,
                authenticationMethod: self.authConfig.citadelAuthMethod,
                hostKeyValidator: .acceptAnything()
            )

            self.client = try await SSHClient.connect(to: settings)
            self._isConnected = true
            self._currentDirectory = self.homeDirectory

            await MainActor.run {
                handler?("Connection established.\n")
            }
        } catch {
            self._isConnected = false
            throw SSHError.connectionFailed("Failed to connect: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        shellTask?.cancel()
        shellTask = nil

        if isShellActive {
            ptyStdin = nil
            isShellActive = false
        }

        client = nil
        _isConnected = false

        let handler = outputHandler
        Task { @MainActor in
            handler?("Connection closed.\n")
        }
    }

    // MARK: - Command Execution

    func execute(command: String) async throws -> String {
        guard let client = client, _isConnected else {
            throw SSHError.disconnected
        }

        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCommand.hasPrefix("cd ") {
            handleCDCommand(trimmedCommand)
            return ""
        }

        if trimmedCommand == "clear" {
            return "\u{001B}[2J\u{001B}[H"
        }

        do {
            let output = try await client.executeCommand(trimmedCommand)
            let handler = outputHandler
            await MainActor.run {
                handler?(output + "\n")
            }
            return output
        } catch {
            throw SSHError.commandFailed(error.localizedDescription)
        }
    }

    private func handleCDCommand(_ command: String) {
        let path = command.dropFirst(3).trimmingCharacters(in: .whitespaces)

        if path == ".." {
            let components = _currentDirectory.split(separator: "/")
            if components.count > 1 {
                _currentDirectory = "/" + components.dropLast().joined(separator: "/")
                if _currentDirectory.isEmpty { _currentDirectory = "/" }
            }
        } else if path == "/" {
            _currentDirectory = "/"
        } else if path == "~" || path.isEmpty {
            _currentDirectory = homeDirectory
        } else if path.hasPrefix("/") {
            _currentDirectory = path
        } else {
            _currentDirectory = _currentDirectory + "/" + path
        }
    }

    // MARK: - PTY / Shell

    func startShell() async throws {
        guard let client = client, _isConnected else {
            throw SSHError.disconnected
        }

        let handler = outputHandler

        do {
            try await client.withPTY(
                SSHChannelRequestEvent.PseudoTerminalRequest(
                    wantReply: true,
                    term: "xterm-256color",
                    terminalCharacterWidth: 80,
                    terminalRowHeight: 24,
                    terminalPixelWidth: 0,
                    terminalPixelHeight: 0,
                    terminalModes: .init([.ECHO: 1, .ICANON: 1])
                )
            ) { [weak self] ttyOutput, ttyStdinWriter in
                guard let self = self else { return }

                Task { @MainActor [weak self] in
                    handler?("Interactive shell started.\n")
                }

                Task {
                    for try await data in ttyOutput {
                        if let str = String(data: data, encoding: .utf8) {
                            let h = self.outputHandler
                            await MainActor.run {
                                h?(str)
                            }
                        }
                    }
                }

                self.ptyStdin = ttyStdinWriter
                self.isShellActive = true
            }
        } catch {
            throw SSHError.commandFailed("Failed to start shell: \(error.localizedDescription)")
        }
    }

    func sendInput(_ input: String) {
        guard isShellActive, let stdin = ptyStdin else { return }
        try? stdin.write(ByteBuffer(string: input))
    }

    func closeShell() {
        ptyStdin = nil
        isShellActive = false
        shellTask?.cancel()
    }

    func resizeTerminal(width: Int, height: Int) {
        guard isShellActive, let stdin = ptyStdin else { return }
        try? stdin.changeSize(terminalCharacterWidth: UInt32(width), terminalRowHeight: UInt32(height))
    }

    // MARK: - Output Handler

    func setOutputHandler(_ handler: @escaping (String) -> Void) {
        self.outputHandler = handler
    }

    // MARK: - Connection Quality

    func sendKeepAlive() async -> Bool {
        guard _isConnected else { return false }
        do {
            let response = try await client?.executeCommand("echo keepalive")
            return response?.contains("keepalive") ?? false
        } catch {
            return false
        }
    }

    func checkConnection() -> Bool {
        return _isConnected
    }

    // MARK: - Reconnection

    func reconnect() async throws {
        disconnect()
        try await Task.sleep(for: .milliseconds(Int(config.reconnectDelay * 1000)))
        try await connect()
    }
}

// MARK: - Connection Info

extension RealSSHConnection {
    func getConnectionInfo() -> ConnectionInfo {
        ConnectionInfo(
            host: host,
            port: port,
            username: authConfig.username,
            isConnected: _isConnected,
            currentDirectory: _currentDirectory
        )
    }

    struct ConnectionInfo {
        let host: String
        let port: Int
        let username: String
        let isConnected: Bool
        let currentDirectory: String
    }
}

// MARK: - SSHAuthConfig Extension

extension SSHAuthConfig {
    var citadelAuthMethod: Citadel.AuthenticationMethod {
        switch self.method {
        case .password:
            if let password = self.password {
                return .passwordBased(username: self.username, password: password)
            } else {
                return .passwordBased(username: self.username, password: "")
            }
        case .privateKey:
            if let privateKey = self.privateKey {
                return .privateKeyBased(username: self.username, privateKey: privateKey, passphrase: self.passphrase ?? "")
            } else {
                return .passwordBased(username: self.username, password: "")
            }
        }
    }
}
