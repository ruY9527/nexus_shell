//
//  Server.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Combine

/// 服务器连接状态
enum ServerStatus: String, Codable, CaseIterable, Sendable {
    case online = "Online"
    case offline = "Offline"
    case warning = "Warning"
    case unknown = "Unknown"
    
    var localizedKey: String {
        rawValue
    }
}

/// 认证方式
enum AuthMethod: String, Codable, CaseIterable, Sendable {
    case password = "Password"
    case privateKey = "PrivateKey"
}

/// 服务器模型 - 使用 SQLite 存储
class Server: Identifiable, ObservableObject, Equatable, Hashable {
    /// 唯一标识符
    var id: UUID
    
    /// 所属文件夹ID (nil 表示根目录)
    var folderId: UUID?
    
    /// 服务器显示名称
    @Published var name: String
    
    /// 主机地址 (IP 或域名)
    @Published var host: String
    
    /// SSH 端口
    @Published var port: Int
    
    /// 用户名
    @Published var username: String
    
    /// 认证方式
    @Published var authMethod: AuthMethod
    
    /// 密码标识 (仅当 authMethod == .password 时有效)
    var passwordKeychainId: String?
    
    /// 私钥标识 (仅当 authMethod == .privateKey 时有效)
    var privateKeyKeychainId: String?
    
    /// 服务器标签 (用于分类)
    @Published var tags: [String]
    
    /// 创建时间
    var createdAt: Date
    
    /// 最后连接时间
    @Published var lastConnectedAt: Date?
    
    /// 当前状态
    @Published var status: ServerStatus
    
    /// CPU 使用率 (0-100)
    @Published var cpuUsage: Double?
    
    /// 内存使用率 (0-100)
    @Published var memoryUsage: Double?
    
    /// 服务器备注
    @Published var notes: String?
    
    init(
        id: UUID = UUID(),
        folderId: UUID? = nil,
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        passwordKeychainId: String? = nil,
        privateKeyKeychainId: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil,
        status: ServerStatus = .unknown,
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.folderId = folderId
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.passwordKeychainId = passwordKeychainId
        self.privateKeyKeychainId = privateKeyKeychainId
        self.tags = tags
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
        self.status = status
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    
    /// 显示地址 (host:port)
    var displayAddress: String {
        if port == 22 {
            return host
        }
        return "\(host):\(port)"
    }
    
    /// 状态颜色
    var statusColor: String {
        switch status {
        case .online: return "green"
        case .offline: return "red"
        case .warning: return "orange"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Database Mapping

extension Server {
    /// 从数据库行创建 Server
    static func fromDatabaseRow(_ row: [String: Any]) -> Server? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = row["name"] as? String,
              let host = row["host"] as? String,
              let port = row["port"] as? Int,
              let username = row["username"] as? String,
              let authMethodString = row["auth_method"] as? String,
              let authMethod = AuthMethod(rawValue: authMethodString),
              let createdAtTimestamp = row["created_at"] as? Double else {
            return nil
        }
        
        let statusString = row["status"] as? String ?? "Unknown"
        let status = ServerStatus(rawValue: statusString) ?? .unknown
        
        // 解析 folderId
        let folderIdString = row["folder_id"] as? String
        let folderId = folderIdString != nil ? UUID(uuidString: folderIdString!) : nil
        
        // 解析 tags（JSON 数组字符串）
        let tagsString = row["tags"] as? String ?? ""
        let tags = tagsString.isEmpty ? [] : tagsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        let server = Server(
            id: id,
            folderId: folderId,
            name: name,
            host: host,
            port: port,
            username: username,
            authMethod: authMethod,
            passwordKeychainId: row["password_keychain_id"] as? String,
            privateKeyKeychainId: row["private_key_keychain_id"] as? String,
            tags: tags,
            createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
            lastConnectedAt: (row["last_connected_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
            status: status,
            cpuUsage: row["cpu_usage"] as? Double,
            memoryUsage: row["memory_usage"] as? Double,
            notes: row["notes"] as? String
        )
        
        return server
    }
    
    /// Equatable 实现
    static func == (lhs: Server, rhs: Server) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Hashable 实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 转换为数据库参数
    func toDatabaseParams() -> [Any] {
        let tagsString = tags.joined(separator: ",")
        let lastConnectedTimestamp = lastConnectedAt?.timeIntervalSince1970
        
        return [
            id.uuidString,
            folderId?.uuidString ?? NSNull(),
            name,
            host,
            port,
            username,
            authMethod.rawValue,
            passwordKeychainId ?? NSNull(),
            privateKeyKeychainId ?? NSNull(),
            tagsString,
            createdAt.timeIntervalSince1970,
            lastConnectedTimestamp ?? NSNull(),
            status.rawValue,
            cpuUsage ?? NSNull(),
            memoryUsage ?? NSNull(),
            notes ?? NSNull()
        ]
    }
}