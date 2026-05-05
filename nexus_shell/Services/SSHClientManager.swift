//
//  SSHClientManager.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Network

/// 用于在并发环境中安全地修改值的包装类
final class UnsafeSendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) var value: T
    nonisolated init(_ value: T) { self.value = value }
}

/// SSH 客户端管理器
final class SSHClientManager {
    static let shared = SSHClientManager()
    private init() {}

    private static var usesSimulatedNetworkForUITests: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--ui-testing") && arguments.contains("--ui-testing-simulated-network")
    }
    
    // MARK: - Connection Test

    /// 测试连接（根据设置选择真实或模拟）
    static func testConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async -> ConnectionTestResult {
        let mode = AppSettings.shared.sshMode

        switch mode {
        case .simulated:
            return await testSimulatedConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )

        #if canImport(NMSSH)
        case .real:
            return await testRealConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )

        case .auto:
            // 先尝试真实连接，失败后尝试模拟
            var result = await testRealConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )

            if case .failure = result {
                result = await testSimulatedConnection(
                    host: host, port: port, username: username,
                    authMethod: authMethod, serverId: serverId
                )
            }

            return result
        #else
        case .real, .auto:
            return await testSimulatedConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )
        #endif
        }
    }

    /// 测试模拟连接
    private static func testSimulatedConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async -> ConnectionTestResult {
        let reachable = await testNetworkReachability(host: host, port: port)
        if !reachable {
            return .failure("Network unreachable or connection refused")
        }

        var credentials: String?
        switch authMethod {
        case .password:
            credentials = KeychainHelper.shared.getPassword(for: serverId)
        case .privateKey:
            credentials = KeychainHelper.shared.getPrivateKey(for: serverId)
        }

        if credentials == nil && usesSimulatedNetworkForUITests {
            credentials = "ui-test-credentials"
        }

        guard credentials != nil else {
            return .failure("Authentication credentials not found")
        }

        do {
            try await Task.sleep(for: .milliseconds(500))
            return .success
        } catch {
            return .failure("Connection timeout")
        }
    }

    #if canImport(NMSSH)
    /// 测试真实 SSH 连接
    private static func testRealConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async -> ConnectionTestResult {
        let reachable = await testNetworkReachability(host: host, port: port)
        if !reachable {
            return .failure("Network unreachable or connection refused")
        }

        var authConfig: SSHAuthConfig

        switch authMethod {
        case .password:
            guard let password = KeychainHelper.shared.getPassword(for: serverId) else {
                return .failure("Password not found in Keychain")
            }
            authConfig = .password(username: username, password: password)

        case .privateKey:
            guard let privateKey = KeychainHelper.shared.getPrivateKey(for: serverId) else {
                return .failure("Private key not found in Keychain")
            }
            let passphrase = KeychainHelper.shared.getPassphrase(for: serverId)
            authConfig = .privateKey(username: username, privateKey: privateKey, passphrase: passphrase)
        }

        let config = AppSettings.shared.defaultSSHConfig
        let connection = RealSSHConnection(
            host: host,
            port: port,
            authConfig: authConfig,
            serverId: serverId,
            config: config
        )

        do {
            try await connection.connect()
            await connection.disconnect()
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }
    #endif
    
    static func testNetworkReachability(host: String, port: Int) async -> Bool {
        if usesSimulatedNetworkForUITests {
            return true
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                to: .hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port))),
                using: .tcp
            )

            final class ResumeState: Sendable {
                let hasResumed = UnsafeSendableBox<Bool>(false)
            }
            let resumeState = ResumeState()

            connection.stateUpdateHandler = { state in
                guard !resumeState.hasResumed.value else { return }
                switch state {
                case .ready:
                    connection.cancel()
                    resumeState.hasResumed.value = true
                    continuation.resume(returning: true)
                case .failed, .waiting:
                    connection.cancel()
                    resumeState.hasResumed.value = true
                    continuation.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                guard !resumeState.hasResumed.value else { return }
                connection.cancel()
                resumeState.hasResumed.value = true
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - SSH Connection

    enum ConnectionMode {
        #if canImport(NMSSH)
        case real(RealSSHConnection)
        #endif
        case simulated(SSHConnection)
    }

    /// 创建 SSH 连接（根据设置自动选择真实或模拟模式）
    func createConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID,
        config: SSHConfig? = nil
    ) async throws -> ConnectionMode {
        let mode = AppSettings.shared.sshMode
        let sshConfig = config ?? AppSettings.shared.defaultSSHConfig

        switch mode {
        case .simulated:
            // 强制使用模拟模式
            let connection = try await createSimulatedConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )
            return .simulated(connection)

        #if canImport(NMSSH)
        case .real:
            // 强制使用真实 SSH
            let connection = try await createRealConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId, config: sshConfig
            )
            return .real(connection)

        case .auto:
            // 尝试真实 SSH，失败时 fallback 到模拟
            do {
                let connection = try await createRealConnection(
                    host: host, port: port, username: username,
                    authMethod: authMethod, serverId: serverId, config: sshConfig
                )
                return .real(connection)
            } catch {
                print("Real SSH connection failed, falling back to simulated mode: \(error.localizedDescription)")
                let connection = try await createSimulatedConnection(
                    host: host, port: port, username: username,
                    authMethod: authMethod, serverId: serverId
                )
                return .simulated(connection)
            }
        #else
        case .real, .auto:
            let connection = try await createSimulatedConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, serverId: serverId
            )
            return .simulated(connection)
        #endif
        }
    }

    /// 创建模拟连接
    private func createSimulatedConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async throws -> SSHConnection {
        var credentials: String?
        switch authMethod {
        case .password:
            credentials = KeychainHelper.shared.getPassword(for: serverId)
        case .privateKey:
            credentials = KeychainHelper.shared.getPrivateKey(for: serverId)
        }

        if credentials == nil && Self.usesSimulatedNetworkForUITests {
            credentials = "ui-test-credentials"
        }

        guard let credentials else {
            throw SSHError.authenticationFailed("Credentials not found")
        }

        let connection = SSHConnection(
            host: host,
            port: port,
            username: username,
            authMethod: authMethod,
            credentials: credentials,
            serverId: serverId
        )

        try await connection.connect()
        return connection
    }

    #if canImport(NMSSH)
    /// 创建真实 SSH 连接
    private func createRealConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID,
        config: SSHConfig
    ) async throws -> RealSSHConnection {
        var authConfig: SSHAuthConfig

        switch authMethod {
        case .password:
            guard let password = KeychainHelper.shared.getPassword(for: serverId) else {
                throw SSHError.authenticationFailed("Password not found in Keychain")
            }
            authConfig = .password(username: username, password: password)

        case .privateKey:
            guard let privateKey = KeychainHelper.shared.getPrivateKey(for: serverId) else {
                throw SSHError.authenticationFailed("Private key not found in Keychain")
            }
            let passphrase = KeychainHelper.shared.getPassphrase(for: serverId)
            authConfig = .privateKey(username: username, privateKey: privateKey, passphrase: passphrase)
        }

        let connection = RealSSHConnection(
            host: host,
            port: port,
            authConfig: authConfig,
            serverId: serverId,
            config: config
        )

        try await connection.connect()
        return connection
    }
    #endif

    /// 兼容旧接口 - 创建模拟连接
    func createConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async throws -> SSHConnection {
        switch authMethod {
        case .password:
            guard let password = KeychainHelper.shared.getPassword(for: serverId) else {
                throw SSHError.authenticationFailed("Credentials not found")
            }
            // 旧接口仍然返回 SSHConnection 类型，用于兼容
            let mockConnection = SSHConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, credentials: password, serverId: serverId
            )
            try await mockConnection.connect()
            return mockConnection

        case .privateKey:
            guard let privateKey = KeychainHelper.shared.getPrivateKey(for: serverId) else {
                throw SSHError.authenticationFailed("Credentials not found")
            }
            let mockConnection = SSHConnection(
                host: host, port: port, username: username,
                authMethod: authMethod, credentials: privateKey, serverId: serverId
            )
            try await mockConnection.connect()
            return mockConnection
        }
    }
}

