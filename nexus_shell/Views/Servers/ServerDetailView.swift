//
//  ServerDetailView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// SSH 连接测试结果类型（本地使用）
enum SSHConnectionTestResult: Equatable {
    case success
    case failure(String)
}

/// 服务器详情视图
struct ServerDetailView: View {
    @ObservedObject var server: Server
    @Environment(\.dismiss) private var dismiss
    @StateObject private var serverStore = ServerStore.shared

    @State private var isEditing: Bool = false
    @State private var editedName: String = ""
    @State private var editedHost: String = ""
    @State private var editedPort: String = ""
    @State private var editedUsername: String = ""
    @State private var editedTags: String = ""
    @State private var editedNotes: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var connectionTestResult: SSHConnectionTestResult?
    @State private var showingConnectionDetail = false
    @State private var showingDeleteConfirmation = false
    @State private var showingTerminalSession = false
    @State private var activeSession: ServerSession?

    private var settings: AppSettings {
        AppSettings.shared
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // 服务器状态卡片
                ServerStatusHeader(server: server)
                
                // 详细信息
                if isEditing {
                    EditableInfoSection(
                        name: $editedName,
                        host: $editedHost,
                        port: $editedPort,
                        username: $editedUsername,
                        tags: $editedTags,
                        notes: $editedNotes,
                        authMethod: server.authMethod
                    )
                } else {
                    StaticInfoSection(server: server)
                }
                
                // 操作按钮
                ActionButtonsSection(
                    server: server,
                    isTesting: isTestingConnection,
                    testResult: connectionTestResult,
                    onConnect: { connectToServer() },
                    onTest: { testConnection() },
                    onShowDetail: { showingConnectionDetail = true }
                )
                
                // 删除按钮
                DeleteButtonSection(
                    serverName: server.name,
                    onDelete: { showingDeleteConfirmation = true }
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .navigationTitle(isEditing ? String(localized: "Edit Server") : server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if isEditing {
                        saveChanges()
                    } else {
                        startEditing()
                    }
                } label: {
                    Text(isEditing ? String(localized: "Save") : String(localized: "Edit Server"))
                        .fontWeight(isEditing ? .semibold : .regular)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                if isEditing {
                    Button(String(localized: "Cancel")) {
                        cancelEditing()
                    }
                }
            }
        }
        .sheet(isPresented: $showingConnectionDetail) {
            ConnectionDetailView(server: server)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTerminalSession) {
            if let session = activeSession {
                TerminalSessionSheet(session: session)
            }
        }
        .confirmationDialog(
            "Delete Server?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteServer()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(server.name)\"? This action cannot be undone and all credentials will be removed.")
        }
        .onAppear {
            loadEditingValues()
        }
    }

    private func loadEditingValues() {
        editedName = server.name
        editedHost = server.host
        editedPort = String(server.port)
        editedUsername = server.username
        editedTags = server.tags.joined(separator: ", ")
        editedNotes = server.notes ?? ""
    }

    private func startEditing() {
        loadEditingValues()
        isEditing = true
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func cancelEditing() {
        isEditing = false
        loadEditingValues()
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func saveChanges() {
        server.name = editedName
        server.host = editedHost
        server.port = Int(editedPort) ?? 22
        server.username = editedUsername
        server.tags = editedTags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        server.notes = editedNotes.isEmpty ? nil : editedNotes

        // 更新数据库
        serverStore.updateServer(server)

        isEditing = false
        if settings.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func deleteServer() {
        // 触觉反馈
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // 清理 Keychain 凭据
        KeychainHelper.shared.deleteAllForServer(server.id)
        
        // 从数据库删除服务器
        serverStore.deleteServer(server)
        
        // 记录删除日志
        let log = LogEntry(
            serverId: server.id,
            level: .info,
            message: "Server \"\(server.name)\" deleted"
        )
        LogStore.shared.addLog(log)
        
        // 关闭详情页面
        dismiss()
        
        // 成功反馈
        if settings.hapticFeedbackEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func connectToServer() {
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // 创建会话并连接
        let session = ServerSession(server: server)
        activeSession = session
        showingTerminalSession = true
        
        Task {
            await session.connect()
        }
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        Task {
            let result = await SSHClientManager.testConnection(
                host: server.host,
                port: server.port,
                username: server.username,
                authMethod: server.authMethod,
                serverId: server.id
            )

            await MainActor.run {
                isTestingConnection = false
                switch result {
                case .success:
                    connectionTestResult = .success
                    serverStore.updateServerStatus(server.id, status: .online, cpuUsage: server.cpuUsage, memoryUsage: server.memoryUsage)
                    if settings.hapticFeedbackEnabled {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                case .failure(let error):
                    connectionTestResult = .failure(error)
                    serverStore.updateServerStatus(server.id, status: .offline, cpuUsage: nil, memoryUsage: nil)
                    if settings.hapticFeedbackEnabled {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }
        }
    }
}

// MARK: - 服务器状态头部
struct ServerStatusHeader: View {
    @ObservedObject var server: Server

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                Circle()
                    .fill(statusColor.opacity(0.4))
                    .frame(width: 70, height: 70)

                Image(systemName: statusIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(statusColor)
            }

            // 状态文字
            Text(String(localized: String.LocalizationValue(server.status.localizedKey)))
                .font(AppTypography.heading2)
                .foregroundStyle(statusColor)

            // 主机地址
            Text(server.displayAddress)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.secondaryText)

            // 使用率指标
            if server.status == .online || server.status == .warning {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    if let cpu = server.cpuUsage {
                        MetricView(
                            title: String(localized: "CPU Usage"),
                            value: cpu,
                            color: usageColor(cpu)
                        )
                    }
                    if let memory = server.memoryUsage {
                        MetricView(
                            title: String(localized: "Memory Usage"),
                            value: memory,
                            color: usageColor(memory)
                        )
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.lg)
        .cardStyle(status: server.status, isGlowing: server.status != .unknown)
        .onAppear {
            isAnimating = server.status == .online
        }
        .onChange(of: server.status) { _, newStatus in
            isAnimating = newStatus == .online
        }
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
        case .unknown: return "questionmark.circle.fill"
        }
    }

    private func usageColor(_ value: Double) -> Color {
        if value < 50 { return AppColors.online }
        if value < 80 { return AppColors.warning }
        return AppColors.offline
    }
}

// MARK: - 指标视图
struct MetricView: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(Int(value))%")
                .font(AppTypography.heading3)
                .foregroundStyle(color)

            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

// MARK: - 静态信息区块
struct StaticInfoSection: View {
    @ObservedObject var server: Server

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 基本信息卡片
            VStack(spacing: 0) {
                SectionHeader(title: String(localized: "Basic Info"), icon: "server.rack")
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    InfoRow(label: String(localized: "Name"), value: server.name)
                    InfoRow(label: String(localized: "Host"), value: server.host)
                    InfoRow(label: String(localized: "Port"), value: String(server.port))
                    InfoRow(label: String(localized: "Username"), value: server.username)
                    InfoRow(
                        label: String(localized: "Authentication"),
                        value: server.authMethod == .password
                            ? String(localized: "Password")
                            : String(localized: "Private Key")
                    )
                }
                .padding(DesignSystem.Spacing.md)
            }
            .cardStyle()
            
            // 标签卡片
            if !server.tags.isEmpty {
                VStack(spacing: 0) {
                    SectionHeader(title: String(localized: "Tags"), icon: "tag")
                    
                    FlowLayout(spacing: DesignSystem.Spacing.sm) {
                        ForEach(server.tags, id: \.self) { tag in
                            TagChip(text: tag)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .cardStyle()
            }
            
            // 备注卡片
            if let notes = server.notes, !notes.isEmpty {
                VStack(spacing: 0) {
                    SectionHeader(title: String(localized: "Notes"), icon: "note.text")
                    
                    Text(notes)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DesignSystem.Spacing.md)
                }
                .cardStyle()
            }
            
            // 时间信息卡片
            VStack(spacing: 0) {
                SectionHeader(title: String(localized: "Timeline"), icon: "clock")
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    if let lastConnected = server.lastConnectedAt {
                        InfoRow(
                            label: String(localized: "Last Connected"),
                            value: lastConnected.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                    
                    InfoRow(
                        label: String(localized: "Created"),
                        value: server.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                .padding(DesignSystem.Spacing.md)
            }
            .cardStyle()
        }
    }
}

// MARK: - 分组标题
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.accent)
            
            Text(title)
                .font(AppTypography.label)
                .foregroundStyle(AppColors.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(AppColors.accent.opacity(0.1))
    }
}

// MARK: - 流式布局（用于标签）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        var totalHeight: CGFloat = 0
        for (index, row) in rows.enumerated() {
            totalHeight += row.maxHeight
            if index > 0 {
                totalHeight += spacing
            }
        }
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            for subview in row.subviews {
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += subview.sizeThatFits(.unspecified).width + spacing
            }
            y += row.maxHeight + spacing
        }
    }
    
    private func arrangeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRowSubviews: [LayoutSubview] = []
        var currentX: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && !currentRowSubviews.isEmpty {
                rows.append(Row(subviews: currentRowSubviews, maxHeight: currentRowSubviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0))
                currentRowSubviews = []
                currentX = 0
            }
            
            currentRowSubviews.append(subview)
            currentX += size.width + spacing
        }
        
        if !currentRowSubviews.isEmpty {
            rows.append(Row(subviews: currentRowSubviews, maxHeight: currentRowSubviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0))
        }
        
        return rows
    }
    
    struct Row {
        let subviews: [LayoutSubview]
        let maxHeight: CGFloat
    }
}

