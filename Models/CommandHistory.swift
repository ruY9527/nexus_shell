import Foundation
import SwiftData

@Model
final class CommandHistory: Identifiable {
    var id: UUID
    var serverId: UUID
    var command: String
    var output: String
    var exitCode: Int?
    var executedAt: Date
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        serverId: UUID,
        command: String,
        output: String = "",
        exitCode: Int? = nil,
        executedAt: Date = Date(),
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.serverId = serverId
        self.command = command
        self.output = output
        self.exitCode = exitCode
        self.executedAt = executedAt
        self.duration = duration
    }
}

extension CommandHistory {
    var isSuccessful: Bool {
        exitCode == 0
    }

    var formattedDuration: String {
        String(format: "%.2fs", duration)
    }

    static func recentCommands(for serverId: UUID, limit: Int = 50) -> FetchDescriptor<CommandHistory> {
        var descriptor = FetchDescriptor<CommandHistory>(
            predicate: #Predicate { $0.serverId == serverId },
            sortBy: [SortDescriptor(\.executedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return descriptor
    }
}
