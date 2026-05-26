import Foundation
@preconcurrency import NMSSH

enum SSHError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String)
    case timeout
    case notConnected
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason): return String(localized: "Connection failed: \(reason)", comment: "SSH connection error")
        case .authenticationFailed(let reason): return String(localized: "Authentication failed: \(reason)", comment: "SSH auth error")
        case .commandFailed(let reason): return String(localized: "Command failed: \(reason)", comment: "SSH command error")
        case .timeout: return String(localized: "Connection timed out", comment: "SSH timeout error")
        case .notConnected: return String(localized: "Not connected to server", comment: "SSH not connected error")
        case .invalidConfiguration: return String(localized: "Invalid server configuration", comment: "SSH config error")
        }
    }
}

enum SessionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected: return String(localized: "Disconnected", comment: "SSH session status")
        case .connecting: return String(localized: "Connecting...", comment: "SSH session status")
        case .connected: return String(localized: "Connected", comment: "SSH session status")
        case .reconnecting(let attempt, let max): return String(localized: "Reconnecting (\(attempt)/\(max))...", comment: "SSH reconnection status")
        case .error(let msg): return String(localized: "Error: \(msg)", comment: "SSH error status")
        }
    }
}

@Observable
final class SSHService: NSObject, @unchecked Sendable {
    private(set) var state: SessionState = .disconnected
    private(set) var isConnected: Bool = false
    private(set) var lastError: String?
    private var session: NMSSHSession?
    private var shellChannel: NMSSHChannel?
    private var outputHandler: ((String) -> Void)?
    private var config: SSHConfig
    private var reconnectAttempt: Int = 0
    private var keepAliveTimer: Timer?

    struct SSHConfig {
        var connectionTimeout: TimeInterval = 10.0
        var commandTimeout: TimeInterval = 30.0
        var autoReconnect: Bool = true
        var maxReconnectAttempts: Int = 3
        var reconnectDelay: TimeInterval = 2.0
        var keepAliveInterval: TimeInterval = 60.0
    }

    init(config: SSHConfig = SSHConfig()) {
        self.config = config
        super.init()
    }

    func connect(to server: Server, password: String? = nil, privateKeyPath: String? = nil) async throws {
        state = .connecting

        guard !server.host.isEmpty, server.port > 0 else {
            state = .error(String(localized: "Invalid server configuration", comment: "SSH config error"))
            throw SSHError.invalidConfiguration
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: SSHError.notConnected)
                    return
                }

                let session = NMSSHSession(host: server.host, port: server.port, andUsername: server.username)
                session.timeout = NSNumber(value: self.config.connectionTimeout)
                session.connect()

                guard session.isConnected else {
                    self.state = .error(String(localized: "Connection failed", comment: "SSH error state"))
                    continuation.resume(throwing: SSHError.connectionFailed(String(localized: "Could not connect to \(server.host):\(server.port)", comment: "SSH connection detail")))
                    return
                }

                if let privateKeyPath {
                    let _ = session.authenticate(byPublicKey: nil, privateKey: privateKeyPath, andPassword: password)
                } else if let password {
                    let _ = session.authenticate(byPassword: password)
                }

                guard session.isAuthorized else {
                    self.state = .error(String(localized: "Authentication failed", comment: "SSH error state"))
                    continuation.resume(throwing: SSHError.authenticationFailed(String(localized: "Invalid credentials for \(server.username)", comment: "SSH auth detail")))
                    return
                }

                self.session = session
                self.isConnected = true
                self.reconnectAttempt = 0
                self.state = .connected

                self.startKeepAlive()
                continuation.resume()
            }
        }
    }

    func disconnect() {
        stopKeepAlive()
        shellChannel?.closeShell()
        session?.disconnect()
        session = nil
        shellChannel = nil
        isConnected = false
        state = .disconnected
    }

    func execute(_ command: String) async throws -> String {
        guard let session, session.isConnected else {
            throw SSHError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSError?
                let response = session.channel.execute(command, error: &error)

                if let error {
                    continuation.resume(throwing: SSHError.commandFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: response)
                }
            }
        }
    }

    func startShell(outputHandler: @escaping (String) -> Void) async throws {
        guard let session, session.isConnected else {
            throw SSHError.notConnected
        }

        self.outputHandler = outputHandler

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: SSHError.notConnected)
                    return
                }

                let channel = NMSSHChannel(session: session)
                channel.requestPty = true
                channel.delegate = self

                do {
                    try channel.startShell()
                    self.shellChannel = channel
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: SSHError.commandFailed(String(localized: "Failed to start shell", comment: "SSH shell error")))
                }
            }
        }
    }

    func sendInput(_ input: String) {
        guard let shellChannel else {
            lastError = "Shell not connected"
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSError?
            let success = shellChannel.write(input, error: &error, timeout: NSNumber(value: 5))
            if !success || error != nil {
                DispatchQueue.main.async { [weak self] in
                    self?.lastError = error?.localizedDescription ?? "Write failed"
                }
            }
        }
    }

    func resizeTerminal(width: Int, height: Int) {
        guard let shellChannel else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = shellChannel.requestSizeWidth(UInt(width), height: UInt(height))
        }
    }

    private func startKeepAlive() {
        stopKeepAlive()
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: config.keepAliveInterval, repeats: true) { [weak self] _ in
            guard let self, let shellChannel = self.shellChannel else { return }
            DispatchQueue.global(qos: .utility).async {
                var error: NSError?
                shellChannel.write("echo .\n", error: &error, timeout: NSNumber(value: 5))
            }
        }
    }

    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }

    func attemptReconnect(to server: Server, password: String? = nil, privateKeyPath: String? = nil) async throws {
        guard config.autoReconnect else { throw SSHError.notConnected }

        while reconnectAttempt < config.maxReconnectAttempts {
            reconnectAttempt += 1
            state = .reconnecting(attempt: reconnectAttempt, maxAttempts: config.maxReconnectAttempts)

            do {
                try await Task.sleep(nanoseconds: UInt64(config.reconnectDelay * 1_000_000_000))
                try await connect(to: server, password: password, privateKeyPath: privateKeyPath)
                return
            } catch {
                if reconnectAttempt >= config.maxReconnectAttempts {
                    state = .error(String(localized: "Reconnection failed after \(config.maxReconnectAttempts) attempts", comment: "SSH reconnect error"))
                    throw error
                }
            }
        }
    }
}

extension SSHService: NMSSHChannelDelegate {
    func channel(_ channel: NMSSHChannel, didReadData message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.outputHandler?(message)
        }
    }

    func channel(_ channel: NMSSHChannel, didReadError error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.outputHandler?("[ERROR] \(error)")
        }
    }

    func channelDidClose(_ channel: NMSSHChannel) {
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.state = .disconnected
        }
    }
}
