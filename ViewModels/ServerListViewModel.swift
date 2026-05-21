import Foundation
import SwiftData

@Observable
final class ServerListViewModel {
    var servers: [Server] = []
    var groups: [ServerGroup] = []
    var searchText: String = ""
    var selectedGroup: ServerGroup?
    var isLoading: Bool = false
    var errorMessage: String?

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var filteredServers: [Server] {
        var result = servers

        if let selectedGroup {
            result = result.filter { $0.groupId == selectedGroup.id }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.host.lowercased().contains(query) ||
                $0.username.lowercased().contains(query) ||
                $0.tags.contains { $0.lowercased().contains(query) }
            }
        }

        return result
    }

    func loadServers() {
        isLoading = true
        let descriptor = FetchDescriptor<Server>(sortBy: [SortDescriptor(\.lastConnected, order: .reverse)])
        servers = (try? modelContext.fetch(descriptor)) ?? []

        let groupDescriptor = FetchDescriptor<ServerGroup>(sortBy: [SortDescriptor(\.sortOrder)])
        groups = (try? modelContext.fetch(groupDescriptor)) ?? []

        if groups.isEmpty {
            ServerGroup.defaultGroups.forEach { modelContext.insert($0) }
            groups = ServerGroup.defaultGroups
            try? modelContext.save()
        }

        isLoading = false
    }

    func addServer(_ server: Server) {
        modelContext.insert(server)
        servers.append(server)
        save()
    }

    func updateServer(_ server: Server) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            save()
        }
    }

    func deleteServer(_ server: Server) {
        modelContext.delete(server)
        servers.removeAll { $0.id == server.id }
        try? KeychainService.shared.deleteCredentials(for: server.id)
        save()
    }

    func deleteServers(at offsets: IndexSet) {
        let serversToDelete = offsets.map { filteredServers[$0] }
        for server in serversToDelete {
            deleteServer(server)
        }
    }

    func moveServer(from source: IndexSet, to destination: Int) {
        var sorted = filteredServers
        sorted.move(fromOffsets: source, toOffset: destination)
        servers = sorted
        save()
    }

    func addGroup(_ group: ServerGroup) {
        modelContext.insert(group)
        groups.append(group)
        save()
    }

    func deleteGroup(_ group: ServerGroup) {
        modelContext.delete(group)
        groups.removeAll { $0.id == group.id }
        for server in servers where server.groupId == group.id {
            server.groupId = nil
        }
        save()
    }

    func serverCount(for group: ServerGroup) -> Int {
        servers.filter { $0.groupId == group.id }.count
    }

    func updateLastConnected(for server: Server) {
        server.lastConnected = Date()
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}
