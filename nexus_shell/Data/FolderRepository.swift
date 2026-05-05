//
//  FolderRepository.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 文件夹数据访问层
class FolderRepository {
    static let shared = FolderRepository()
    
    private let db = DatabaseManager.shared
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    /// 获取所有文件夹
    func fetchAll() -> [ServerFolder] {
        let sql = "SELECT * FROM folders ORDER BY sort_order ASC, name ASC;"
        
        guard let rows = db.query(sql) else {
            return []
        }
        
        return rows.compactMap { ServerFolder.fromDatabaseRow($0) }
    }
    
    /// 获取单个文件夹
    func fetchById(_ id: UUID) -> ServerFolder? {
        let sql = "SELECT * FROM folders WHERE id = ?;"
        let params: [Any] = [id.uuidString]
        
        guard let rows = db.query(sql, params: params), let row = rows.first else {
            return nil
        }
        
        return ServerFolder.fromDatabaseRow(row)
    }
    
    /// 插入文件夹
    func insert(_ folder: ServerFolder) -> Bool {
        let sql = """
        INSERT INTO folders (id, name, color, icon, description, created_at, updated_at, sort_order)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        let params: [Any] = [
            folder.id.uuidString,
            folder.name,
            folder.color.rawValue,
            folder.icon.rawValue,
            folder.description ?? NSNull(),
            folder.createdAt.timeIntervalSince1970,
            folder.updatedAt.timeIntervalSince1970,
            folder.sortOrder
        ]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 批量插入文件夹
    func insertBatch(_ folders: [ServerFolder]) -> Int {
        var insertedCount = 0
        
        db.beginTransaction()
        
        for folder in folders {
            if insert(folder) {
                insertedCount += 1
            }
        }
        
        db.commitTransaction()
        
        return insertedCount
    }
    
    /// 更新文件夹
    func update(_ folder: ServerFolder) -> Bool {
        let sql = """
        UPDATE folders SET
            name = ?,
            color = ?,
            icon = ?,
            description = ?,
            updated_at = ?,
            sort_order = ?
        WHERE id = ?;
        """
        
        let params: [Any] = [
            folder.name,
            folder.color.rawValue,
            folder.icon.rawValue,
            folder.description ?? NSNull(),
            Date().timeIntervalSince1970,
            folder.sortOrder,
            folder.id.uuidString
        ]
        
        return db.execute(sql, params: params) > 0
    }
    
    /// 删除文件夹（仅删除空文件夹）
    func delete(_ folderId: UUID) -> Bool {
        // 检查文件夹是否为空
        if countByFolder(folderId) > 0 {
            // 文件夹不为空，不允许删除
            AppLogger.database("Cannot delete non-empty folder: \(folderId)", level: AppLogLevel.warning)
            return false
        }
        
        // 删除文件夹
        let sql = "DELETE FROM folders WHERE id = ?;"
        let params: [Any] = [folderId.uuidString]
        return db.execute(sql, params: params) > 0
    }
    
    /// 强制删除文件夹（将服务器移动到根目录后删除）
    func forceDelete(_ folderId: UUID) -> Bool {
        // 先将文件夹内的服务器移动到根目录
        _ = moveServersToRoot(folderId)
        
        // 删除文件夹
        let sql = "DELETE FROM folders WHERE id = ?;"
        let params: [Any] = [folderId.uuidString]
        return db.execute(sql, params: params) > 0
    }
    
    /// 将文件夹内的服务器移动到根目录
    private func moveServersToRoot(_ folderId: UUID) -> Int {
        let sql = "UPDATE servers SET folder_id = NULL WHERE folder_id = ?;"
        let params: [Any] = [folderId.uuidString]
        return db.execute(sql, params: params)
    }
    
    /// 统计文件夹数量
    func count() -> Int {
        let sql = "SELECT COUNT(*) as count FROM folders;"
        guard let rows = db.query(sql), let row = rows.first else {
            return 0
        }
        return row["count"] as? Int ?? 0
    }
    
    /// 统计文件夹内的服务器数量
    func countByFolder(_ folderId: UUID) -> Int {
        let sql = "SELECT COUNT(*) as count FROM servers WHERE folder_id = ?;"
        let params: [Any] = [folderId.uuidString]
        
        guard let rows = db.query(sql, params: params), let row = rows.first else {
            return 0
        }
        return row["count"] as? Int ?? 0
    }
    
    /// 更新文件夹排序
    func updateSortOrder(_ folderId: UUID, sortOrder: Int) -> Bool {
        let sql = "UPDATE folders SET sort_order = ?, updated_at = ? WHERE id = ?;"
        let params: [Any] = [sortOrder, Date().timeIntervalSince1970, folderId.uuidString]
        return db.execute(sql, params: params) > 0
    }
    
    /// 批量更新排序
    func updateSortOrders(_ folderIds: [UUID]) -> Int {
        var updatedCount = 0
        
        db.beginTransaction()
        
        for (index, folderId) in folderIds.enumerated() {
            if updateSortOrder(folderId, sortOrder: index) {
                updatedCount += 1
            }
        }
        
        db.commitTransaction()
        
        return updatedCount
    }
    
    /// 获取文件夹内的服务器
    func getServersInFolder(_ folderId: UUID) -> [Server] {
        let sql = "SELECT * FROM servers WHERE folder_id = ? ORDER BY name ASC;"
        let params: [Any] = [folderId.uuidString]
        
        guard let rows = db.query(sql, params: params) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
    
    /// 获取根目录的服务器
    func getRootServers() -> [Server] {
        let sql = "SELECT * FROM servers WHERE folder_id IS NULL ORDER BY name ASC;"
        
        guard let rows = db.query(sql) else {
            return []
        }
        
        return rows.compactMap { Server.fromDatabaseRow($0) }
    }
}