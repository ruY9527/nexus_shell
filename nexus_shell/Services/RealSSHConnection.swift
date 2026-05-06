//
//  RealSSHConnection.swift
//  nexus_shell
//
//  SSH connection using NMSSH library
//

import Foundation
#if canImport(NMSSH)
import NMSSH
#endif

/// 真实 SSH 连接类 (NMSSH)
class RealSSHConnection: NSObject {

    // MARK: - Properties

    let host: String
    let port: Int
    let authConfig: SSHAuthConfig
    let serverId: UUID
    var config: SSHConfig

    #if canImport(NMSSH)
    private var session: NMSSHSession?
    private var channel: NMSSHChannel?
    #endif
    private var _isConnected: Bool = false
    private var _currentDirectory: String = ""
    private let homeDirectory: String
    private var outputHandler: ((String) -> Void)?
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
        super.init()
    }

    // MARK: - Connection State

    var isConnected: Bool {
        _isConnected
    }

    var currentDirectory: String {
        _currentDirectory
    }

    // MARK: - Connection Management

    func connect() throws {
        #if canImport(NMSSH)
        guard !_isConnected else { return }

        outputHandler?("Connecting to \(self.host):\(self.port)...\n")

        let newSession = NMSSHSession(host: host, port: port, andUsername: authConfig.username)
        newSession.delegate = self
        newSession.connect()

        guard newSession.isConnected else {
            _isConnected = false
            throw SSHError.connectionFailed("Failed to connect to \(host):\(port)")
        }

        var authenticated = false
        switch authConfig.method {
        case .password:
            if let password = authConfig.password {
                authenticated = newSession.authenticate(byPassword: password)
            }
        case .privateKey:
            if let privateKey = authConfig.privateKey {
                authenticated = newSession.authenticateBy(inMemoryPublicKey: "", privateKey: privateKey, andPassword: authConfig.passphrase)
            }
        }

        guard authenticated else {
            _isConnected = false
            throw SSHError.authenticationFailed("Authentication failed")
        }

        self.session = newSession
        self.channel = newSession.channel
        self.channel?.delegate = self
        self._isConnected = true
        self._currentDirectory = homeDirectory

        outputHandler?("Connection established.\n")
        #else
        throw SSHError.connectionFailed("NMSSH module is not available. Open nexus_shell.xcworkspace and run pod install before building.")
        #endif
    }

    func disconnect() {
        #if canImport(NMSSH)
        if isShellActive {
            closeShell()
        }

        channel = nil
        session?.disconnect()
        session = nil
        _isConnected = false

        outputHandler?("Connection closed.\n")
        #else
        _isConnected = false
        outputHandler?("Connection closed.\n")
        #endif
    }

    // MARK: - Command Execution

    func execute(command: String) throws -> String {
        #if canImport(NMSSH)
        guard let channel = channel, _isConnected else {
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

        channel.requestPty = false

        var error: NSError?
        let result = channel.execute(trimmedCommand, error: &error)

        if let error = error {
            throw SSHError.commandFailed(error.localizedDescription)
        }

        outputHandler?(result + "\n")
        return result
        #else
        throw SSHError.connectionFailed("NMSSH module is not available")
        #endif
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

        #if canImport(NMSSH)
        if let channel = channel {
            var error: NSError?
            channel.execute("cd \(_currentDirectory)", error: &error)
        }
        #endif
    }

    // MARK: - PTY / Shell

    func startShell() throws {
        #if canImport(NMSSH)
        guard let channel = channel, _isConnected else {
            throw SSHError.disconnected
        }

        channel.requestPty = true

        try channel.startShell()

        isShellActive = true

        outputHandler?("Interactive shell started.\n")
        #else
        throw SSHError.connectionFailed("NMSSH module is not available")
        #endif
    }

    func sendInput(_ input: String) {
        #if canImport(NMSSH)
        guard isShellActive, let channel = channel else { return }
        var error: NSError?
        channel.write(input, error: &error, timeout: NSNumber(value: 1.0))
        #endif
    }

    func closeShell() {
        #if canImport(NMSSH)
        channel?.closeShell()
        #endif
        isShellActive = false
    }

    func resizeTerminal(width: Int, height: Int) {
        #if canImport(NMSSH)
        guard isShellActive, let channel = channel else { return }
        channel.requestSizeWidth(UInt(width), height: UInt(height))
        #endif
    }

    // MARK: - Output Handler

    func setOutputHandler(_ handler: @escaping (String) -> Void) {
        self.outputHandler = handler
    }

    // MARK: - Connection Quality

    func sendKeepAlive() -> Bool {
        guard _isConnected else { return false }
        do {
            let response = try execute(command: "echo keepalive")
            return response.contains("keepalive")
        } catch {
            return false
        }
    }

    func checkConnection() -> Bool {
        #if canImport(NMSSH)
        return _isConnected && (session?.isConnected ?? false)
        #else
        return false
        #endif
    }

    // MARK: - Reconnection

    func reconnect() throws {
        disconnect()
        Thread.sleep(forTimeInterval: config.reconnectDelay)
        try connect()
    }
}

#if canImport(NMSSH)
// MARK: - NMSSHSessionDelegate

extension RealSSHConnection: NMSSHSessionDelegate {
    func session(_ session: NMSSHSession, didDisconnectWithError error: Error) {
        _isConnected = false
        outputHandler?("Disconnected: \(error.localizedDescription)\n")
    }
}

// MARK: - NMSSHChannelDelegate

extension RealSSHConnection: NMSSHChannelDelegate {
    func channel(_ channel: NMSSHChannel, didReadData message: String) {
        outputHandler?(message)
    }

    func channel(_ channel: NMSSHChannel, didReadError error: String) {
        outputHandler?(error)
    }

    func channelShellDidClose(_ channel: NMSSHChannel) {
        isShellActive = false
        outputHandler?("Shell closed.\n")
    }
}

// MARK: - SFTP Support

extension RealSSHConnection {
    func getNMSSHSession() -> NMSSHSession? {
        return session
    }
}
#endif

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

// MARK: - SSHConfig Extension for NMSSH

extension SSHConfig {
    static var defaultNMSSH: SSHConfig {
        SSHConfig(
            connectionTimeout: 30.0,
            commandTimeout: 60.0,
            autoReconnect: true,
            maxReconnectAttempts: 5,
            reconnectDelay: 2.0,
            keepAliveInterval: 60.0
        )
    }
}
