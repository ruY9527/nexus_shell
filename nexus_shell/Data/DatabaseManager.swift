//
//  DatabaseManager.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import SQLite3

/// SQLite 数据库管理器
/// 提供基础的数据库操作封装
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    /// 日志保留天数
    private let logRetentionDays = 7
    
    private init() {
        // 数据库文件路径
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.path
        dbPath = (documentsPath as NSString).appendingPathComponent("nexus_shell.sqlite")
        
        // 打开或创建数据库
        openDatabase()
        
        // 创建表
        createTables()
    }
    
    // MARK: - Database Operations
    
    /// 打开数据库
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("无法打开数据库: \(dbPath)")
            db = nil
        } else {
            print("数据库已打开: \(dbPath)")
        }
    }
    
    /// 关闭数据库
    func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    /// 创建数据表
    private func createTables() {
        // 文件夹表
        let createFoldersTable = """
        CREATE TABLE IF NOT EXISTS folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT 'blue',
            icon TEXT NOT NULL DEFAULT 'folder.fill',
            description TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        """
        
        // 服务器表（添加 folder_id）
        let createServersTable = """
        CREATE TABLE IF NOT EXISTS servers (
            id TEXT PRIMARY KEY,
            folder_id TEXT,
            name TEXT NOT NULL,
            host TEXT NOT NULL,
            port INTEGER NOT NULL DEFAULT 22,
            username TEXT NOT NULL,
            auth_method TEXT NOT NULL DEFAULT 'Password',
            password_keychain_id TEXT,
            private_key_keychain_id TEXT,
            tags TEXT,
            created_at REAL NOT NULL,
            last_connected_at REAL,
            status TEXT NOT NULL DEFAULT 'Unknown',
            cpu_usage REAL,
            memory_usage REAL,
            notes TEXT
        );
        """
        
        // 日志表
        let createLogsTable = """
        CREATE TABLE IF NOT EXISTS logs (
            id TEXT PRIMARY KEY,
            server_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            level TEXT NOT NULL DEFAULT 'INFO',
            message TEXT NOT NULL,
            event_type TEXT,
            created_at REAL NOT NULL
        );
        """
        
        // 索引
        let createLogsIndex = "CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);"
        let createLogsServerIndex = "CREATE INDEX IF NOT EXISTS idx_logs_server_id ON logs(server_id);"
        let createServersFolderIndex = "CREATE INDEX IF NOT EXISTS idx_servers_folder_id ON servers(folder_id);"
        
        _ = executeQuery(createFoldersTable)
        _ = executeQuery(createServersTable)
        _ = executeQuery(createLogsTable)
        _ = executeQuery(createLogsIndex)
        _ = executeQuery(createLogsServerIndex)
        _ = executeQuery(createServersFolderIndex)
        
        // 数据库迁移：检查并添加缺失的列
        migrateDatabase()
        
        // 清理过期日志（超过7天）
        cleanupOldLogs()
    }
    
    /// 数据库迁移：检查并添加缺失的列
    private func migrateDatabase() {
        // 检查 servers 表是否有 folder_id 列
        let checkFolderIdSql = "PRAGMA table_info(servers);"
        guard let rows = query(checkFolderIdSql) else {
            return
        }
        
        var hasFolderId = false
        for row in rows {
            if let columnName = row["name"] as? String, columnName == "folder_id" {
                hasFolderId = true
                break
            }
        }
        
        // 如果缺少 folder_id 列，添加它
        if !hasFolderId {
            print("数据库迁移：添加 folder_id 列到 servers 表")
            let addFolderIdSql = "ALTER TABLE servers ADD COLUMN folder_id TEXT;"
            _ = executeQuery(addFolderIdSql)
            
            // 创建索引
            let addIndexSql = "CREATE INDEX IF NOT EXISTS idx_servers_folder_id ON servers(folder_id);"
            _ = executeQuery(addIndexSql)
        }
    }
    
    /// 清理过期日志
    private func cleanupOldLogs() {
        let cutoffDate = Date().addingTimeInterval(-Double(logRetentionDays) * 24 * 60 * 60)
        let cutoffTimestamp = cutoffDate.timeIntervalSince1970
        
        let sql = "DELETE FROM logs WHERE timestamp < ?;"
        let params: [Any] = [cutoffTimestamp]
        
        let deletedCount = execute(sql, params: params)
        if deletedCount > 0 {
            print("已清理 \(deletedCount) 条过期日志（超过 \(logRetentionDays) 天）")
        }
    }
    
    /// 手动清理所有日志
    func clearAllLogs() -> Int {
        let sql = "DELETE FROM logs;"
        return execute(sql)
    }
    
    /// 清理指定服务器的日志
    func clearLogsForServer(_ serverId: UUID) -> Int {
        let sql = "DELETE FROM logs WHERE server_id = ?;"
        let params: [Any] = [serverId.uuidString]
        return execute(sql, params: params)
    }
    
    /// 执行 SQL 查询（无返回结果）
    func executeQuery(_ sql: String) -> Bool {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL 准备失败: \(errorMessage)")
            return false
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL 执行失败: \(errorMessage)")
            sqlite3_finalize(statement)
            return false
        }
        
        sqlite3_finalize(statement)
        return true
    }
    
    /// 执行查询并返回结果
    func query(_ sql: String, params: [Any] = []) -> [[String: Any]]? {
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL 准备失败: \(errorMessage)")
            return nil
        }
        
        // 绑定参数
        bindParams(statement: statement, params: params)
        
        // 获取列信息
        let columnCount = sqlite3_column_count(statement)
        var columnNames: [String] = []
        
        for i in 0..<columnCount {
            let columnName = String(cString: sqlite3_column_name(statement, i))
            columnNames.append(columnName)
        }
        
        // 遍历结果
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            
            for i in 0..<columnCount {
                let columnName = columnNames[Int(i)]
                let columnType = sqlite3_column_type(statement, i)
                
                switch columnType {
                case SQLITE_TEXT:
                    if let textPointer = sqlite3_column_text(statement, i) {
                        let text = String(cString: textPointer)
                        row[columnName] = text
                    }
                case SQLITE_INTEGER:
                    let intValue = sqlite3_column_int(statement, i)
                    row[columnName] = Int(intValue)
                case SQLITE_FLOAT:
                    let doubleValue = sqlite3_column_double(statement, i)
                    row[columnName] = doubleValue
                default:
                    row[columnName] = NSNull()
                }
            }
            
            results.append(row)
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    /// 执行插入/更新/删除并返回影响的行数
    func execute(_ sql: String, params: [Any] = []) -> Int {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL 准备失败: \(errorMessage)")
            return 0
        }
        
        // 绑定参数
        bindParams(statement: statement, params: params)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SQL 执行失败: \(errorMessage)")
            sqlite3_finalize(statement)
            return 0
        }
        
        let changes = sqlite3_changes(db)
        sqlite3_finalize(statement)
        
        return Int(changes)
    }
    
    /// 绑定参数
    private func bindParams(statement: OpaquePointer?, params: [Any]) {
        for (index, param) in params.enumerated() {
            let paramIndex = Int32(index + 1)
            
            if let stringParam = param as? String {
                // 使用 SQLITE_TRANSIENT 让 SQLite 在使用后自动释放内存
                sqlite3_bind_text(statement, paramIndex, (stringParam as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            } else if let intParam = param as? Int {
                sqlite3_bind_int(statement, paramIndex, Int32(intParam))
            } else if let doubleParam = param as? Double {
                sqlite3_bind_double(statement, paramIndex, doubleParam)
            } else if param is NSNull {
                sqlite3_bind_null(statement, paramIndex)
            } else {
                sqlite3_bind_null(statement, paramIndex)
            }
        }
    }
    
    /// 获取最后插入的 ID
    func lastInsertRowId() -> Int64 {
        return sqlite3_last_insert_rowid(db)
    }
    
    /// 获取数据库大小（字节）
    func getDatabaseSize() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: dbPath),
           let size = attributes[.size] as? Int64 {
            return size
        }
        return 0
    }
    
    /// 获取日志表大小
    func getLogsCount() -> Int {
        let sql = "SELECT COUNT(*) as count FROM logs;"
        guard let rows = query(sql), let row = rows.first else {
            return 0
        }
        return row["count"] as? Int ?? 0
    }
    
    /// 获取日志占用空间估算
    func getLogsSizeEstimate() -> String {
        let count = getLogsCount()
        // 估算每条日志约 500 字节
        let estimatedBytes = count * 500
        
        if estimatedBytes < 1024 {
            return "\(estimatedBytes) B"
        } else if estimatedBytes < 1024 * 1024 {
            return "\(estimatedBytes / 1024) KB"
        } else {
            return String(format: "%.1f MB", Double(estimatedBytes) / 1024.0 / 1024.0)
        }
    }
    
    // MARK: - Transaction
    
    func beginTransaction() {
        _ = executeQuery("BEGIN TRANSACTION;")
    }
    
    func commitTransaction() {
        _ = executeQuery("COMMIT;")
    }
    
    func rollbackTransaction() {
        _ = executeQuery("ROLLBACK;")
    }
}