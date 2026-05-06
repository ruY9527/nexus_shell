//
//  BookmarkStore.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  命令书签数据存储
//

import Foundation
import Combine

/// 命令书签
struct CommandBookmark: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var description: String?
    var groupId: UUID?
    var icon: String
    var color: String
    var requiresAdmin: Bool
    var useCount: Int
    var lastUsedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        description: String? = nil,
        groupId: UUID? = nil,
        icon: String = "terminal",
        color: String = "#007AFF",
        requiresAdmin: Bool = false,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.description = description
        self.groupId = groupId
        self.icon = icon
        self.color = color
        self.requiresAdmin = requiresAdmin
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: CommandBookmark, rhs: CommandBookmark) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 书签分组
struct BookmarkGroup: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var isExpanded: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        color: String = "#007AFF",
        sortOrder: Int = 0,
        isExpanded: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.isExpanded = isExpanded
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: BookmarkGroup, rhs: BookmarkGroup) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 预置书签
struct PresetBookmark {
    let name: String
    let command: String
    let description: String?
    let groupName: String
    let icon: String
    let color: String
    let requiresAdmin: Bool

    static let systemCommands: [PresetBookmark] = [
        PresetBookmark(name: "Restart Nginx", command: "sudo systemctl restart nginx", description: "Restart web server", groupName: "System", icon: "arrow.clockwise", color: "#FF9500", requiresAdmin: true),
        PresetBookmark(name: "Restart SSH", command: "sudo systemctl restart sshd", description: "Restart SSH service", groupName: "System", icon: "arrow.clockwise", color: "#FF9500", requiresAdmin: true),
        PresetBookmark(name: "Check Memory", command: "free -h", description: "Display memory usage", groupName: "System", icon: "chart.bar.fill", color: "#5856D6", requiresAdmin: false),
        PresetBookmark(name: "Disk Usage", command: "df -h", description: "Display disk usage", groupName: "System", icon: "internaldrive.fill", color: "#34C759", requiresAdmin: false),
        PresetBookmark(name: "System Log", command: "journalctl -n 50", description: "View recent system logs", groupName: "System", icon: "doc.text.fill", color: "#FF3B30", requiresAdmin: false),
        PresetBookmark(name: "User List", command: "cat /etc/passwd", description: "List all users", groupName: "System", icon: "person.3.fill", color: "#007AFF", requiresAdmin: false),
        PresetBookmark(name: "Network Stats", command: "netstat -tuln", description: "Show network statistics", groupName: "System", icon: "network", color: "#5856D6", requiresAdmin: false),
        PresetBookmark(name: "Process List", command: "ps aux | head -20", description: "Show top processes", groupName: "System", icon: "cpu.fill", color: "#FF9500", requiresAdmin: false)
    ]

    static let dockerCommands: [PresetBookmark] = [
        PresetBookmark(name: "List Containers", command: "docker ps", description: "List running containers", groupName: "Docker", icon: "shippingbox.fill", color: "#2496ED", requiresAdmin: false),
        PresetBookmark(name: "List Images", command: "docker images", description: "List docker images", groupName: "Docker", icon: "photo.fill", color: "#2496ED", requiresAdmin: false),
        PresetBookmark(name: "Compose Up", command: "docker-compose up -d", description: "Start services", groupName: "Docker", icon: "play.fill", color: "#34C759", requiresAdmin: false),
        PresetBookmark(name: "Compose Down", command: "docker-compose down", description: "Stop services", groupName: "Docker", icon: "stop.fill", color: "#FF3B30", requiresAdmin: false),
        PresetBookmark(name: "Docker Stats", command: "docker stats --no-stream", description: "Show resource usage", groupName: "Docker", icon: "chart.bar.fill", color: "#5856D6", requiresAdmin: false),
        PresetBookmark(name: "Container Logs", command: "docker logs -f", description: "Follow container logs", groupName: "Docker", icon: "doc.text.fill", color: "#FF9500", requiresAdmin: false),
        PresetBookmark(name: "Clean Containers", command: "docker container prune -f", description: "Remove stopped containers", groupName: "Docker", icon: "trash.fill", color: "#FF3B30", requiresAdmin: false),
        PresetBookmark(name: "Clean Images", command: "docker image prune -f", description: "Remove unused images", groupName: "Docker", icon: "trash.fill", color: "#FF3B30", requiresAdmin: false)
    ]