// MARK: - 标签芯片
struct TagChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(AppTypography.labelSmall)
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(AppColors.accent.opacity(0.15))
            .cornerRadius(DesignSystem.Radius.sm)
    }
}

// MARK: - 可编辑信息区块
struct EditableInfoSection: View {
    @Binding var name: String
    @Binding var host: String
    @Binding var port: String
    @Binding var username: String
    @Binding var tags: String
    @Binding var notes: String
    let authMethod: AuthMethod

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 基本信息编辑卡片
            VStack(spacing: 0) {
                SectionHeader(title: String(localized: "Basic Info"), icon: "server.rack")
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    EditableRow(label: String(localized: "Name"), value: $name)
                    EditableRow(label: String(localized: "Host"), value: $host)
                    EditableRow(label: String(localized: "Port"), value: $port)
                    EditableRow(label: String(localized: "Username"), value: $username)
                    
                    // 认证方式（不可编辑）
                    HStack {
                        Text(String(localized: "Authentication"))
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.secondaryText)
                        
                        Spacer()
                        
                        Text(authMethod == .password
                            ? String(localized: "Password")
                            : String(localized: "Private Key"))
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .cardStyle()
            
            // 标签编辑卡片
            VStack(spacing: 0) {
                SectionHeader(title: String(localized: "Tags"), icon: "tag")
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField(String(localized: "Enter tags separated by commas"), text: $tags)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                        .textFieldStyle(.plain)
                    
                    // 标签预览
                    if !tags.isEmpty {
                        let tagList = tags.split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        
                        if !tagList.isEmpty {
                            FlowLayout(spacing: DesignSystem.Spacing.sm) {
                                ForEach(tagList, id: \.self) { tag in
                                    TagChip(text: tag)
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .cardStyle()
            
            // 备注编辑卡片
            VStack(spacing: 0) {
                SectionHeader(title: String(localized: "Notes"), icon: "note.text")
                
                TextField(String(localized: "Enter notes"), text: $notes, axis: .vertical)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(3...10)
                    .padding(DesignSystem.Spacing.md)
            }
            .cardStyle()
        }
    }
}

// MARK: - 信息行
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)

            Spacer()

            Text(value)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.primaryText)
        }
    }
}

