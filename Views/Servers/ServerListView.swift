import SwiftUI
import SwiftData

struct ServerListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ServerListViewModel?
    @State private var showAddServer: Bool = false
    @State private var selectedServer: Server?
    @State private var showTerminal: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var serverToDelete: Server?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    @Bindable var vm = viewModel
                    serverListContent(vm: viewModel, searchText: $vm.searchText)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedServer = nil
                        showAddServer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddServer) {
                NavigationStack {
                    ServerEditView(server: selectedServer) { server in
                        if selectedServer != nil {
                            viewModel?.updateServer(server)
                        } else {
                            viewModel?.addServer(server)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showTerminal) {
                if let selectedServer {
                    TerminalView(server: selectedServer)
                }
            }
            .confirmationDialog("Delete Server?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let server = serverToDelete {
                        viewModel?.deleteServer(server)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this server? This action cannot be undone.")
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ServerListViewModel(modelContext: modelContext)
                    viewModel?.loadServers()
                }
            }
        }
    }

    @ViewBuilder
    private func serverListContent(vm: ServerListViewModel, searchText: Binding<String>) -> some View {
        if vm.servers.isEmpty && vm.searchText.isEmpty {
            ContentUnavailableView {
                Label("No Servers", systemImage: "server.rack")
            } description: {
                Text("Add your first server to get started")
            } actions: {
                Button("Add Server") { showAddServer = true }
            }
        } else {
            List {
                if vm.searchText.isEmpty {
                    groupsSection(vm: vm)
                }
                allServersSection(vm: vm)
            }
            .searchable(text: searchText, prompt: "Search servers...")
            .overlay {
                if vm.filteredServers.isEmpty && !vm.searchText.isEmpty {
                    ContentUnavailableView.search(text: vm.searchText)
                }
            }
        }
    }

    @ViewBuilder
    private func groupsSection(vm: ServerListViewModel) -> some View {
        Section("Groups") {
            ForEach(vm.groups) { group in
                NavigationLink {
                    ServerListFilteredView(
                        viewModel: vm,
                        group: group,
                        selectedServer: $selectedServer,
                        showTerminal: $showTerminal
                    )
                } label: {
                    HStack {
                        Image(systemName: group.icon)
                            .foregroundStyle(Color(hex: group.color))
                        Text(group.name)
                        Spacer()
                        Text("\(vm.serverCount(for: group))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func allServersSection(vm: ServerListViewModel) -> some View {
        Section("All Servers") {
            ForEach(vm.filteredServers) { server in
                ServerListRow(
                    server: server,
                    onSelect: {
                        selectedServer = server
                        showTerminal = true
                    },
                    onEdit: {
                        selectedServer = server
                        showAddServer = true
                    },
                    onDelete: {
                        serverToDelete = server
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }
}

struct ServerRowView: View {
    let server: Server

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: server.color))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "server.rack")
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)

                Text(server.displayAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let lastConnected = server.lastConnected {
                Text(lastConnected.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ServerListRow: View {
    let server: Server
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ServerRowView(server: server)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.selection()
                onSelect()
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}

struct ServerListFilteredView: View {
    let viewModel: ServerListViewModel
    let group: ServerGroup
    @Binding var selectedServer: Server?
    @Binding var showTerminal: Bool

    var body: some View {
        List {
            ForEach(viewModel.servers.filter { $0.groupId == group.id }) { server in
                ServerRowView(server: server)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedServer = server
                        showTerminal = true
                    }
            }
        }
        .navigationTitle(group.name)
    }
}

#Preview {
    ServerListView()
        .modelContainer(for: [Server.self, ServerGroup.self, CommandHistory.self, QuickCommand.self])
}
