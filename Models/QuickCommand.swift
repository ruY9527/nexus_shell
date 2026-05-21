import Foundation
import SwiftData

@Model
final class QuickCommand: Identifiable, Codable {
    var id: UUID
    var name: String
    var command: String
    var icon: String
    var category: String
    var sortOrder: Int
    var isGlobal: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, command, icon, category, sortOrder, isGlobal
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        command: String = "",
        icon: String = "terminal.fill",
        category: String = "General",
        sortOrder: Int = 0,
        isGlobal: Bool = true
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.icon = icon
        self.category = category
        self.sortOrder = sortOrder
        self.isGlobal = isGlobal
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        command = try container.decode(String.self, forKey: .command)
        icon = try container.decode(String.self, forKey: .icon)
        category = try container.decode(String.self, forKey: .category)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        isGlobal = try container.decode(Bool.self, forKey: .isGlobal)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(command, forKey: .command)
        try container.encode(icon, forKey: .icon)
        try container.encode(category, forKey: .category)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(isGlobal, forKey: .isGlobal)
    }
}

extension QuickCommand {
    static var defaultCommands: [QuickCommand] {
        [
            QuickCommand(name: "System Info", command: "uname -a", icon: "info.circle.fill", category: "System"),
            QuickCommand(name: "Disk Usage", command: "df -h", icon: "internaldrive.fill", category: "System"),
            QuickCommand(name: "Memory", command: "free -h", icon: "memorychip.fill", category: "System"),
            QuickCommand(name: "Processes", command: "top -bn1 | head -20", icon: "chart.bar.fill", category: "System"),
            QuickCommand(name: "Network", command: "ip addr show", icon: "network", category: "Network"),
            QuickCommand(name: "Docker PS", command: "docker ps", icon: "shippingbox.fill", category: "Docker"),
            QuickCommand(name: "Docker Logs", command: "docker logs --tail 50", icon: "doc.text.fill", category: "Docker"),
            QuickCommand(name: "List Files", command: "ls -la", icon: "folder.fill", category: "Files"),
            QuickCommand(name: "Current Dir", command: "pwd", icon: "mappin.circle.fill", category: "Files"),
        ]
    }

    static var preview: QuickCommand {
        QuickCommand(name: "System Info", command: "uname -a", icon: "info.circle.fill", category: "System")
    }
}
