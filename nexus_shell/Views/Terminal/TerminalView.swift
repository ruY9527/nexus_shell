//
//  TerminalView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI
import UIKit

/// 终端视图
struct TerminalView: View {
    @StateObject private var serverStore = ServerStore.shared
    @StateObject private var completionEngine = CompletionEngine.shared
    @State private var showingServerPicker = false
    @State private var commandInput: String = ""
    @State private var showingQuickCommands = false
    @State private var showingFileBrowser = false
    @State private var showingBookmarkQuickPanel = false
    @State private var inputFieldId: UUID = UUID()  // 用于重建输入框
    @State private var currentDirectory: String = "/home"
    @FocusState private var isInputFocused: Bool  // 用于控制键盘焦点

    private var settings: AppSettings { AppSettings.shared }

    private var activeSession: ServerSession? {
        serverStore.activeSession
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let session = activeSession {
                    // 连接状态栏
                    ConnectionStatusBar(session: session)

                    // 终端内容区域
                    TerminalOutputView(session: session, fontSize: settings.terminalFontSize)

                    // 快捷命令面板
                    if showingQuickCommands {
                        QuickCommandsPanel(onCommand: { cmd in executeCommand(cmd) })
                    }

                    // 命令输入区域 - 使用 UIKit TextField 确保键盘升起
                    CommandInputBarUIKit(
                        prompt: "\(session.server.username)@\(session.server.host):~$",
                        text: $commandInput,
                        id: inputFieldId,
                        isEnabled: session.state == .connected,
                        isFocused: isInputFocused,
                        onTextChange: { text in
                            commandInput = text
                            completionEngine.getCompletions(
                                for: text,
                                cursorPosition: nil,
                                currentDirectory: currentDirectory
                            )
                        },
                        onSubmit: executeCommand,
                        onTabPressed: {
                            if let completion = completionEngine.handleTab() {
                                commandInput = completion.text
                            }
                        },
                        onEscapePressed: {
                            completionEngine.hideCompletions()
                        },
                        onUpPressed: {
                            if completionEngine.isShowingCompletions {
                                completionEngine.selectPrevious()
                            } else {
                                sendKeyToSession("\u{001B}[A")
                            }
                        },
                        onDownPressed: {
                            if completionEngine.isShowingCompletions {
                                completionEngine.selectNext()
                            } else {
                                sendKeyToSession("\u{001B}[B")
                            }
                        }
                    )

                    // 自动补全弹窗
                    if completionEngine.isShowingCompletions {
                        CompletionPopupView(
                            completions: completionEngine.currentCompletions,
                            selectedIndex: $completionEngine.selectedIndex,
                            onSelect: { item in
                                if let completion = completionEngine.applyCompletion(at: completionEngine.selectedIndex) {
                                    commandInput = completion.text
                                }
                            },
                            onDismiss: {
                                completionEngine.hideCompletions()
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // 书签快速访问面板
                    if showingBookmarkQuickPanel {
                        BookmarkQuickPanel(
                            onExecute: { bookmark in
                                executeCommand(bookmark.command)
                            },
                            onDismiss: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingBookmarkQuickPanel = false
                                }
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // 工具栏
                    TerminalToolbarView(
                        showingQuickCommands: $showingQuickCommands,
                        onKeyPressed: { key in sendKeyToSession(key) }
                    )
                } else {
                    // 未连接状态 - 去掉了 Quick Connect
                    TerminalEmptyState(
                        servers: serverStore.allServers,
                        onSelectServer: { showingServerPicker = true }
                    )
                }
            }
            .navigationTitle(String(localized: "Terminal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(serverStore.allServers) { server in
                            Button {
                                connectToServer(server)
                            } label: {
                                Label(server.name, systemImage: server.status == .online ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    } label: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(activeSession != nil ? AppColors.accent : AppColors.secondaryText)
                    }
                }
                
                if activeSession != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            #if canImport(NMSSH)
                            Button {
                                showingFileBrowser = true
                            } label: {
                                Image(systemName: "folder")
                                    .foregroundStyle(AppColors.accent)
                            }
                            .accessibilityIdentifier("terminal.fileBrowser")
                            #endif

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingQuickCommands.toggle()
                                }
                            } label: {
                                Image(systemName: showingQuickCommands ? "keyboard.chevron.compact.down" : "command")
                                    .foregroundStyle(AppColors.accent)
                            }
                            .accessibilityIdentifier("terminal.quickCommands")

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingBookmarkQuickPanel.toggle()
                                }
                            } label: {
                                Image(systemName: showingBookmarkQuickPanel ? "bookmark.fill" : "bookmark")
                                    .foregroundStyle(showingBookmarkQuickPanel ? AppColors.accent : AppColors.primaryText)
                            }
                            .accessibilityIdentifier("terminal.bookmarkQuickPanel")
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Disconnect")) {
                            disconnect()
                        }
                        .foregroundStyle(AppColors.offline)
                    }
                }
            }
            .sheet(isPresented: $showingServerPicker) {
                ServerPickerSheet(servers: serverStore.allServers, onSelect: connectToServer)
            }
            #if canImport(NMSSH)
            .sheet(isPresented: $showingFileBrowser) {
                if let session = activeSession, let connection = session.sshConnection {
                    FileBrowserView(sshConnection: connection)
                }
            }
            #endif
        }
        .background(AppColors.background)
    }
    
    // MARK: - Actions
    
    private func connectToServer(_ server: Server) {
        let session = ServerSession(server: server)
        serverStore.activeSession = session
        
        Task {
            await session.connect()
            await MainActor.run {
                if session.state == .connected {
                    // 连接成功后，重建输入框并触发键盘
                    inputFieldId = UUID()
                    isInputFocused = true
                }
            }
        }
        
        showingServerPicker = false
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func disconnect() {
        serverStore.activeSession?.disconnect()
        serverStore.activeSession = nil
        commandInput = ""
        showingQuickCommands = false
        
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func executeCommand(_ cmd: String) {
        guard let session = activeSession, !cmd.isEmpty else { return }
        session.sendCommand(cmd)
        
        if settings.hapticFeedbackEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func sendKeyToSession(_ key: String) {
        guard let session = activeSession else { return }
        session.sendCommand(key)
    }
}

// MARK: - UIKit 命令输入栏（确保键盘升起）

struct CommandInputBarUIKit: UIViewRepresentable {
    let prompt: String
    @Binding var text: String
    let id: UUID
    let isEnabled: Bool
    var isFocused: Bool = false  // 新增：控制焦点
    let onTextChange: (String) -> Void
    let onSubmit: (String) -> Void
    let onTabPressed: () -> Void
    let onEscapePressed: () -> Void
    let onUpPressed: () -> Void
    let onDownPressed: () -> Void

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(AppColors.cardBackground)

        // 提示符标签
        let promptLabel = UILabel()
        promptLabel.text = prompt
        promptLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        promptLabel.textColor = UIColor(AppColors.accent)
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(promptLabel)

        // 输入框 - 使用 UITextField
        let textField = UITextField()
        textField.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textField.textColor = UIColor(AppColors.primaryText)
        textField.placeholder = "输入命令..."
        textField.accessibilityIdentifier = "terminal.commandInput"
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        textField.returnKeyType = .go
        textField.delegate = context.coordinator
        textField.tag = 100  // 用于查找
        textField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textField)

        // 发送按钮
        let sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = UIColor(AppColors.accent)
        sendButton.accessibilityIdentifier = "terminal.sendCommand"
        sendButton.addTarget(context.coordinator, action: #selector(Coordinator.sendPressed), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(sendButton)

        // 布局约束
        NSLayoutConstraint.activate([
            promptLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            promptLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: promptLabel.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),

            container.heightAnchor.constraint(equalToConstant: 44)
        ])

        // 保存 textField 引用
        context.coordinator.textField = textField

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onTextChange = onTextChange
        context.coordinator.onTabPressed = onTabPressed
        context.coordinator.onEscapePressed = onEscapePressed
        context.coordinator.onUpPressed = onUpPressed
        context.coordinator.onDownPressed = onDownPressed

        // 更新文本
        if let textField = uiView.viewWithTag(100) as? UITextField {
            if textField.text != text {
                textField.text = text
            }

            textField.isEnabled = isEnabled
            textField.placeholder = isEnabled ? "输入命令..." : "等待连接..."

            // id 变化时强制获取焦点并弹出键盘
            if context.coordinator.currentId != id {
                context.coordinator.currentId = id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if self.isEnabled {
                        textField.becomeFirstResponder()
                    }
                }
            }

            // isFocused 变化时弹出键盘
            if isFocused && !textField.isFirstResponder && isEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if self.isEnabled {
                        textField.becomeFirstResponder()
                    }
                }
            }

            if !isEnabled && textField.isFirstResponder {
                textField.resignFirstResponder()
            }
        }

        if let sendButton = uiView.subviews.compactMap({ $0 as? UIButton }).first {
            sendButton.isEnabled = isEnabled
            sendButton.alpha = isEnabled ? 1.0 : 0.35
        }

        // 更新提示符
        for subview in uiView.subviews {
            if let label = subview as? UILabel {
                label.text = prompt
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onTextChange: onTextChange, onTabPressed: onTabPressed, onEscapePressed: onEscapePressed, onUpPressed: onUpPressed, onDownPressed: onDownPressed)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onSubmit: (String) -> Void
        var onTextChange: (String) -> Void
        var onTabPressed: () -> Void
        var onEscapePressed: () -> Void
        var onUpPressed: () -> Void
        var onDownPressed: () -> Void

        var textField: UITextField?
        var currentId: UUID?

        init(text: Binding<String>, onSubmit: @escaping (String) -> Void, onTextChange: @escaping (String) -> Void, onTabPressed: @escaping () -> Void, onEscapePressed: @escaping () -> Void, onUpPressed: @escaping () -> Void, onDownPressed: @escaping () -> Void) {
            self._text = text
            self.onSubmit = onSubmit
            self.onTextChange = onTextChange
            self.onTabPressed = onTabPressed
            self.onEscapePressed = onEscapePressed
            self.onUpPressed = onUpPressed
            self.onDownPressed = onDownPressed
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if newText != text {
                text = newText
                onTextChange(newText)
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            submit(textField)
            return true
        }

        @objc func sendPressed() {
            if let textField {
                submit(textField)
            }
        }

        // 允许始终编辑
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            return true
        }

        private func submit(_ textField: UITextField) {
            let command = textField.text ?? ""
            guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            onSubmit(command)
            text = ""
            textField.text = ""
            textField.becomeFirstResponder()
        }
    }
}

