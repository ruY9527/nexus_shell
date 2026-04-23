//
//  LogsView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 日志视图
struct LogsView: View {
    @StateObject private var logStore = LogStore.shared
    @StateObject private var serverStore = ServerStore.shared
    @State private var searchText: String = ""
    @State private var showingClearConfirmation = false
    @State private var clearOption: ClearOption = .all
    @State private var showingStorageInfo = false
    
    private var settings: AppSettings {
        AppSettings.shared
    }

    private var allServers: [Server] {
        serverStore.allServers
    }
    
    enum ClearOption {
        case all
        case olderThan7Days
        case selectedServer
    }
    
    var filteredEntries: [LogEntry] {
        var entries = logStore.logs
        
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.level.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if logStore.logs.isEmpty && allServers.isEmpty {
                    LogsEmptyState()
                } else {
                    logListView
                }
            }
            .navigationTitle(String(localized: "Logs"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // 服务器过滤
                        Button {
                            logStore.clearFilters()
                            if settings.hapticFeedbackEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Label("All Servers", systemImage: logStore.selectedServerId == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(allServers) { server in
                            Button {
                                logStore.filterByServer(server.id)
                                if settings.hapticFeedbackEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } label: {
                                Label(server.name, systemImage: logStore.selectedServerId == server.id ? "checkmark" : "")
                            }
                        }
                        
                        Divider()
                        
                        // 存储信息
                        Button {
                            showingStorageInfo = true
                        } label: {
                            Label("Storage Info", systemImage: "internaldrive")
                        }
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            if let serverId = logStore.selectedServerId,
                               let server = allServers.first(where: { $0.id == serverId }) {
                                Text(server.name)
                                    .font(AppTypography.labelSmall)
                            } else {
                                Text("All")
                                    .font(AppTypography.labelSmall)
                            }
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppColors.cardBackground)
                        .cornerRadius(DesignSystem.Radius.sm)
                    }
                }
                
                // 清除按钮
                if !logStore.logs.isEmpty {
                    ToolbarItem(placement: .secondaryAction) {
                        Menu {
                            Button {
                                clearOption = .all
                                showingClearConfirmation = true
                            } label: {
                                Label("Clear All Logs", systemImage: "trash")
                            }
                            
                            Button {
                                clearOption = .olderThan7Days
                                showingClearConfirmation = true
                            } label: {
                                Label("Clear Logs Older Than 7 Days", systemImage: "calendar.badge.minus")
                            }
                            
                            if logStore.selectedServerId != nil {
                                Button {
                                    clearOption = .selectedServer
                                    showingClearConfirmation = true
                                } label: {
                                    Label("Clear Logs for Selected Server", systemImage: "server.rack")
                                }
                            }
                        } label: {
                            Image(systemName: "trash.circle")
                                .foregroundStyle(AppColors.offline)
                        }
                    }
                }
            }
            .confirmationDialog(
                clearDialogTitle,
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear", role: .destructive) {
                    performClear()
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text(clearDialogMessage)
            }
            .sheet(isPresented: $showingStorageInfo) {
                LogStorageInfoSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .background(AppColors.background)
        .onChange(of: searchText) { _, newValue in
            logStore.searchText = newValue
        }
    }
    
    private var logListView: some View {
        Group {
            if filteredEntries.isEmpty {
                NoLogsView(
                    selectedServerId: logStore.selectedServerId,
                    onSelectServer: { logStore.clearFilters() },
                    servers: allServers
                )
            } else {
                List {
                    // 日志统计头部
                    LogStatsHeader(logStore: logStore)
                    
                    // 搜索框
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondaryText)
                        
                        TextField("Search logs...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(AppColors.primaryText)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(AppColors.cardBackground)
                    .cornerRadius(DesignSystem.Radius.sm)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.Spacing.md, bottom: 0, trailing: DesignSystem.Spacing.md))
                    .listRowSeparator(.hidden)
                    
                    ForEach(filteredEntries) { entry in
                        LogEntryRow(
                            entry: entry,
                            serverName: allServers.first(where: { $0.id == entry.serverId })?.name ?? "Unknown"
                        )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var clearDialogTitle: String {
        switch clearOption {
        case .all:
            return "Clear All Logs?"
        case .olderThan7Days:
            return "Clear Old Logs?"
        case .selectedServer:
            return "Clear Server Logs?"
        }
    }
    
    private var clearDialogMessage: String {
        switch clearOption {
        case .all:
            return "This will remove all \(logStore.totalLogs) log entries. This action cannot be undone."
        case .olderThan7Days:
            return "Logs older than 7 days will be removed. Recent logs will be preserved."
        case .selectedServer:
            if let serverId = logStore.selectedServerId,
               let server = allServers.first(where: { $0.id == serverId }) {
                return "Logs for \"\(server.name)\" will be removed. Other server logs will be preserved."
            }
            return "Logs for selected server will be removed."
        }
    }
    
    private func performClear() {
        switch clearOption {
        case .all:
            logStore.clearAllLogs()
        case .olderThan7Days:
            logStore.cleanupOldLogs(days: 7)
        case .selectedServer:
            if let serverId = logStore.selectedServerId {
                logStore.clearLogsForServer(serverId)
            }
        }
        
        if settings.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Log Stats Header

struct LogStatsHeader: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // 总数
                StatBadge(
                    title: String(localized: "Total"),
                    value: logStore.totalLogs,
                    color: AppColors.accent
                )
                
                // 错误数
                StatBadge(
                    title: String(localized: "Errors"),
                    value: logStore.levelCounts[.error] ?? 0,
                    color: AppColors.offline
                )
                
                // 警告数
                StatBadge(
                    title: String(localized: "Warnings"),
                    value: logStore.levelCounts[.warning] ?? 0,
                    color: AppColors.warning
                )
                
                // 存储大小
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Text(logStore.sizeEstimate)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            
            // 保留策略提示
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                
                Text("Logs are automatically cleared after 7 days")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.7))
            }
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(AppColors.cardBackground.opacity(0.5))
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: DesignSystem.Spacing.md, bottom: 0, trailing: DesignSystem.Spacing.md))
        .listRowSeparator(.hidden)
    }
}

