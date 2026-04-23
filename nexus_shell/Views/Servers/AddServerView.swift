//
//  AddServerView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 添加服务器视图的连接测试结果
enum AddServerConnectionTestResult: Equatable {
    case success
    case failure(String)
}

/// 添加服务器视图
struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var serverStore = ServerStore.shared
    @StateObject private var folderStore = FolderStore.shared
    
    /// 初始文件夹ID（从文件夹页面添加时传入）
    let folderId: UUID?
    
    /// 根目录的特殊标识（固定UUID）
    private let rootFolderId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var authMethod: AuthMethod = .password
    @State private var password: String = ""
    @State private var privateKey: String = ""
    @State private var passphrase: String = ""
    @State private var tags: String = ""
    @State private var notes: String = ""
    @State private var selectedFolderId: UUID
    
    @State private var isTestingConnection = false
    @State private var connectionTestResult: AddServerConnectionTestResult?
    @State private var showingSaveConfirmation = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    init(folderId: UUID? = nil) {
        self.folderId = folderId
        // 初始化选中的文件夹：使用固定的根目录标识
        let rootId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        _selectedFolderId = State(initialValue: folderId ?? rootId)
    }
    
    var isValid: Bool {
        let hasBasicInfo = !name.isEmpty && !host.isEmpty && !username.isEmpty
        let hasPasswordAuth = authMethod == AuthMethod.password && !password.isEmpty
        let hasKeyAuth = authMethod == AuthMethod.privateKey && !privateKey.isEmpty
        return hasBasicInfo && (hasPasswordAuth || hasKeyAuth)
    }
    
    var selectedFolderName: String {
        if selectedFolderId != rootFolderId {
            if let folder = folderStore.getFolder(byId: selectedFolderId) {
                return folder.name
            }
        }
        return String(localized: "Root")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section {
                    TextField(String(localized: "Server Name"), text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addServer.name")
                    
                    TextField(String(localized: "Host"), text: $host)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addServer.host")
                    
                    TextField(String(localized: "Port"), text: $port)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("addServer.port")
                    
                    TextField(String(localized: "Username"), text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("addServer.username")
                    
                    // 文件夹选择
                    Picker(String(localized: "Folder"), selection: $selectedFolderId) {
                        // 根目录选项（使用固定的UUID）
                        Text("Root")
                            .tag(rootFolderId)
                        
                        // 文件夹选项
                        ForEach(folderStore.folders) { folder in
                            Label(folder.name, systemImage: folder.icon.systemName)
                                .tag(folder.id)
                        }
                    }
                } header: {
                    Text("Basic Information")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 认证方式
                Section {
                    Picker(String(localized: "Authentication"), selection: $authMethod) {
                        Text(String(localized: "Password")).tag(AuthMethod.password)
                        Text(String(localized: "Private Key")).tag(AuthMethod.privateKey)
                    }
                    .pickerStyle(.segmented)
                    
                    if authMethod == .password {
                        SecureField(String(localized: "Password"), text: $password)
                            .textContentType(.password)
                            .accessibilityIdentifier("addServer.password")
                        
                        // 密码强度指示器
                        PasswordStrengthIndicator(password: password)
                    } else {
                        // 私钥输入
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text(String(localized: "Private Key"))
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.secondaryText)
                            
                            TextEditor(text: $privateKey)
                                .font(AppTypography.terminalSmall)
                                .foregroundStyle(AppColors.primaryText)
                                .frame(minHeight: 100)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(DesignSystem.Spacing.sm)
                                .background(AppColors.cardBackground)
                                .cornerRadius(DesignSystem.Radius.sm)
                            
                            // 私钥密码短语（可选）
                            SecureField("Passphrase (optional)", text: $passphrase)
                        }
                    }
                } header: {
                    Text("Authentication")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 标签和备注
                Section {
                    TextField("Tags (comma separated)", text: $tags)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Additional Information")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 测试连接
                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .tint(AppColors.accent)
                            } else {
                                Image(systemName: "wifi")
                            }
                            
                            Text(String(localized: "Test Connection"))
                                .foregroundStyle(AppColors.accent)
                            
                            Spacer()
                            
                            if let result = connectionTestResult {
                                Image(systemName: result == AddServerConnectionTestResult.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result == AddServerConnectionTestResult.success ? AppColors.online : AppColors.offline)
                            }
                        }
                    }
                    .disabled(!isValid || isTestingConnection)
                    
                    if let result = connectionTestResult {
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
                    
                    // 快速填充按钮
                    Button {
                        quickFillSSHDefaults()
                    } label: {
                        Label("Quick Fill: SSH Defaults", systemImage: "wand.and.stars")
                            .foregroundStyle(AppColors.secondaryAccent)
                    }
                } header: {
                    Text("Connection Test")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(String(localized: "Add Server"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveServer()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("addServer.save")
                }
            }
            .alert("Save Server?", isPresented: $showingSaveConfirmation) {
                Button(String(localized: "Cancel"), role: .cancel) {}
                Button(String(localized: "Save")) {
                    performSave()
                }
            } message: {
                Text("Would you like to save this server configuration?")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // 临时保存凭据用于测试
        let tempServerId = UUID()
        
        if authMethod == .password {
            _ = KeychainHelper.shared.savePassword(password, for: tempServerId)
        } else {
            _ = KeychainHelper.shared.savePrivateKey(privateKey, for: tempServerId)
            if !passphrase.isEmpty {
                _ = KeychainHelper.shared.savePassphrase(passphrase, for: tempServerId)
            }
        }
        
        Task {
            let result = await SSHClientManager.testConnection(
                host: host,
                port: Int(port) ?? 22,
                username: username,
                authMethod: authMethod,
                serverId: tempServerId
            )
            
            // 清理临时凭据
            KeychainHelper.shared.deleteAllForServer(tempServerId)
            
            await MainActor.run {
                isTestingConnection = false
                
                switch result {
                case .success:
                    connectionTestResult = AddServerConnectionTestResult.success
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .failure(let error):
                    connectionTestResult = AddServerConnectionTestResult.failure(error)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func quickFillSSHDefaults() {
        if port.isEmpty {
            port = "22"
        }
        if username.isEmpty {
            username = "root"
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func saveServer() {
        showingSaveConfirmation = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func performSave() {
        let tagArray = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 判断是否为根目录（使用固定的rootFolderId判断）
        let actualFolderId: UUID? = {
            if selectedFolderId == rootFolderId {
                return nil  // 根目录
            }
            return selectedFolderId
        }()
        
        let server = Server(
            folderId: actualFolderId,
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authMethod: authMethod,
            tags: tagArray,
            notes: notes.isEmpty ? nil : notes
        )
        
        // 保存凭据到 Keychain
        if authMethod == .password {
            let success = KeychainHelper.shared.savePassword(password, for: server.id)
            if !success {
                errorMessage = "Failed to save password to secure storage"
                showingError = true
                return
            }
        } else {
            let success = KeychainHelper.shared.savePrivateKey(privateKey, for: server.id)
            if !success {
                errorMessage = "Failed to save private key to secure storage"
                showingError = true
                return
            }
            if !passphrase.isEmpty {
                _ = KeychainHelper.shared.savePassphrase(passphrase, for: server.id)
            }
        }
        
        // 如果测试成功，设置初始状态
        if connectionTestResult == AddServerConnectionTestResult.success {
            server.status = .online
        }
        
        // 保存服务器到数据库
        serverStore.addServer(server)
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String
    
    var strength: PasswordStrength {
        guard !password.isEmpty else { return .none }
        
        let length = password.count
        let hasUppercase = password.contains(where: { $0.isUppercase })
        let hasLowercase = password.contains(where: { $0.isLowercase })
        let hasDigit = password.contains(where: { $0.isNumber })
        let hasSpecial = password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
        
        var score = 0
        if length >= 8 { score += 1 }
        if length >= 12 { score += 1 }
        if hasUppercase { score += 1 }
        if hasLowercase { score += 1 }
        if hasDigit { score += 1 }
        if hasSpecial { score += 1 }
        
        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        case 5...6: return .strong
        default: return .none
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Text("Strength:")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)
                
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Rectangle()
                            .fill(strengthColor(for: index))
                            .frame(width: 20, height: 4)
                            .cornerRadius(2)
                    }
                }
                
                Text(strengthText)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(strength.color)
            }
        }
    }
    
    private func strengthColor(for index: Int) -> Color {
        switch strength {
        case .none:
            return AppColors.disabledText.opacity(0.3)
        case .weak:
            return index == 0 ? AppColors.offline : AppColors.disabledText.opacity(0.3)
        case .medium:
            return index < 2 ? AppColors.warning : AppColors.disabledText.opacity(0.3)
        case .strong:
            return strength.color
        }
    }
    
    private var strengthText: String {
        switch strength {
        case .none: return ""
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

enum PasswordStrength {
    case none, weak, medium, strong
    
    var color: Color {
        switch self {
        case .none: return AppColors.disabledText
        case .weak: return AppColors.offline
        case .medium: return AppColors.warning
        case .strong: return AppColors.online
        }
    }
}

#Preview {
    AddServerView()
}