    static let gitCommands: [PresetBookmark] = [
        PresetBookmark(name: "Git Pull", command: "git pull origin main", description: "Pull from remote", groupName: "Git", icon: "arrow.down.circle.fill", color: "#FF9500", requiresAdmin: false),
        PresetBookmark(name: "Git Push", command: "git push origin main", description: "Push to remote", groupName: "Git", icon: "arrow.up.circle.fill", color: "#FF9500", requiresAdmin: false),
        PresetBookmark(name: "Git Status", command: "git status", description: "Show working tree status", groupName: "Git", icon: "arrow.triangle.2.circlepath", color: "#34C759", requiresAdmin: false),
        PresetBookmark(name: "Git Branch", command: "git branch -a", description: "List all branches", groupName: "Git", icon: "arrow.branch", color: "#007AFF", requiresAdmin: false),
        PresetBookmark(name: "Git Diff", command: "git diff", description: "Show changes", groupName: "Git", icon: "doc.text.magnifyingglass", color: "#FF3B30", requiresAdmin: false),
        PresetBookmark(name: "Git Log", command: "git log --oneline -10", description: "Show recent commits", groupName: "Git", icon: "clock.fill", color: "#5856D6", requiresAdmin: false),
        PresetBookmark(name: "Git Stash", command: "git stash", description: "Stash changes", groupName: "Git", icon: "archivebox.fill", color: "#FF9500", requiresAdmin: false),
        PresetBookmark(name: "Git Fetch All", command: "git fetch --all", description: "Fetch all remotes", groupName: "Git", icon: "arrow.down.circle", color: "#007AFF", requiresAdmin: false)
    ]

    static let databaseCommands: [PresetBookmark] = [
        PresetBookmark(name: "MySQL Connect", command: "mysql -u root -p", description: "Connect to MySQL", groupName: "Database", icon: "cylinder.fill", color: "#007AFF", requiresAdmin: false),
        PresetBookmark(name: "PostgreSQL Connect", command: "psql -U postgres", description: "Connect to PostgreSQL", groupName: "Database", icon: "cylinder.fill", color: "#336791", requiresAdmin: false),
        PresetBookmark(name: "Redis Connect", command: "redis-cli", description: "Connect to Redis", groupName: "Database", icon: "cylinder.fill", color: "#DC382D", requiresAdmin: false),
        PresetBookmark(name: "MongoDB Shell", command: "mongosh", description: "Connect to MongoDB", groupName: "Database", icon: "cylinder.fill", color: "#47A248", requiresAdmin: false),
        PresetBookmark(name: "List Databases", command: "show databases;", description: "List MySQL databases", groupName: "Database", icon: "list.bullet.rectangle.fill", color: "#007AFF", requiresAdmin: false),
        PresetBookmark(name: "Show Tables", command: "show tables;", description: "List database tables", groupName: "Database", icon: "tablecells.fill", color: "#007AFF", requiresAdmin: false)
    ]

    static let networkCommands: [PresetBookmark] = [
        PresetBookmark(name: "Ping Test", command: "ping -c 4 8.8.8.8", description: "Test network connectivity", groupName: "Network", icon: "antenna.radiowaves.left.and.right", color: "#34C759", requiresAdmin: false),
        PresetBookmark(name: "Traceroute", command: "traceroute", description: "Trace network route", groupName: "Network", icon: "point.topleft.down.curvedto.point.bottomright.up.fill", color: "#FF9500", requiresAdmin: false),
        PresetBookmark(name: "DNS Lookup", command: "nslookup", description: "DNS lookup", groupName: "Network", icon: "magnifyingglass", color: "#007AFF", requiresAdmin: false),
        PresetBookmark(name: "Port Scan", command: "nmap -sV localhost", description: "Scan local ports", groupName: "Network", icon: "network", color: "#FF3B30", requiresAdmin: true),
        PresetBookmark(name: "IP Address", command: "ip addr", description: "Show IP addresses", groupName: "Network", icon: "number.circle.fill", color: "#5856D6", requiresAdmin: false),
        PresetBookmark(name: "Routing Table", command: "ip route", description: "Show routing table", groupName: "Network", icon: "point.3.connected.trianglepath.dotted", color: "#FF9500", requiresAdmin: false)
    ]

    static var all: [PresetBookmark] {
        systemCommands + dockerCommands + gitCommands + databaseCommands + networkCommands
    }
}

/// 书签存储数据结构
private struct BookmarkStorage: Codable {
    var bookmarks: [CommandBookmark]
    var groups: [BookmarkGroup]
    var hasInitializedPresets: Bool

    init(bookmarks: [CommandBookmark] = [], groups: [BookmarkGroup] = [], hasInitializedPresets: Bool = false) {
        self.bookmarks = bookmarks
        self.groups = groups
        self.hasInitializedPresets = hasInitializedPresets
    }
}