// MARK: - 可编辑行
struct EditableRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
            
            Spacer()
            
            TextField("", text: $value)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - 操作按钮区块
struct ActionButtonsSection: View {
    @ObservedObject var server: Server
    let isTesting: Bool
    let testResult: SSHConnectionTestResult?
    let onConnect: () -> Void
    let onTest: () -> Void
    let onShowDetail: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 连接按钮
            Button {
                onConnect()
            } label: {
                HStack {
                    Image(systemName: "terminal")
                    Text(String(localized: "Connect"))
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.primaryGradient)
                .cornerRadius(DesignSystem.Radius.md)
            }

            // 查看连接详情按钮
            Button {
                onShowDetail()
            } label: {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(String(localized: "Connection Details"))
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.secondaryAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.secondaryAccent.opacity(0.2))
                .cornerRadius(DesignSystem.Radius.md)
            }

            // 测试连接按钮
            Button {
                onTest()
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .tint(AppColors.accent)
                    } else {
                        Image(systemName: "wifi")
                    }

                    Text(String(localized: "Test Connection"))

                    if let result = testResult {
                        Spacer()
                        Image(systemName: result == SSHConnectionTestResult.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result == SSHConnectionTestResult.success ? AppColors.online : AppColors.offline)
                    }
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.accent.opacity(0.2))
                .cornerRadius(DesignSystem.Radius.md)
            }
            .disabled(isTesting)

            // 测试结果信息
            if let result = testResult {
                switch result {
                case .success:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.online)
                        Text(String(localized: "System Ready"))
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.online)
                    }
                case .failure(let message):
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.offline)
                        Text(message)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.offline)
                    }
                }
            }
        }
    }
}

