import Foundation
import SwiftData

final class CommandHistoryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveCommand(_ command: String, serverId: UUID, output: String = "", exitCode: Int? = nil, duration: TimeInterval = 0) {
        let history = CommandHistory(
            serverId: serverId,
            command: command,
            output: output,
            exitCode: exitCode,
            duration: duration
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    func getRecentCommands(for serverId: UUID, limit: Int = 50) -> [CommandHistory] {
        let descriptor = CommandHistory.recentCommands(for: serverId, limit: limit)
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getAllCommands(limit: Int = 200) -> [CommandHistory] {
        var descriptor = FetchDescriptor<CommandHistory>(
            sortBy: [SortDescriptor(\.executedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func searchCommands(_ query: String) -> [CommandHistory] {
        let descriptor = FetchDescriptor<CommandHistory>(
            predicate: #Predicate { $0.command.contains(query) },
            sortBy: [SortDescriptor(\.executedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func clearHistory(for serverId: UUID? = nil) {
        if let serverId {
            let descriptor = FetchDescriptor<CommandHistory>(
                predicate: #Predicate { $0.serverId == serverId }
            )
            if let items = try? modelContext.fetch(descriptor) {
                items.forEach { modelContext.delete($0) }
            }
        } else {
            try? modelContext.delete(model: CommandHistory.self)
        }
        try? modelContext.save()
    }

    func getUniqueCommands(for serverId: UUID, limit: Int = 20) -> [String] {
        let commands = getRecentCommands(for: serverId, limit: 200)
        var seen = Set<String>()
        var unique: [String] = []

        for history in commands {
            if !seen.contains(history.command) {
                seen.insert(history.command)
                unique.append(history.command)
            }
            if unique.count >= limit { break }
        }

        return unique
    }
}