/// 书签存储管理器
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "nexus_shell_bookmarks"

    @Published private(set) var bookmarks: [CommandBookmark] = []
    @Published private(set) var groups: [BookmarkGroup] = []
    @Published private(set) var hasInitializedPresets: Bool = false

    private init() {
        loadFromStorage()
    }

    // MARK: - Public Methods

    /// 添加书签
    func addBookmark(_ bookmark: CommandBookmark) {
        bookmarks.append(bookmark)
        saveToStorage()
    }

    /// 更新书签
    func updateBookmark(_ bookmark: CommandBookmark) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            var updated = bookmark
            updated.updatedAt = Date()
            bookmarks[index] = updated
            saveToStorage()
        }
    }

    /// 删除书签
    func deleteBookmark(_ bookmark: CommandBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveToStorage()
    }

    /// 删除书签 by ID
    func deleteBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveToStorage()
    }

    /// 使用书签（更新使用次数）
    func useBookmark(_ bookmark: CommandBookmark) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].useCount += 1
            bookmarks[index].lastUsedAt = Date()
            saveToStorage()
        }
    }

    /// 获取书签 by ID
    func getBookmark(id: UUID) -> CommandBookmark? {
        bookmarks.first { $0.id == id }
    }

    /// 获取分组内的书签
    func getBookmarks(inGroup groupId: UUID?) -> [CommandBookmark] {
        bookmarks.filter { $0.groupId == groupId }
    }

    /// 获取未分组书签
    func getUngroupedBookmarks() -> [CommandBookmark] {
        bookmarks.filter { $0.groupId == nil }
    }

    /// 获取最常用的书签
    func getMostUsedBookmarks(limit: Int = 5) -> [CommandBookmark] {
        Array(bookmarks.sorted { $0.useCount > $1.useCount }.prefix(limit))
    }

    /// 获取最近使用的书签
    func getRecentlyUsedBookmarks(limit: Int = 5) -> [CommandBookmark] {
        let withLastUsed = bookmarks.filter { $0.lastUsedAt != nil }
        return Array(withLastUsed.sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }.prefix(limit))
    }

    // MARK: - Group Methods

    /// 添加分组
    func addGroup(_ group: BookmarkGroup) {
        groups.append(group)
        saveToStorage()
    }

    /// 更新分组
    func updateGroup(_ group: BookmarkGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            var updated = group
            updated.updatedAt = Date()
            groups[index] = updated
            saveToStorage()
        }
    }

    /// 删除分组（同时删除分组内所有书签）
    func deleteGroup(_ group: BookmarkGroup) {
        // 删除分组内的书签
        bookmarks.removeAll { $0.groupId == group.id }
        // 删除分组
        groups.removeAll { $0.id == group.id }
        saveToStorage()
    }

    /// 获取分组 by ID
    func getGroup(id: UUID) -> BookmarkGroup? {
        groups.first { $0.id == id }
    }

    // MARK: - Preset Initialization

    /// 初始化预置书签
    func initializePresetsIfNeeded() {
        guard !hasInitializedPresets else { return }

        // 创建默认分组
        let defaultGroups: [(String, String, String, Int)] = [
            ("System", "gearshape.fill", "#FF9500", 0),
            ("Docker", "shippingbox.fill", "#2496ED", 1),
            ("Git", "arrow.triangle.2.circlepath", "#FF9500", 2),
            ("Database", "cylinder.fill", "#007AFF", 3),
            ("Network", "network", "#34C759", 4)
        ]

        var groupMap: [String: UUID] = [:]

        for (name, icon, color, order) in defaultGroups {
            let group = BookmarkGroup(
                name: name,
                icon: icon,
                color: color,
                sortOrder: order
            )
            groups.append(group)
            groupMap[name] = group.id
        }

        // 创建预置书签
        for preset in PresetBookmark.all {
            guard let groupId = groupMap[preset.groupName] else { continue }
            let bookmark = CommandBookmark(
                name: preset.name,
                command: preset.command,
                description: preset.description,
                groupId: groupId,
                icon: preset.icon,
                color: preset.color,
                requiresAdmin: preset.requiresAdmin
            )
            bookmarks.append(bookmark)
        }

        hasInitializedPresets = true
        saveToStorage()
    }

    /// 搜索书签
    func search(_ query: String) -> [CommandBookmark] {
        guard !query.isEmpty else { return bookmarks }
        let lowercased = query.lowercased()
        return bookmarks.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.command.lowercased().contains(lowercased) ||
            ($0.description?.lowercased().contains(lowercased) ?? false)
        }
    }

    /// 按使用次数排序
    func sortByUseCount() {
        bookmarks.sort { $0.useCount > $1.useCount }
    }

    /// 按名称排序
    func sortByName() {
        bookmarks.sort { $0.name.lowercased() < $1.name.lowercased() }
    }

    /// 按创建时间排序
    func sortByCreatedAt() {
        bookmarks.sort { $0.createdAt > $1.createdAt }
    }

    // MARK: - Private Methods

    private func loadFromStorage() {
        guard let data = userDefaults.data(forKey: storageKey),
              let storage = try? JSONDecoder().decode(BookmarkStorage.self, from: data) else {
            return
        }
        bookmarks = storage.bookmarks
        groups = storage.groups
        hasInitializedPresets = storage.hasInitializedPresets
    }

    private func saveToStorage() {
        let storage = BookmarkStorage(
            bookmarks: bookmarks,
            groups: groups,
            hasInitializedPresets: hasInitializedPresets
        )
        guard let data = try? JSONEncoder().encode(storage) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
