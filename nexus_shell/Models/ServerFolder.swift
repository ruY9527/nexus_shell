//
//  ServerFolder.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import SwiftUI

/// 服务器文件夹模型
/// 用于按公司/项目分组管理服务器
class ServerFolder: Identifiable, Equatable {
    var id: UUID
    var name: String
    var color: FolderColor
    var icon: FolderIcon
    var description: String?
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        color: FolderColor = .blue,
        icon: FolderIcon = .folder,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
    
    static func == (lhs: ServerFolder, rhs: ServerFolder) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 从数据库行创建
    static func fromDatabaseRow(_ row: [String: Any]) -> ServerFolder? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = row["name"] as? String,
              let colorString = row["color"] as? String,
              let color = FolderColor(rawValue: colorString),
              let iconString = row["icon"] as? String,
              let icon = FolderIcon(rawValue: iconString),
              let createdAtValue = row["created_at"] as? Double,
              let updatedAtValue = row["updated_at"] as? Double,
              let sortOrderValue = row["sort_order"] as? Int else {
            return nil
        }
        
        return ServerFolder(
            id: id,
            name: name,
            color: color,
            icon: icon,
            description: row["description"] as? String,
            createdAt: Date(timeIntervalSince1970: createdAtValue),
            updatedAt: Date(timeIntervalSince1970: updatedAtValue),
            sortOrder: sortOrderValue
        )
    }
}

// MARK: - Folder Color

/// 文件夹颜色
enum FolderColor: String, Codable, CaseIterable {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case gray = "gray"
    
    var swiftUIColor: Color {
        switch self {
        case .blue: return Color.blue
        case .green: return Color.green
        case .orange: return Color.orange
        case .red: return Color.red
        case .purple: return Color.purple
        case .pink: return Color.pink
        case .yellow: return Color.yellow
        case .gray: return Color.gray
        }
    }
    
    var lightColor: Color {
        swiftUIColor.opacity(0.15)
    }
}

// MARK: - Folder Icon

/// 文件夹图标
enum FolderIcon: String, Codable, CaseIterable {
    case folder = "folder.fill"
    case building = "building.2.fill"
    case globe = "globe"
    case network = "network"
    case cloud = "cloud.fill"
    case server = "server.rack"
    case house = "house.fill"
    case briefcase = "briefcase.fill"
    case gear = "gear"
    case star = "star.fill"
    
    var systemName: String {
        return rawValue
    }
}