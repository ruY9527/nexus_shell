//
//  CommandHistoryStore.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  命令历史记录存储
//

import Foundation

/// 命令历史条目
struct CommandHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let command: String
    var serverId: UUID?
    var serverName: String?
    let executedAt: Date
    var useCount: Int
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        command: String,
        serverId: UUID? = nil,
        serverName: String? = nil,
        executedAt: Date = Date(),
        useCount: Int = 1,
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.command = command
        self.serverId = serverId
        self.serverName = serverName
        self.executedAt = executedAt
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }
}

/// 命令历史存储管理器
final class CommandHistoryStore {
    static let shared = CommandHistoryStore()

    private let userDefaults = UserDefaults.standard
    private let historyKey = "nexus_shell_command_history"
    private let maxHistoryCount = 100

    private init() {}

    // MARK: - Public Methods

    /// 添加命令到历史记录
    func addCommand(_ command: String, serverId: UUID? = nil, serverName: String? = nil) {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        var history = loadHistory()

        // 检查是否已存在
        if let index = history.firstIndex(where: { $0.command == command }) {
            // 更新使用次数
            history[index].useCount += 1
            history[index].lastUsedAt = Date()
            history[index].serverId = serverId
            history[index].serverName = serverName
        } else {
            // 添加新记录
            let entry = CommandHistoryEntry(
                command: command,
                serverId: serverId,
                serverName: serverName
            )
            history.insert(entry, at: 0)
        }

        // 保持数量限制
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }

        saveHistory(history)
    }

    /// 获取最近的命令
    func getRecentCommands(limit: Int = 50) -> [String] {
        let history = loadHistory()
        return history.prefix(limit).map { $0.command }
    }

    /// 获取历史记录
    func getHistory(limit: Int = 100) -> [CommandHistoryEntry] {
        return Array(loadHistory().prefix(limit))
    }

    /// 搜索历史命令
    func search(_ query: String, limit: Int = 20) -> [String] {
        guard !query.isEmpty else { return getRecentCommands(limit: limit) }

        let lowercasedQuery = query.lowercased()
        return loadHistory()
            .filter { $0.command.lowercased().contains(lowercasedQuery) }
            .prefix(limit)
            .map { $0.command }
    }

    /// 删除单条历史记录
    func deleteCommand(_ command: String) {
        var history = loadHistory()
        history.removeAll { $0.command == command }
        saveHistory(history)
    }

    /// 清空所有历史记录
    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }

    /// 获取最常用的命令
    func getMostUsedCommands(limit: Int = 10) -> [String] {
        return loadHistory()
            .sorted { $0.useCount > $1.useCount }
            .prefix(limit)
            .map { $0.command }
    }

    // MARK: - Private Methods

    private func loadHistory() -> [CommandHistoryEntry] {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([CommandHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    private func saveHistory(_ history: [CommandHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        userDefaults.set(data, forKey: historyKey)
    }
}

// MARK: - Command Execution Observer

/// 命令执行观察者，用于自动记录命令历史
final class CommandExecutionObserver {
    static let shared = CommandExecutionObserver()

    private init() {}

    func recordCommand(_ command: String, serverId: UUID? = nil, serverName: String? = nil) {
        // 过滤掉空白命令
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 过滤掉特殊命令
        let specialCommands = ["clear", "history"]
        guard !specialCommands.contains(trimmed.lowercased()) else { return }

        CommandHistoryStore.shared.addCommand(trimmed, serverId: serverId, serverName: serverName)
    }
}
