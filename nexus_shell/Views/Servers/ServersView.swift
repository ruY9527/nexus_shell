//
//  ServersView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 服务器管理视图
struct ServersView: View {
    @StateObject private var serverStore = ServerStore.shared
    @StateObject private var folderStore = FolderStore.shared
    @State private var showingAddServer = false
    @State private var showingAddFolder = false
    @State private var selectedServer: Server?
    @State private var showingDeleteConfirmation = false
    @State private var serverToDelete: Server?
    @State private var showingDeleteFolderConfirmation = false
    @State private var folderToDelete: ServerFolder?
    @State private var showingFolderNotEmptyAlert = false
    @State private var sortOrder: SortOrder = .name
    @State private var showingFolderPicker = false
    @State private var serverToMove: Server?
    
    private var settings: AppSettings {
        AppSettings.shared
    }
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case status = "Status"
        case lastConnected = "Last Connected"
    }
    
    // 当前显示位置
    var currentLocationName: String {
        if let folderId = serverStore.currentFolderId,
           let folder = folderStore.getFolder(byId: folderId) {
            return folder.name
        }
        return String(localized: "Servers")
    }
    
    // 当前文件夹信息（用于显示标题头部）
    var currentFolder: ServerFolder? {
        if let folderId = serverStore.currentFolderId {
            return folderStore.getFolder(byId: folderId)
        }
        return nil
    }
    
    var sortedServers: [Server] {
        var result = serverStore.servers
        
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .status:
            result.sort { statusPriority($0.status) < statusPriority($1.status) }
        case .lastConnected:
            result.sort { ($0.lastConnectedAt ?? .distantPast) > ($1.lastConnectedAt ?? .distantPast) }
        }
        
        return result
    }
    

    private func statusPriority(_ status: ServerStatus) -> Int {
        switch status {
        case .online: return 0
        case .warning: return 1
        case .offline: return 2
        case .unknown: return 3
        }
    }
    var body: some View {
        NavigationStack {
            Group {
                if folderStore.folders.isEmpty && serverStore.rootServerCount == 0 {
                    EmptyServersView(onAddServer: { showingAddServer = true }, onAddFolder: { showingAddFolder = true })
                } else {
                    serversList
                }
            }
            .navigationTitle(currentLocationName)
            .navigationBarTitleDisplayMode(serverStore.currentFolderId == nil ? .large : .inline)
            .toolbar {
                // 返回按钮（只在文件夹内显示）
                if serverStore.currentFolderId != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            serverStore.selectRootFolder()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        
                        Button {
                            showingAddServer = true
                        } label: {
                            Label("New Server", systemImage: "server.rack")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.accent)
                    }
                    .accessibilityIdentifier("servers.addMenu")
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        // 位置选择
                        Section {
                            Button {
                                serverStore.selectRootFolder()
                            } label: {
                                Label("Root", systemImage: serverStore.currentFolderId == nil ? "checkmark" : "")
                            }
                            
                            ForEach(folderStore.folders) { folder in
                                Button {
                                    serverStore.selectFolder(folder.id)
                                } label: {
                                    Label(folder.name, systemImage: serverStore.currentFolderId == folder.id ? "checkmark" : "")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 排序
                        Section {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button {
                                    sortOrder = order
                                } label: {
                                    Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .accessibilityIdentifier("servers.optionsMenu")
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView(folderId: serverStore.currentFolderId)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingAddFolder) {
                AddFolderView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFolderPicker) {
                if let server = serverToMove {
                    MoveServerSheet(
                        server: server,
                        folders: folderStore.folders,
                        onMove: { folderId in
                            serverStore.updateServerFolder(server.id, folderId: folderId)
                            serverToMove = nil
                            showingFolderPicker = false
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .confirmationDialog(
                "Delete Server?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let server = serverToDelete {
                        serverStore.deleteServer(server)
                        serverToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    serverToDelete = nil
                }
            } message: {
                if let server = serverToDelete {
                    Text("Are you sure you want to delete \"\(server.name)\"? This action cannot be undone.")
                }
            }
            .confirmationDialog(
                "Delete Folder?",
                isPresented: $showingDeleteFolderConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        folderStore.deleteFolder(folder.id)
                        folderToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    folderToDelete = nil
                }
            } message: {
                if let folder = folderToDelete {
                    Text("Are you sure you want to delete \"\(folder.name)\"? This action cannot be undone.")
                }
            }
            // 文件夹不为空的警告
            .alert("Cannot Delete Folder", isPresented: $showingFolderNotEmptyAlert) {
                Button("OK", role: .cancel) {
                    folderToDelete = nil
                }
            } message: {
                if let folder = folderToDelete {
                    let serverCount = folderStore.serverCountInFolder(folder.id)
                    Text("Folder \"\(folder.name)\" contains \(serverCount) servers. Please delete all servers in this folder first before deleting the folder.")
                }
            }
        }
        .background(AppColors.background)
        .onChange(of: folderStore.folders) { _, _ in
            serverStore.loadServers()
        }
    }
    
    private var serversList: some View {
        List {
            // 文件夹信息头部（只在文件夹内显示）
            if let folder = currentFolder {
                Section {
                    FolderHeaderView(folder: folder)
                }
            }
            
            // 文件夹列表（只在根目录显示）
            if serverStore.currentFolderId == nil && !folderStore.folders.isEmpty {
                Section {
                    ForEach(folderStore.folders) { folder in
                        FolderRowView(folder: folder, onTap: {
                            serverStore.selectFolder(folder.id)
                        }, onDelete: {
                            // 先检查文件夹内是否有服务器
                            let serverCount = folderStore.serverCountInFolder(folder.id)
                            if serverCount > 0 {
                                folderToDelete = folder
                                showingFolderNotEmptyAlert = true
                            } else {
                                folderToDelete = folder
                                showingDeleteFolderConfirmation = true
                            }
                        })
                    }
                } header: {
                    Text("Folders")
                }
            }
            
            // 服务器列表
            Section {
                if sortedServers.isEmpty {
                    NoServersInFolderView(
                        folderName: currentLocationName,
                        onAddServer: { showingAddServer = true }
                    )
                } else {
                    ForEach(sortedServers) { server in
                        ServerRowView(server: server)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedServer = server
                                if settings.hapticFeedbackEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    serverToDelete = server
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    serverToMove = server
                                    showingFolderPicker = true
                                } label: {
                                    Label("Move", systemImage: "folder")
                                }
                                .accessibilityIdentifier("serverRow.move.\(server.name)")
                            }
                    }
                }
            } header: {
                if serverStore.currentFolderId == nil {
                    Text("Root Servers")
                } else {
                    Text("Servers")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(isPresented: Binding<Bool>(
            get: { selectedServer != nil },
            set: { if !$0 { selectedServer = nil } }
        )) {
            if let server = selectedServer {
                ServerDetailView(server: server)
            }
        }
    }
}

// MARK: - Folder Header View

struct FolderHeaderView: View {
    let folder: ServerFolder
    
    @StateObject private var folderStore = FolderStore.shared
    
    var serverCount: Int {
        folderStore.serverCountInFolder(folder.id)
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .fill(folder.color.lightColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: folder.icon.systemName)
                    .font(.system(size: 28))
                    .foregroundStyle(folder.color.swiftUIColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(folder.name)
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                if let description = folder.description, !description.isEmpty {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Label("\(serverCount) servers", systemImage: "server.rack")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(folder.color.swiftUIColor)
                    
                    Text(folder.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .listRowBackground(folder.color.lightColor.opacity(0.5))
        .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.sm, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.sm, trailing: DesignSystem.Spacing.md))
        .listRowSeparator(.hidden)
    }
}

// MARK: - Folder Row View

struct FolderRowView: View {
    let folder: ServerFolder
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var folderStore = FolderStore.shared
    
    var serverCount: Int {
        folderStore.serverCountInFolder(folder.id)
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(folder.color.lightColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: folder.icon.systemName)
                    .font(.system(size: 20))
                    .foregroundStyle(folder.color.swiftUIColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(folder.name)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                
                if let description = folder.description, !description.isEmpty {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                Text("\(serverCount) servers")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.7))
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(AppColors.cardBackground)
        .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.sm, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.sm, trailing: DesignSystem.Spacing.md))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("folderRow.\(folder.name)")
    }
}

// MARK: - Server Row View

struct ServerRowView: View {
    @ObservedObject var server: Server
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 状态指示器
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(statusColor)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(server.name)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                
                Text(server.displayAddress)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText)
                
                // 标签
                if !server.tags.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(server.tags.prefix(3), id: \.self) { tag in
                            TagView(text: tag, color: AppColors.accent)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 使用率指标
            if server.status == .online || server.status == .warning {
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    if let cpu = server.cpuUsage {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("CPU")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                            
                            Text("\(Int(cpu))%")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(usageColor(cpu))
                        }
                    }
                    
                    if let memory = server.memoryUsage {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Mem")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                            
                            Text("\(Int(memory))%")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(usageColor(memory))
                        }
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .listRowBackground(AppColors.cardBackground)
        .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.sm, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.sm, trailing: DesignSystem.Spacing.md))
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("serverRow.\(server.name)")
    }
    
    private var statusColor: Color {
        switch server.status {
        case .online: return AppColors.online
        case .offline: return AppColors.offline
        case .warning: return AppColors.warning
        case .unknown: return AppColors.unknown
        }
    }
    
    private var statusIcon: String {
        switch server.status {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func usageColor(_ value: Double) -> Color {
        if value < 50 { return AppColors.online }
        if value < 80 { return AppColors.warning }
        return AppColors.offline
    }
}

// MARK: - Tag View

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(AppTypography.labelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Empty Servers View

struct EmptyServersView: View {
    let onAddServer: () -> Void
    let onAddFolder: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            
            Text("No Servers Yet")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Create folders to organize servers by company, or add servers directly to the root folder.")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    onAddFolder()
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Create Folder")
                    }
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(AppColors.secondaryAccent.opacity(0.2))
                    .cornerRadius(DesignSystem.Radius.md)
                }
                .accessibilityIdentifier("servers.empty.createFolder")
                
                Button {
                    onAddServer()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Server")
                    }
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(AppColors.primaryGradient)
                    .cornerRadius(DesignSystem.Radius.md)
                }
                .accessibilityIdentifier("servers.empty.addServer")
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - No Servers In Folder View

struct NoServersInFolderView: View {
    let folderName: String
    let onAddServer: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "server.rack")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            
            Text("No Servers in \(folderName)")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Button {
                onAddServer()
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Server")
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.accent)
            }
            .accessibilityIdentifier("servers.folder.addServer")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
}

// MARK: - Move Server Sheet

struct MoveServerSheet: View {
    let server: Server
    let folders: [ServerFolder]
    let onMove: (UUID?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onMove(nil)
                    dismiss()
                } label: {
                    moveRow(title: String(localized: "Root"), icon: "tray", isSelected: server.folderId == nil)
                }
                .accessibilityIdentifier("moveServer.root")

                ForEach(folders) { folder in
                    Button {
                        onMove(folder.id)
                        dismiss()
                    } label: {
                        moveRow(
                            title: folder.name,
                            icon: folder.icon.systemName,
                            isSelected: server.folderId == folder.id
                        )
                    }
                    .disabled(server.folderId == folder.id)
                    .accessibilityIdentifier("moveServer.folder.\(folder.name)")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Move Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func moveRow(title: String, icon: String, isSelected: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.secondaryText)

            Text(title)
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

#Preview {
    ServersView()
}
