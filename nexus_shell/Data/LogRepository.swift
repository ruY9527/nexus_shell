//
//  LogRepository.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 日志数据访问层
class LogRepository {
    static let shared = LogRepository()
    
    private let db = DatabaseManager.shared
    private let logRetentionDays = 7
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    /// 获取所有日志（按时间倒序）
    func fetchAll(limit: Int = 100, offset: Int = 0) -> [LogEntry] {
        let sql = "SELECT * FROM logs ORDER BY timestamp DESC LIMIT ? OFFSET ?;"
        let params: [Any] = [limit, offset]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { LogEntry.fromDatabaseRow($0) }
    }
    
    /// 获取指定服务器的日志
    func fetchByServer(serverId: UUID, limit: Int = 50) -> [LogEntry] {
        let sql = "SELECT * FROM logs WHERE server_id = ? ORDER BY timestamp DESC LIMIT ?;"
        let params: [Any] = [serverId.uuidString, limit]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { LogEntry.fromDatabaseRow($0) }
    }
    
    /// 获取指定级别的日志
    func fetchByLevel(level: LogLevel, limit: Int = 50) -> [LogEntry] {
        let sql = "SELECT * FROM logs WHERE level = ? ORDER BY timestamp DESC LIMIT ?;"
        let params: [Any] = [level.rawValue, limit]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { LogEntry.fromDatabaseRow($0) }
    }
    
    /// 搜索日志
    func search(keyword: String, limit: Int = 100) -> [LogEntry] {
        let sql = "SELECT * FROM logs WHERE message LIKE ? ORDER BY timestamp DESC LIMIT ?;"
        let searchPattern = "%\(keyword)%"
        let params: [Any] = [searchPattern, limit]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { LogEntry.fromDatabaseRow($0) }
    }
    
    /// 获取最近7天的日志
    func fetchRecent(days: Int = 7) -> [LogEntry] {
        let cutoffTimestamp = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        let sql = "SELECT * FROM logs WHERE timestamp >= ? ORDER BY timestamp DESC;"
        let params: [Any] = [cutoffTimestamp.timeIntervalSince1970]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { LogEntry.fromDatabaseRow($0) }
    }
    
    /// 插入日志
    func insert(_ log: LogEntry) -> Bool {
        let sql = """
        INSERT INTO logs (id, server_id, timestamp, level, message, event_type, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        let params: [Any] = [
            log.id.uuidString,
            log.serverId.uuidString,
            log.timestamp.timeIntervalSince1970,
            log.level.rawValue,
            log.message,
            NSNull(),  // event_type 暂时为空
            Date().timeIntervalSince1970
        ]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 批量插入日志
    func insertBatch(_ logs: [LogEntry]) -> Int {
        var insertedCount = 0
        
        db.beginTransaction()
        
        for log in logs {
            if insert(log) {
                insertedCount += 1
            }
        }
        
        db.commitTransaction()
        
        return insertedCount
    }
    
    /// 删除指定日志
    func delete(_ logId: UUID) -> Bool {
        let sql = "DELETE FROM logs WHERE id = ?;"
        let params: [Any] = [logId.uuidString]
        return db.execute(sql, params: params) > 0
    }
    
    /// 删除指定服务器的所有日志
    func deleteByServer(_ serverId: UUID) -> Int {
        return db.clearLogsForServer(serverId)
    }
    
    /// 删除所有日志
    func deleteAll() -> Int {
        return db.clearAllLogs()
    }
    
    /// 清理过期日志（超过指定天数）
    func cleanupOldLogs(days: Int = 7) -> Int {
        let cutoffTimestamp = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        let sql = "DELETE FROM logs WHERE timestamp < ?;"
        let params: [Any] = [cutoffTimestamp.timeIntervalSince1970]
        return db.execute(sql, params: params)
    }
    
    /// 统计日志数量
    func count() -> Int {
        return db.getLogsCount()
    }
    
    /// 统计指定服务器的日志数量
    func countByServer(_ serverId: UUID) -> Int {
        let sql = "SELECT COUNT(*) as count FROM logs WHERE server_id = ?;"
        let params: [Any] = [serverId.uuidString]
        
        guard let rows = db.query(sql, params: params), let row = rows.first else {
            return 0
        }
        return row["count"] as? Int ?? 0
    }
    
    /// 统计各级别的日志数量
    func countByLevel() -> [LogLevel: Int] {
        var counts: [LogLevel: Int] = [:]
        
        for level in LogLevel.allCases {
            let sql = "SELECT COUNT(*) as count FROM logs WHERE level = ?;"
            let params: [Any] = [level.rawValue]
            
            guard let rows = db.query(sql, params: params), let row = rows.first else {
                counts[level] = 0
                continue
            }
            
            counts[level] = row["count"] as? Int ?? 0
        }
        
        return counts
    }
    
    /// 获取日志存储空间估算
    func getSizeEstimate() -> String {
        return db.getLogsSizeEstimate()
    }
    
    /// 获取数据库大小
    func getDatabaseSize() -> Int64 {
        return db.getDatabaseSize()
    }
    
    // MARK: - Log Writing Helpers
    
    /// 写入连接日志
    func logConnection(serverId: UUID, serverName: String, success: Bool) {
        let level: LogLevel = success ? .info : .error
        let message = success
            ? "SSH connection established to \(serverName)"
            : "SSH connection failed to \(serverName)"
        
        let log = LogEntry(serverId: serverId, level: level, message: message)
        _ = insert(log)
    }
    
    /// 写入认证日志
    func logAuthentication(serverId: UUID, serverName: String, success: Bool, method: String) {
        let level: LogLevel = success ? .info : .warning
        let message = success
            ? "Authentication successful using \(method)"
            : "Authentication failed using \(method)"
        
        let log = LogEntry(serverId: serverId, level: level, message: message)
        _ = insert(log)
    }
    
    /// 写入命令执行日志
    func logCommand(serverId: UUID, command: String) {
        let message = "Executing command: \(command)"
        let log = LogEntry(serverId: serverId, level: .debug, message: message)
        _ = insert(log)
    }
    
    /// 写入错误日志
    func logError(serverId: UUID, error: String) {
        let log = LogEntry(serverId: serverId, level: .error, message: error)
        _ = insert(log)
    }
    
    /// 写入状态变化日志
    func logStatusChange(serverId: UUID, serverName: String, oldStatus: ServerStatus, newStatus: ServerStatus) {
        let message = "Server \(serverName) status changed: \(oldStatus.rawValue) → \(newStatus.rawValue)"
        let log = LogEntry(serverId: serverId, level: .info, message: message)
        _ = insert(log)
    }
    
    /// 写入断开连接日志
    func logDisconnect(serverId: UUID, serverName: String) {
        let message = "Disconnected from \(serverName)"
        let log = LogEntry(serverId: serverId, level: .info, message: message)
        _ = insert(log)
    }
}