struct StatBadge: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(value)")
                .font(AppTypography.heading3)
                .foregroundStyle(color)
            
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

// MARK: - No Logs View

struct NoLogsView: View {
    let selectedServerId: UUID?
    let onSelectServer: () -> Void
    let servers: [Server]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            
            Text(selectedServerId == nil ? "No Logs Available" : "No Logs for Selected Server")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Connect to servers to view activity logs")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
            
            if selectedServerId != nil {
                Button {
                    onSelectServer()
                } label: {
                    Text("Show All Logs")
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry
    let serverName: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 时间戳和级别
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 级别徽章
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: entry.level.icon)
                        .font(.system(size: 12))
                    
                    Text(entry.level.rawValue)
                        .font(AppTypography.labelSmall)
                }
                .foregroundStyle(entry.level.color)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 2)
                .background(entry.level.color.opacity(0.15))
                .cornerRadius(4)
                
                // 时间戳
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)
                
                Spacer()
                
                // 服务器名称
                if !serverName.isEmpty {
                    Text(serverName)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                }
            }
            
            // 日志消息
            Text(entry.message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)
            
            // 展开/收起按钮（仅长消息）
            if entry.message.count > 50 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .listRowBackground(AppColors.cardBackground)
        .listRowInsets(EdgeInsets(top: DesignSystem.Spacing.xs, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.xs, trailing: DesignSystem.Spacing.md))
        .listRowSeparator(.hidden)
    }
}

// MARK: - Log Storage Info Sheet

struct LogStorageInfoSheet: View {
    @StateObject private var logStore = LogStore.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingClearAllConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // 存储信息
                Section {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(AppColors.accent)
                        Text("Database Size")
                        Spacer()
                        Text(formatBytes(logStore.databaseSize))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(AppColors.secondaryAccent)
                        Text("Log Entries")
                        Spacer()
                        Text("\(logStore.totalLogs)")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(AppColors.warning)
                        Text("Estimated Log Size")
                        Spacer()
                        Text(logStore.sizeEstimate)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                } header: {
                    Text("Storage Information")
                }
                
                // 日志级别统计
                Section {
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        HStack {
                            Image(systemName: level.icon)
                                .foregroundStyle(level.color)
                            Text(level.rawValue)
                            Spacer()
                            Text("\(logStore.levelCounts[level] ?? 0)")
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                } header: {
                    Text("Log Level Statistics")
                }
                
                // 保留策略
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(AppColors.online)
                            Text("Automatic Cleanup")
                                .font(AppTypography.label)
                        }
                        
                        Text("Logs older than 7 days are automatically removed when the app starts. This helps prevent excessive storage usage.")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                } header: {
                    Text("Retention Policy")
                }
                
                // 清理操作
                Section {
                    Button {
                        showingClearAllConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear All Logs")
                        }
                        .foregroundStyle(AppColors.offline)
                    }
                } header: {
                    Text("Manual Cleanup")
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Log Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Clear All Logs?",
                isPresented: $showingClearAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    logStore.clearAllLogs()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(logStore.totalLogs) log entries.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024) KB"
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / 1024.0 / 1024.0)
        } else {
            return String(format: "%.1f GB", Double(bytes) / 1024.0 / 1024.0 / 1024.0)
        }
    }
}

// MARK: - Logs Empty State

struct LogsEmptyState: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            
            Text("No Activity Logs")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Add servers and connect to view activity logs")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    LogsView()
}