// MARK: - 连接状态栏

struct ConnectionStatusBar: View {
    @ObservedObject var session: ServerSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("\(session.server.username)@\(session.server.host)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                Text(statusText)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            if case .reconnecting(let attempt, let maxAttempts) = session.state {
                ReconnectingProgressBar(attempt: attempt, maxAttempts: maxAttempts)
            }
        }
        .background(AppColors.secondaryBackground.opacity(0.8))
        .accessibilityIdentifier("terminal.connectionStatus")
    }

    private var statusText: String {
        switch session.state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .reconnecting(let attempt, let maxAttempts):
            return "Reconnecting (\(attempt)/\(maxAttempts))..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var statusColor: Color {
        switch session.state {
        case .connected:
            return AppColors.online
        case .connecting, .reconnecting:
            return AppColors.warning
        case .disconnected, .error:
            return AppColors.offline
        }
    }
}

// MARK: - 终端输出视图

struct TerminalOutputView: View {
    @ObservedObject var session: ServerSession
    let fontSize: Int
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(session.outputBuffer)
                    .font(.system(size: CGFloat(fontSize), design: .monospaced))
                    .foregroundStyle(AppColors.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignSystem.Spacing.sm)
                    .id("output")
            }
            .background(AppColors.secondaryBackground)
            .accessibilityIdentifier("terminal.output")
            .onChange(of: session.outputBuffer) { _, _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo("output", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - 终端工具栏

struct TerminalToolbarView: View {
    @Binding var showingQuickCommands: Bool
    let onKeyPressed: (String) -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingQuickCommands.toggle()
                }
            } label: {
                Text("CMD")
                    .font(AppTypography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(showingQuickCommands ? AppColors.accent : AppColors.primaryText)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(AppColors.cardBackground)
                    .cornerRadius(DesignSystem.Radius.sm)
            }
            .accessibilityIdentifier("terminal.quickCommandsToolbar")

            ToolbarKeyButton(title: "ESC") { onKeyPressed("\u{001B}") }
            ToolbarKeyButton(title: "TAB") { onKeyPressed("\t") }
            ToolbarKeyButton(icon: "arrow.up") { onKeyPressed("\u{001B}[A") }
            ToolbarKeyButton(icon: "arrow.down") { onKeyPressed("\u{001B}[B") }
            ToolbarKeyButton(icon: "arrow.left") { onKeyPressed("\u{001B}[D") }
            ToolbarKeyButton(icon: "arrow.right") { onKeyPressed("\u{001B}[C") }
            
            Spacer()
            
            ToolbarKeyButton(title: "CLR") { onKeyPressed("clear") }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(AppColors.secondaryBackground.opacity(0.6))
    }
}

