//
//  ServerStore.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Combine

/// 服务器数据存储
/// 用于 SwiftUI 视图绑定和状态管理
@MainActor
class ServerStore: ObservableObject {
    static let shared = ServerStore()

    @Published var servers: [Server] = []
    @Published var searchText: String = ""
    @Published var currentFolderId: UUID?  // 当前显示的文件夹（nil为根目录）
    @Published var activeSession: ServerSession?  // 当前活跃的 SSH 会话
    
    private let repository = ServerRepository.shared
    private var updateTimer: Timer?
    
    private init() {
        loadServers()
        startAutoRefresh()
    }
    
    // MARK: - Data Loading
    
    /// 加载服务器（根据当前文件夹）
    func loadServers() {
        if let folderId = currentFolderId {
            servers = repository.fetchByFolder(folderId: folderId)
        } else {
            servers = repository.fetchRootServers()
        }
    }
    
    /// 加载所有服务器（忽略文件夹筛选）
    func loadAllServers() {
        servers = repository.fetchAll()
    }
    
    /// 切换到指定文件夹
    func selectFolder(_ folderId: UUID?) {
        currentFolderId = folderId
        loadServers()
    }
    
    /// 切换到根目录
    func selectRootFolder() {
        currentFolderId = nil
        loadServers()
    }
    
    /// 根据搜索文本过滤服务器
    var filteredServers: [Server] {
        if searchText.isEmpty {
            return servers
        }
        return servers.filter { server in
            server.name.localizedCaseInsensitiveContains(searchText) ||
            server.host.localizedCaseInsensitiveContains(searchText) ||
            server.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    /// 按状态过滤的服务器（当前文件夹）
    var onlineServers: [Server] {
        servers.filter { $0.status == .online }
    }
    
    var offlineServers: [Server] {
        servers.filter { $0.status == .offline }
    }
    
    var warningServers: [Server] {
        servers.filter { $0.status == .warning }
    }
    
    // MARK: - CRUD Operations
    
    /// 添加服务器
    func addServer(_ server: Server) {
        if repository.insert(server) {
            loadServers()
        }
    }
    
    /// 更新服务器
    func updateServer(_ server: Server) {
        if repository.update(server) {
            loadServers()
        }
    }
    
    /// 更新服务器的文件夹
    func updateServerFolder(_ serverId: UUID, folderId: UUID?) {
        if let index = servers.firstIndex(where: { $0.id == serverId }) {
            servers[index].folderId = folderId
        }

        if activeSession?.server.id == serverId {
            activeSession?.server.folderId = folderId
        }

        if repository.updateFolder(serverId, folderId: folderId) {
            loadServers()
        }
    }
    
    /// 更新服务器状态
    func updateServerStatus(_ serverId: UUID, status: ServerStatus, cpuUsage: Double?, memoryUsage: Double?) {
        if repository.updateStatus(serverId, status: status, cpuUsage: cpuUsage, memoryUsage: memoryUsage) {
            loadServers()
        }
    }
    
    /// 删除服务器
    func deleteServer(_ server: Server) {
        if repository.delete(server.id) {
            // 删除相关的 Keychain 凭据
            KeychainHelper.shared.deleteAllForServer(server.id)
            loadServers()
        }
    }
    
    /// 删除服务器（通过 ID）
    func deleteServer(byId id: UUID) {
        if repository.delete(id) {
            KeychainHelper.shared.deleteAllForServer(id)
            loadServers()
        }
    }
    
    /// 获取服务器（通过 ID）
    func getServer(byId id: UUID) -> Server? {
        repository.fetchById(id)
    }
    
    // MARK: - Statistics
    
    /// 统计各状态数量
    var statusCounts: [ServerStatus: Int] {
        repository.countByStatus()
    }
    
    /// 获取所有服务器（不区分文件夹）
    var allServers: [Server] {
        repository.fetchAll()
    }
    
    /// 获取根目录服务器数量
    var rootServerCount: Int {
        repository.countRootServers()
    }
    
    /// 获取文件夹内服务器数量
    func serverCountInFolder(_ folderId: UUID) -> Int {
        repository.countByFolder(folderId)
    }
    
    /// 总 CPU 使用率平均值
    var averageCpuUsage: Double {
        let activeServers = allServers.filter { $0.status == .online || $0.status == .warning }
        let cpuValues = activeServers.compactMap { $0.cpuUsage }
        return cpuValues.isEmpty ? 0 : cpuValues.reduce(0, +) / Double(cpuValues.count)
    }
    
    /// 总内存使用率平均值
    var averageMemoryUsage: Double {
        let activeServers = allServers.filter { $0.status == .online || $0.status == .warning }
        let memValues = activeServers.compactMap { $0.memoryUsage }
        return memValues.isEmpty ? 0 : memValues.reduce(0, +) / Double(memValues.count)
    }
    
    // MARK: - Auto Refresh
    
    /// 启动自动刷新
    func startAutoRefresh() {
        stopAutoRefresh()
        
        let interval = AppSettings.shared.refreshInterval
        
        if AppSettings.shared.autoRefreshEnabled {
            updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { _ in
                Task { @MainActor [weak self] in
                    self?.refreshAllServers()
                }
            }
        }
    }
    
    /// 停止自动刷新
    func stopAutoRefresh() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// 刷新所有服务器状态
    func refreshAllServers() {
        loadServers()
    }

    deinit {
        stopAutoRefresh()
    }
}
