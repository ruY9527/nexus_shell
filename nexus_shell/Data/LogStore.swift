//
//  LogStore.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Combine

/// 日志数据存储
/// 用于 SwiftUI 视图绑定和状态管理
@MainActor
class LogStore: ObservableObject {
    static let shared = LogStore()
    
    @Published var logs: [LogEntry] = []
    @Published var searchText: String = ""
    @Published var selectedServerId: UUID?
    @Published var selectedLevel: LogLevel?
    
    private let repository = LogRepository.shared
    
    private init() {
        loadLogs()
    }
    
    // MARK: - Data Loading
    
    /// 加载日志
    func loadLogs() {
        if let serverId = selectedServerId {
            logs = repository.fetchByServer(serverId: serverId)
        } else if let level = selectedLevel {
            logs = repository.fetchByLevel(level: level)
        } else {
            logs = repository.fetchRecent(days: 7)
        }
    }
    
    /// 根据搜索文本过滤日志
    var filteredLogs: [LogEntry] {
        if searchText.isEmpty {
            return logs
        }
        return logs.filter { log in
            log.message.localizedCaseInsensitiveContains(searchText) ||
            log.level.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// 刷新日志
    func refreshLogs() {
        loadLogs()
    }
    
    // MARK: - Log Operations
    
    /// 添加日志
    func addLog(_ log: LogEntry) {
        repository.insert(log)
        loadLogs()
    }
    
    /// 记录连接日志
    func logConnection(serverId: UUID, serverName: String, success: Bool) {
        repository.logConnection(serverId: serverId, serverName: serverName, success: success)
        loadLogs()
    }
    
    /// 记录认证日志
    func logAuthentication(serverId: UUID, serverName: String, success: Bool, method: String) {
        repository.logAuthentication(serverId: serverId, serverName: serverName, success: success, method: method)
        loadLogs()
    }
    
    /// 记录命令执行日志
    func logCommand(serverId: UUID, command: String) {
        repository.logCommand(serverId: serverId, command: command)
        loadLogs()
    }
    
    /// 记录错误日志
    func logError(serverId: UUID, error: String) {
        repository.logError(serverId: serverId, error: error)
        loadLogs()
    }
    
    /// 记录状态变化日志
    func logStatusChange(serverId: UUID, serverName: String, oldStatus: ServerStatus, newStatus: ServerStatus) {
        repository.logStatusChange(serverId: serverId, serverName: serverName, oldStatus: oldStatus, newStatus: newStatus)
        loadLogs()
    }
    
    /// 记录断开连接日志
    func logDisconnect(serverId: UUID, serverName: String) {
        repository.logDisconnect(serverId: serverId, serverName: serverName)
        loadLogs()
    }
    
    // MARK: - Delete Operations
    
    /// 清除所有日志
    func clearAllLogs() {
        repository.deleteAll()
        loadLogs()
    }
    
    /// 清除指定服务器的日志
    func clearLogsForServer(_ serverId: UUID) {
        repository.deleteByServer(serverId)
        loadLogs()
    }
    
    /// 清除过期日志
    func cleanupOldLogs(days: Int = 7) {
        repository.cleanupOldLogs(days: days)
        loadLogs()
    }
    
    // MARK: - Statistics
    
    /// 日志总数
    var totalLogs: Int {
        repository.count()
    }
    
    /// 各级别日志数量
    var levelCounts: [LogLevel: Int] {
        repository.countByLevel()
    }
    
    /// 日志占用空间估算
    var sizeEstimate: String {
        repository.getSizeEstimate()
    }
    
    /// 数据库大小
    var databaseSize: Int64 {
        repository.getDatabaseSize()
    }
    
    // MARK: - Filter Operations
    
    /// 设置服务器过滤器
    func filterByServer(_ serverId: UUID?) {
        selectedServerId = serverId
        loadLogs()
    }
    
    /// 设置级别过滤器
    func filterByLevel(_ level: LogLevel?) {
        selectedLevel = level
        loadLogs()
    }
    
    /// 清除所有过滤器
    func clearFilters() {
        selectedServerId = nil
        selectedLevel = nil
        loadLogs()
    }
}