struct ToolbarKeyButton: View {
    var title: String? = nil
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Group {
                if let title = title {
                    Text(title)
                        .font(AppTypography.labelSmall)
                        .fontWeight(.medium)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(AppColors.cardBackground)
            .cornerRadius(DesignSystem.Radius.sm)
        }
        .accessibilityIdentifier(title.map { "terminal.key.\($0)" } ?? "terminal.key.icon")
    }
}

// MARK: - 快捷命令面板

struct QuickCommandsPanel: View {
    let onCommand: (String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                QuickCmdGroup(title: "系统", commands: [
                    ("uname -a", "系统信息"),
                    ("hostname", "主机名"),
                    ("uptime", "运行时间"),
                    ("date", "日期时间")
                ], onCommand: onCommand)
                
                QuickCmdGroup(title: "资源", commands: [
                    ("free -h", "内存"),
                    ("df -h", "磁盘"),
                    ("top -bn1", "进程"),
                    ("ps aux", "进程列表")
                ], onCommand: onCommand)
                
                QuickCmdGroup(title: "网络", commands: [
                    ("ifconfig", "网络接口"),
                    ("ip addr", "IP地址"),
                    ("netstat -tuln", "端口"),
                    ("ping -c 4 localhost", "Ping")
                ], onCommand: onCommand)
                
                QuickCmdGroup(title: "文件", commands: [
                    ("ls -la", "列表"),
                    ("pwd", "当前目录"),
                    ("whoami", "当前用户"),
                    ("cat /etc/os-release", "系统版本")
                ], onCommand: onCommand)
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .frame(maxHeight: 250)
        .background(AppColors.secondaryBackground)
    }
}