// MARK: - Types

enum ConnectionTestResult {
    case success
    case failure(String)
}

enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String)
    case timeout
    case disconnected
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed(let msg): return "Authentication failed: \(msg)"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .timeout: return "Connection timeout"
        case .disconnected: return "Connection disconnected"
        }
    }
}

struct MonitorUpdate {
    let serverId: UUID
    let cpuUsage: Double
    let memoryUsage: Double
    let status: ServerStatus
}

// MARK: - SSH Connection

actor SSHConnection {
    let host: String
    let port: Int
    let username: String
    let authMethod: AuthMethod
    let credentials: String
    let serverId: UUID

    private var isConnected = false
    private var outputHandler: ((String) -> Void)?
    private var engine: DefaultCommandEngine

    init(host: String, port: Int, username: String, authMethod: AuthMethod, credentials: String, serverId: UUID) {
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.credentials = credentials
        self.serverId = serverId
        self.engine = DefaultCommandEngine(host: host, username: username, port: port)
    }

    func connect() async throws {
        try await Task.sleep(for: .milliseconds(300))

        let reachable = await SSHClientManager.testNetworkReachability(host: host, port: port)
        if !reachable {
            throw SSHError.connectionFailed("Cannot reach server at \(host):\(port)")
        }

        isConnected = true
        engine.setCurrentDirectory(engine.homeDirectory)

        outputHandler?("Welcome to \(host)!\nLast login: \(Date().formatted(date: .abbreviated, time: .shortened))\n\n")
    }

    func disconnect() {
        isConnected = false
        outputHandler?("Connection closed.\n")
    }

    func execute(command: String) async throws -> String {
        guard isConnected else { throw SSHError.disconnected }

        let delay = UInt64.random(in: 50...200)
        try await Task.sleep(for: .milliseconds(delay))

        let output = engine.execute(command)
        outputHandler?(output)
        return output
    }

    func setOutputHandler(_ handler: @escaping (String) -> Void) {
        self.outputHandler = handler
    }

    func checkConnection() -> Bool { isConnected }

    func getCurrentDirectory() -> String { engine.currentDirectory }
}