// MARK: - 删除按钮区块
struct DeleteButtonSection: View {
    let serverName: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Divider()
                .background(AppColors.secondaryText.opacity(0.3))
            
            // 删除按钮
            Button {
                onDelete()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(String(localized: "Delete Server"))
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.offline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.offline.opacity(0.15))
                .cornerRadius(DesignSystem.Radius.md)
            }
            
            // 提示文字
            Text("This will permanently remove the server and all associated credentials.")
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
}

// MARK: - 终端会话 Sheet

struct TerminalSessionSheet: View {
    @ObservedObject var session: ServerSession
    @Environment(\.dismiss) private var dismiss
    @State private var commandInput: String = ""
    
    private var settings: AppSettings { AppSettings.shared }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 连接状态栏
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Circle()
                        .fill(session.state == .connected ? AppColors.online : AppColors.warning)
                        .frame(width: 8, height: 8)
                    
                    Text("\(session.server.username)@\(session.server.host)")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                    
                    Spacer()
                    
                    Text(session.state == .connected ? "Connected" : "Connecting...")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(session.state == .connected ? AppColors.online : AppColors.warning)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(AppColors.secondaryBackground.opacity(0.8))
                
                // 终端输出
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(session.outputBuffer)
                            .font(.system(size: CGFloat(settings.terminalFontSize), design: .monospaced))
                            .foregroundStyle(AppColors.primaryText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.sm)
                            .id("output")
                    }
                    .background(AppColors.secondaryBackground)
                    .onChange(of: session.outputBuffer) { _, _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo("output", anchor: .bottom)
                        }
                    }
                }
                
                // 命令输入
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("$")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AppColors.accent)
                    
                    TextField("输入命令...", text: $commandInput)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AppColors.primaryText)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .submitLabel(.go)
                        .onSubmit {
                            sendCommand()
                        }
                    
                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(commandInput.isEmpty ? AppColors.disabledText : AppColors.accent)
                    }
                    .disabled(commandInput.isEmpty)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(AppColors.cardBackground)
                
                // 工具栏
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button("ESC") { session.sendCommand("\u{001B}") }
                        .font(AppTypography.labelSmall)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppColors.cardBackground)
                        .cornerRadius(DesignSystem.Radius.sm)
                    
                    Button("TAB") { session.sendCommand("\t") }
                        .font(AppTypography.labelSmall)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppColors.cardBackground)
                        .cornerRadius(DesignSystem.Radius.sm)
                    
                    Button("CLR") { session.sendCommand("clear") }
                        .font(AppTypography.labelSmall)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppColors.cardBackground)
                        .cornerRadius(DesignSystem.Radius.sm)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(AppColors.secondaryBackground.opacity(0.6))
            }
            .navigationTitle(session.server.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        session.disconnect()
                        dismiss()
                    }
                    .foregroundStyle(AppColors.offline)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func sendCommand() {
        guard !commandInput.isEmpty else { return }
        session.sendCommand(commandInput)
        commandInput = ""
        
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#Preview {
    ServerDetailView(server: Server(
        name: "Test Server",
        host: "192.168.1.100",
        username: "admin"
    ))
}