struct QuickCmdGroup: View {
    let title: String
    let commands: [(String, String)]
    let onCommand: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.accent)
            
            ForEach(commands, id: \.0) { cmd, label in
                Button {
                    onCommand(cmd)
                } label: {
                    HStack {
                        Text(label)
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.cardBackground)
                    .cornerRadius(4)
                }
                .accessibilityIdentifier("terminal.quickCommand.\(cmd)")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
            }
        }
    }
}

// MARK: - 空状态（去掉 Quick Connect）

struct TerminalEmptyState: View {
    let servers: [Server]
    let onSelectServer: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            
            Text("No Active Session")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("Select a server to start SSH session")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
            
            if !servers.isEmpty {
                Button { onSelectServer() } label: {
                    Text("Select Server")
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.primaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(AppColors.primaryGradient)
                        .cornerRadius(DesignSystem.Radius.md)
                }
                .accessibilityIdentifier("terminal.selectServer")
            } else {
                Text("Add servers first in Servers tab")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - 服务器选择器

struct ServerPickerSheet: View {
    let servers: [Server]
    let onSelect: (Server) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(servers) { server in
                    Button {
                        onSelect(server)
                        dismiss()
                    } label: {
                        HStack {
                            Circle()
                                .fill(server.status == .online ? AppColors.online : AppColors.offline)
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading) {
                                Text(server.name)
                                    .font(AppTypography.label)
                                    .foregroundStyle(AppColors.primaryText)
                                Text(server.displayAddress)
                                    .font(AppTypography.labelSmall)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                        }
                    }
                    .listRowBackground(AppColors.cardBackground)
                    .accessibilityIdentifier("terminal.server.\(server.name)")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Select Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TerminalView()
}