// MARK: - Server Monitor

actor ServerMonitor {
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let interval: TimeInterval = 30.0
    private var handler: ((MonitorUpdate) -> Void)?

    func setUpdateHandler(_ h: @escaping (MonitorUpdate) -> Void) { handler = h }

    // 监控模拟连接
    func startMonitoring(serverId: UUID, simulatedConnection: SSHConnection) {
        stopMonitoring(serverId)
        let task = Task {
            while !Task.isCancelled {
                do {
                    let cpuOutput = try await simulatedConnection.execute(command: "top -bn1 | head -5")
                    let memOutput = try await simulatedConnection.execute(command: "free -m")

                    let cpu = parseCPU(cpuOutput)
                    let mem = parseMem(memOutput)
                    let status: ServerStatus = (cpu > 80 || mem > 80) ? .warning : .online

                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: cpu, memoryUsage: mem, status: status))
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: 0, memoryUsage: 0, status: .offline))
                    break
                }
            }
        }
        tasks[serverId] = task
    }

    #if canImport(NMSSH)
    // 监控真实 SSH 连接
    func startMonitoring(serverId: UUID, realConnection: RealSSHConnection) {
        stopMonitoring(serverId)
        let task = Task {
            while !Task.isCancelled {
                do {
                    let cpuOutput = try await realConnection.execute(command: "top -bn1 | head -5")
                    let memOutput = try await realConnection.execute(command: "free -m")

                    let cpu = parseCPU(cpuOutput)
                    let mem = parseMem(memOutput)
                    let status: ServerStatus = (cpu > 80 || mem > 80) ? .warning : .online

                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: cpu, memoryUsage: mem, status: status))
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: 0, memoryUsage: 0, status: .offline))
                    break
                }
            }
        }
        tasks[serverId] = task
    }
    #endif

    func stopMonitoring(_ id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }

    func stopAll() { tasks.keys.forEach { stopMonitoring($0) } }

    private func parseCPU(_ output: String) -> Double {
        if let range = output.range(of: "([\\d.]+) us", options: .regularExpression) {
            let nums = String(output[range]).extractNumbers()
            return nums.first ?? 45.5
        }
        return 45.5
    }

    private func parseMem(_ output: String) -> Double {
        for line in output.split(separator: "\n") {
            if line.contains("Mem:") {
                let nums = String(line).extractNumbers()
                if nums.count >= 2 { return (nums[1] / nums[0]) * 100.0 }
            }
        }
        return 62.3
    }
}

extension String {
    nonisolated func extractNumbers() -> [Double] {
        let regex = try? NSRegularExpression(pattern: "[\\d.]+")
        let matches = regex?.matches(in: self, range: NSRange(startIndex..., in: self))
        return matches?.compactMap { m in
            guard let r = Range(m.range, in: self) else { return nil }
            return Double(self[r])
        } ?? []
    }
}
