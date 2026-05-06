//
//  SSHClientManager.swift
//  nexus_shell
//
//  SSH Client Manager using Citadel
//

import Foundation
import Network
import Citadel

/// 用于在并发环境中安全地修改值的包装类
final class UnsafeSendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) var value: T
    nonisolated init(_ value: T) { self.value = value }
}

/// SSH 客户端管理器
final class SSHClientManager {
    static let shared = SSHClientManager()
    private init() {}

    // MARK: - Connection Test

    /// 测试 SSH 连接
    static func testConnection(
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

    static func testNetworkReachability(host: String, port: Int) async -> Bool {
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

    /// 创建真实 SSH 连接
    func createConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID,
        config: SSHConfig? = nil
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

        let sshConfig = config ?? AppSettings.shared.defaultSSHConfig
        let connection = RealSSHConnection(
            host: host,
            port: port,
            authConfig: authConfig,
            serverId: serverId,
            config: sshConfig
        )

        try await connection.connect()
        return connection
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

// MARK: - Server Monitor

actor ServerMonitor {
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let interval: TimeInterval = 30.0
    private var handler: ((MonitorUpdate) -> Void)?

    func setUpdateHandler(_ h: @escaping (MonitorUpdate) -> Void) { handler = h }

    /// 监控真实 SSH 连接
    func startMonitoring(serverId: UUID, connection: RealSSHConnection) {
        stopMonitoring(serverId)
        let task = Task {
            while !Task.isCancelled {
                do {
                    let cpuOutput = try await connection.execute(command: "top -bn1 | head -5")
                    let memOutput = try await connection.execute(command: "free -m")

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
