//
//  ServerRepository.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 服务器数据访问层
/// 提供对 Server 数据的 CRUD 操作
class ServerRepository {
    static let shared = ServerRepository()
    
    private let db = DatabaseManager.shared
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    /// 获取所有服务器
    func fetchAll(sortBy: String = "name", ascending: Bool = true) -> [Server] {
        let order = ascending ? "ASC" : "DESC"
        let sql = "SELECT * FROM servers ORDER BY \(sortBy) \(order);"
        
        guard let rows = db.query(sql) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 获取根目录的服务器（无文件夹）
    func fetchRootServers(sortBy: String = "name", ascending: Bool = true) -> [Server] {
        let order = ascending ? "ASC" : "DESC"
        let sql = "SELECT * FROM servers WHERE folder_id IS NULL ORDER BY \(sortBy) \(order);"
        
        guard let rows = db.query(sql) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 获取指定文件夹的服务器
    func fetchByFolder(folderId: UUID, sortBy: String = "name", ascending: Bool = true) -> [Server] {
        let order = ascending ? "ASC" : "DESC"
        let sql = "SELECT * FROM servers WHERE folder_id = ? ORDER BY \(sortBy) \(order);"
        let params: [Any] = [folderId.uuidString]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 根据 ID 获取服务器
    func fetchById(_ id: UUID) -> Server? {
        let sql = "SELECT * FROM servers WHERE id = ?;"
        let params: [Any] = [id.uuidString]
        
        guard let rows = db.query(sql, params: params), let row = rows.first else {
            return nil
        }
        
        return Server.fromDatabaseRow(row)
    }
    
    /// 搜索服务器
    func search(_ keyword: String) -> [Server] {
        let sql = "SELECT * FROM servers WHERE name LIKE ? OR host LIKE ? OR notes LIKE ?;"
        let searchPattern = "%\(keyword)%"
        let params: [Any] = [searchPattern, searchPattern, searchPattern]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 搜索指定文件夹的服务器
    func searchInFolder(folderId: UUID, keyword: String) -> [Server] {
        let sql = "SELECT * FROM servers WHERE folder_id = ? AND (name LIKE ? OR host LIKE ? OR notes LIKE ?);"
        let searchPattern = "%\(keyword)%"
        let params: [Any] = [folderId.uuidString, searchPattern, searchPattern, searchPattern]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 插入服务器
    func insert(_ server: Server) -> Bool {
        let sql = """
        INSERT INTO servers (
            id, folder_id, name, host, port, username, auth_method,
            password_keychain_id, private_key_keychain_id, tags,
            created_at, last_connected_at, status,
            cpu_usage, memory_usage, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var params: [Any] = [
            server.id.uuidString,
            server.folderId?.uuidString ?? NSNull(),
            server.name,
            server.host,
            server.port,
            server.username,
            server.authMethod.rawValue
        ]
        
        params.append(server.passwordKeychainId ?? NSNull())
        params.append(server.privateKeyKeychainId ?? NSNull())
        params.append(server.tags.isEmpty ? "" : server.tags.joined(separator: ","))
        params.append(server.createdAt.timeIntervalSince1970)
        params.append(server.lastConnectedAt?.timeIntervalSince1970 ?? NSNull())
        params.append(server.status.rawValue)
        params.append(server.cpuUsage ?? NSNull())
        params.append(server.memoryUsage ?? NSNull())
        params.append(server.notes ?? NSNull())
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 更新服务器
    func update(_ server: Server) -> Bool {
        let sql = """
        UPDATE servers SET
            folder_id = ?, name = ?, host = ?, port = ?, username = ?, auth_method = ?,
            password_keychain_id = ?, private_key_keychain_id = ?, tags = ?,
            last_connected_at = ?, status = ?, cpu_usage = ?, memory_usage = ?, notes = ?
        WHERE id = ?;
        """
        
        var params: [Any] = [
            server.folderId?.uuidString ?? NSNull(),
            server.name,
            server.host,
            server.port,
            server.username,
            server.authMethod.rawValue
        ]
        
        params.append(server.passwordKeychainId ?? NSNull())
        params.append(server.privateKeyKeychainId ?? NSNull())
        params.append(server.tags.isEmpty ? "" : server.tags.joined(separator: ","))
        params.append(server.lastConnectedAt?.timeIntervalSince1970 ?? NSNull())
        params.append(server.status.rawValue)
        params.append(server.cpuUsage ?? NSNull())
        params.append(server.memoryUsage ?? NSNull())
        params.append(server.notes ?? NSNull())
        params.append(server.id.uuidString)
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 更新服务器的文件夹
    func updateFolder(_ serverId: UUID, folderId: UUID?) -> Bool {
        let sql = "UPDATE servers SET folder_id = ? WHERE id = ?;"
        let params: [Any] = [folderId?.uuidString ?? NSNull(), serverId.uuidString]
        return db.execute(sql, params: params) > 0
    }
    
    /// 更新服务器状态
    func updateStatus(_ serverId: UUID, status: ServerStatus, cpuUsage: Double?, memoryUsage: Double?) -> Bool {
        let sql = """
        UPDATE servers SET status = ?, cpu_usage = ?, memory_usage = ?
        WHERE id = ?;
        """
        
        let params: [Any] = [
            status.rawValue,
            cpuUsage ?? NSNull(),
            memoryUsage ?? NSNull(),
            serverId.uuidString
        ]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 更新最后连接时间
    func updateLastConnected(_ serverId: UUID) -> Bool {
        let sql = """
        UPDATE servers SET last_connected_at = ?
        WHERE id = ?;
        """
        
        let params: [Any] = [
            Date().timeIntervalSince1970,
            serverId.uuidString
        ]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 删除服务器
    func delete(_ serverId: UUID) -> Bool {
        let sql = "DELETE FROM servers WHERE id = ?;"
        let params: [Any] = [serverId.uuidString]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 删除所有服务器
    func deleteAll() -> Bool {
        let sql = "DELETE FROM servers;"
        return db.execute(sql) >= 0
    }
    
    /// 删除文件夹内的所有服务器
    func deleteByFolder(_ folderId: UUID) -> Int {
        let sql = "DELETE FROM servers WHERE folder_id = ?;"
        let params: [Any] = [folderId.uuidString]
        return db.execute(sql, params: params)
    }
    
    /// 统计服务器数量
    func count() -> Int {
        let sql = "SELECT COUNT(*) as count FROM servers;"
        
        guard let rows = db.query(sql), let row = rows.first else {
            return 0
        }
        
        return row["count"] as? Int ?? 0
    }
    
    /// 统计根目录服务器数量
    func countRootServers() -> Int {
        let sql = "SELECT COUNT(*) as count FROM servers WHERE folder_id IS NULL;"
        
        guard let rows = db.query(sql), let row = rows.first else {
            return 0
        }
        
        return row["count"] as? Int ?? 0
    }
    
    /// 统计文件夹内服务器数量
    func countByFolder(_ folderId: UUID) -> Int {
        let sql = "SELECT COUNT(*) as count FROM servers WHERE folder_id = ?;"
        let params: [Any] = [folderId.uuidString]
        
        guard let rows = db.query(sql, params: params), let row = rows.first else {
            return 0
        }
        
        return row["count"] as? Int ?? 0
    }
    
    /// 统计各状态服务器数量
    func countByStatus() -> [ServerStatus: Int] {
        var counts: [ServerStatus: Int] = [:]
        
        for status in ServerStatus.allCases {
            let sql = "SELECT COUNT(*) as count FROM servers WHERE status = ?;"
            let params: [Any] = [status.rawValue]
            
            guard let rows = db.query(sql, params: params), let row = rows.first else {
                counts[status] = 0
                continue
            }
            
            counts[status] = row["count"] as? Int ?? 0
        }
        
        return counts
    }
    
    // MARK: - Batch Operations
    
    /// 批量插入服务器
    func insertBatch(_ servers: [Server]) -> Int {
        var insertedCount = 0
        
        db.beginTransaction()
        
        for server in servers {
            if insert(server) {
                insertedCount += 1
            }
        }
        
        db.commitTransaction()
        
        return insertedCount
    }
}