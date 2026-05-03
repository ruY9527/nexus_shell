//
//  RealSSHConnection.swift
//  nexus_shell
//
//  Created by opencode on 2026-05-03.
//

import Foundation
#if canImport(NMSSH)
import NMSSH
#endif

// MARK: - RealSSHConnection (NMSSH-based)

#if canImport(NMSSH)

/// Shell 输出代理
class ShellOutputDelegate: NSObject, NMSSHChannelDelegate {
    var onData: ((String) -> Void)?

    func channel(_ channel: NMSSHChannel, didReadData message: String) {
        onData?(message)
    }

    func channel(_ channel: NMSSHChannel, didReadError error: String) {
        onData?(error)
    }

    func channelShellDidClose(_ channel: NMSSHChannel) {
        // Shell closed
    }
}

/// 真实 SSH 连接类 (NMSSH)
actor RealSSHConnection {

    // MARK: - Properties

    let host: String
    let port: Int
    let authConfig: SSHAuthConfig
    let serverId: UUID
    var config: SSHConfig

    private var session: NMSSHSession?
    private var channel: NMSSHChannel?
    private var _isConnected: Bool = false
    private var _currentDirectory: String = ""
    private let homeDirectory: String
    private var outputHandler: ((String) -> Void)?
    private var shellStarted: Bool = false
    private let shellDelegate = ShellOutputDelegate()

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
        _isConnected && (session?.isConnected ?? false)
    }

    var currentDirectory: String {
        _currentDirectory
    }

    // MARK: - Connection Management

    func connect() async throws {
        guard !isConnected else { return }

        let handler = outputHandler
        await MainActor.run {
            handler?("Connecting to \(self.host):\(self.port)...\n")
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    let session = NMSSHSession(host: self.host, andUsername: self.authConfig.username)

                    guard session.connect() else {
                        continuation.resume(throwing: SSHError.connectionFailed("Cannot connect to \(self.host):\(self.port)"))
                        return
                    }

                    self.session = session
                    self.channel = session.channel

                    do {
                        try self.authenticate(session: session)
                        self._isConnected = true
                        self._currentDirectory = self.homeDirectory
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            _isConnected = false
            throw error
        }

        let handler2 = outputHandler
        await MainActor.run {
            handler2?("Connection established.\n")
        }
    }

    private func authenticate(session: NMSSHSession) throws {
        var authenticated = false

        switch authConfig.method {
        case .password:
            if let password = authConfig.password {
                authenticated = session.authenticate(byPassword: password)
            } else {
                throw SSHError.authenticationFailed("Password not provided")
            }

        case .privateKey:
            if let privateKey = authConfig.privateKey {
                let passphrase = authConfig.passphrase
                authenticated = session.authenticateBy(inMemoryPublicKey: "", privateKey: privateKey, andPassword: passphrase)
            } else {
                throw SSHError.authenticationFailed("Private key not provided")
            }
        }

        guard authenticated else {
            throw SSHError.authenticationFailed("Authentication failed for user \(authConfig.username)")
        }
    }

    func disconnect() {
        guard let session = session else { return }

        if shellStarted {
            channel?.closeShell()
            shellStarted = false
        }

        session.disconnect()
        _isConnected = false
        self.session = nil
        self.channel = nil

        let handler = outputHandler
        Task { @MainActor in
            handler?("Connection closed.\n")
        }
    }

    // MARK: - Command Execution

    func execute(command: String) async throws -> String {
        guard isConnected, let channel = channel else {
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

        let handler = outputHandler

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var err: NSError?
                let response = channel.execute(trimmedCommand, error: &err)

                if let err = err {
                    continuation.resume(throwing: SSHError.commandFailed(err.localizedDescription))
                    return
                }

                let output = response
                DispatchQueue.main.async {
                    handler?(output)
                }
                continuation.resume(returning: output)
            }
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
        guard isConnected, let channel = channel else {
            throw SSHError.disconnected
        }

        channel.requestPty = true
        channel.ptyTerminalType = config.terminalType.nmsshPtyType

        let handler = outputHandler
        shellDelegate.onData = { data in
            Task { @MainActor in
                handler?(data)
            }
        }
        channel.delegate = shellDelegate

        do {
            try channel.startShell()
        } catch {
            throw SSHError.commandFailed("Failed to start shell: \(error.localizedDescription)")
        }

        shellStarted = true

        await MainActor.run {
            handler?("Interactive shell started.\n")
        }
    }

    func sendInput(_ input: String) {
        guard shellStarted, let channel = channel else { return }
        try? channel.write(input)
    }

    func closeShell() {
        shellStarted = false
        channel?.closeShell()
    }

    func resizeTerminal(width: Int, height: Int) {
        guard shellStarted, let channel = channel else { return }
        _ = channel.requestSizeWidth(UInt(width), height: UInt(height))
    }

    // MARK: - Output Handler

    func setOutputHandler(_ handler: @escaping (String) -> Void) {
        self.outputHandler = handler
    }

    // MARK: - SFTP Support

    func getNMSSHSession() -> NMSSHSession? {
        return session
    }

    // MARK: - Connection Quality

    func sendKeepAlive() async -> Bool {
        guard isConnected else { return false }
        do {
            let response = try await execute(command: "echo keepalive")
            return response.contains("keepalive")
        } catch {
            return false
        }
    }

    func checkConnection() -> Bool {
        return isConnected
    }

    // MARK: - Reconnection

    func reconnect() async throws {
        disconnect()
        try await Task.sleep(for: .milliseconds(Int(config.reconnectDelay * 1000)))
        try await connect()
    }

    func reconnectWithRetry() async throws {
        var attempts = 0
        while attempts < config.maxReconnectAttempts {
            attempts += 1
            do {
                try await reconnect()
                return
            } catch {
                let handler = outputHandler
                let maxAttempts = config.maxReconnectAttempts
                await MainActor.run {
                    handler?("Reconnect attempt \(attempts)/\(maxAttempts) failed: \(error.localizedDescription)\n")
                }
                if attempts < config.maxReconnectAttempts {
                    let delay = config.reconnectDelay * Double(attempts)
                    try await Task.sleep(for: .seconds(delay))
                }
            }
        }
        throw SSHError.connectionFailed("Failed to reconnect after \(config.maxReconnectAttempts) attempts")
    }
}

// MARK: - Connection Info

extension RealSSHConnection {
    func getConnectionInfo() -> ConnectionInfo {
        ConnectionInfo(
            host: host,
            port: port,
            username: authConfig.username,
            isConnected: isConnected,
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

#endif
