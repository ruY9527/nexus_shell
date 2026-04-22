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
    case error(String)
    
    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected):
            return true
        case (.connecting, .connecting):
            return true
        case (.connected, .connected):
            return true
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}

/// SSH 会话管理类
/// 管理单个 SSH 连接的生命周期
@MainActor
class ServerSession: ObservableObject {
    /// 关联的服务器
    let server: Server
    
    /// 会话状态
    @Published var state: SessionState = .disconnected
    
    /// 终端输出缓冲
    @Published var outputBuffer: String = ""
    
    /// 命令历史
    @Published var commandHistory: [String] = []
    
    /// 会话创建时间
    let createdAt: Date
    
    /// SSH 连接
    private var sshConnection: SSHConnection?
    
    /// 监控器
    private let monitor = ServerMonitor()
    
    /// 是否正在监控
    @Published var isMonitoring: Bool = false
    
    init(server: Server) {
        self.server = server
        self.createdAt = Date()
        
        // 初始化欢迎信息
        outputBuffer = """
        ┌─────────────────────────────────────────┐
        │  Nexus Shell - SSH Terminal             │
        │  Server: \(server.name)
        │  Host: \(server.displayAddress)
        └─────────────────────────────────────────┘

        """
        
        // 设置监控器回调
        Task {
            await monitor.setUpdateHandler { [weak self] update in
                Task { @MainActor [weak self] in
                    guard let self, self.server.id == update.serverId else { return }
                    
                    self.server.cpuUsage = update.cpuUsage
                    self.server.memoryUsage = update.memoryUsage
                    self.server.status = update.status
                }
            }
        }
    }
    
    /// 连接到服务器
    func connect() async {
        guard state != .connected && state != .connecting else { return }
        
        state = .connecting
        appendOutput("Connecting to \(server.host)...\n")
        
        do {
            sshConnection = try await SSHClientManager.shared.createConnection(
                host: server.host,
                port: server.port,
                username: server.username,
                authMethod: server.authMethod,
                serverId: server.id
            )
            
            // 设置输出回调
            await sshConnection?.setOutputHandler { [weak self] output in
                Task { @MainActor [weak self] in
                    self?.appendOutput(output)
                }
            }
            
            state = .connected
            appendOutput("Connection established. Welcome!\n")
            
            // 更新服务器状态
            server.status = .online
            server.lastConnectedAt = Date()
            
            // 开始监控
            startMonitoring()
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
        } catch {
            state = .error(error.localizedDescription)
            appendOutput("Error: \(error.localizedDescription)\n")
            server.status = .offline
            
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    /// 断开连接
    func disconnect() {
        guard sshConnection != nil else { return }
        
        isMonitoring = false
        
        // 异步处理断开连接
        Task {
            await monitor.stopMonitoring(server.id)
            await sshConnection?.disconnect()
        }
        
        sshConnection = nil
        
        state = .disconnected
        appendOutput("\nConnection closed.\n")
        
        server.status = .unknown
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// 发送命令
    func sendCommand(_ command: String) {
        guard state == .connected, let connection = sshConnection else {
            appendOutput("Error: Not connected to server.\n")
            return
        }
        
        // 添加到历史
        if !command.isEmpty && command != "\n" {
            commandHistory.append(command.trimmingCharacters(in: .newlines))
        }
        
        // 显示命令
        appendOutput("$ " + command.trimmingCharacters(in: .whitespacesAndNewlines) + "\n")
        
        Task {
            do {
                _ = try await connection.execute(command: command)
            } catch {
                appendOutput("Error: \(error.localizedDescription)\n")
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// 清空终端
    func clearTerminal() {
        outputBuffer = ""
    }
    
    /// 开始监控服务器状态
    private func startMonitoring() {
        guard sshConnection != nil else { return }
        
        isMonitoring = true
        
        Task {
            await monitor.startMonitoring(serverId: server.id, connection: sshConnection!)
        }
    }
    
    /// 追加输出
    private func appendOutput(_ text: String) {
        outputBuffer += text
        
        // 限制缓冲区大小，防止内存溢出
        if outputBuffer.count > 100000 {
            let startIndex = outputBuffer.index(outputBuffer.startIndex, offsetBy: 50000)
            outputBuffer = String(outputBuffer[startIndex...])
        }
    }
    
    /// 获取上一个命令（用于向上箭头）
    func getPreviousCommand() -> String? {
        if commandHistory.isEmpty { return nil }
        return commandHistory.last
    }
    
    /// 获取特定索引的历史命令
    func getCommand(at index: Int) -> String? {
        if index < 0 || index >= commandHistory.count { return nil }
        return commandHistory[commandHistory.count - 1 - index]
    }
}