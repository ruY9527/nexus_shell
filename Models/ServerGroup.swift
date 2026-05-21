import Foundation
import SwiftData

@Model
final class ServerGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, sortOrder, createdAt
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        icon: String = "folder.fill",
        color: String = "#007AFF",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

extension ServerGroup {
    static var defaultGroups: [ServerGroup] {
        [
            ServerGroup(name: "Production", icon: "server.rack", color: "#FF3B30"),
            ServerGroup(name: "Staging", icon: "testtube.2", color: "#FF9500"),
            ServerGroup(name: "Development", icon: "hammer.fill", color: "#34C759"),
            ServerGroup(name: "Personal", icon: "person.fill", color: "#007AFF"),
        ]
    }

    static var preview: ServerGroup {
        ServerGroup(name: "Production", icon: "server.rack", color: "#FF3B30")
    }
}
