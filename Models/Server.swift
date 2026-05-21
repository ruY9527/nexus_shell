import Foundation
import SwiftData

@Model
final class Server: Identifiable, Codable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var groupId: UUID?
    var tags: [String]
    var lastConnected: Date?
    var createdAt: Date
    var notes: String
    var color: String

    enum AuthMethod: String, Codable, CaseIterable {
        case password
        case privateKey
    }

    enum CodingKeys: String, CodingKey {
        case id, name, host, port, username, authMethod, groupId, tags
        case lastConnected, createdAt, notes, color
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        host: String = "",
        port: Int = 22,
        username: String = "",
        authMethod: AuthMethod = .password,
        groupId: UUID? = nil,
        tags: [String] = [],
        lastConnected: Date? = nil,
        createdAt: Date = Date(),
        notes: String = "",
        color: String = "#007AFF"
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.groupId = groupId
        self.tags = tags
        self.lastConnected = lastConnected
        self.createdAt = createdAt
        self.notes = notes
        self.color = color
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        username = try container.decode(String.self, forKey: .username)
        authMethod = try container.decode(AuthMethod.self, forKey: .authMethod)
        groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        tags = try container.decode([String].self, forKey: .tags)
        lastConnected = try container.decodeIfPresent(Date.self, forKey: .lastConnected)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        notes = try container.decode(String.self, forKey: .notes)
        color = try container.decode(String.self, forKey: .color)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(username, forKey: .username)
        try container.encode(authMethod, forKey: .authMethod)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(lastConnected, forKey: .lastConnected)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(notes, forKey: .notes)
        try container.encode(color, forKey: .color)
    }
}

extension Server {
    var displayAddress: String {
        "\(username)@\(host):\(port)"
    }

    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && !username.isEmpty && port > 0 && port <= 65535
    }

    static var preview: Server {
        Server(
            name: "Production Server",
            host: "192.168.1.100",
            port: 22,
            username: "admin",
            authMethod: .password
        )
    }
}
