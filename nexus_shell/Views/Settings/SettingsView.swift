//
//  SettingsView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsObserver.shared
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 外观设置
                Section {
                    Picker(String(localized: "Appearance"), selection: $settings.colorSchemeString) {
                        Text("Dark (Recommended)").tag("dark")
                        Text("Light").tag("light")
                        Text("System").tag("system")
                    }
                    .onChange(of: settings.colorSchemeString) { _, newValue in
                        settings.setColorScheme(newValue)
                    }
                    
                    Picker(String(localized: "Language"), selection: $settings.language) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("中文").tag("zh-Hans")
                    }
                    .onChange(of: settings.language) { _, newValue in
                        AppSettings.shared.language = newValue
                    }
                    
                    HStack {
                        Text("Terminal Font Size")
                            .foregroundStyle(AppColors.primaryText)
                        
                        Spacer()
                        
                        Text("\(settings.terminalFontSize)")
                            .foregroundStyle(AppColors.secondaryText)
                        
                        Stepper("", value: $settings.terminalFontSize, in: 10...24)
                            .labelsHidden()
                            .onChange(of: settings.terminalFontSize) { _, newValue in
                                AppSettings.shared.terminalFontSize = newValue
                            }
                    }
                } header: {
                    Text(String(localized: "Appearance"))
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 安全设置
                Section {
                    if AppSettings.shared.supportsBiometric {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(AppSettings.shared.biometricType.displayName)
                                    .foregroundStyle(AppColors.primaryText)
                                
                                Text("Require authentication to open the app")
                                    .font(AppTypography.bodySmall)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.biometricLockEnabled)
                                .labelsHidden()
                                .tint(AppColors.accent)
                                .onChange(of: settings.biometricLockEnabled) { _, newValue in
                                    AppSettings.shared.biometricLockEnabled = newValue
                                }
                        }
                    } else {
                        HStack {
                            Text("Biometric Lock")
                                .foregroundStyle(AppColors.secondaryText)
                            
                            Spacer()
                            
                            Text("Not Available")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.disabledText)
                        }
                    }
                } header: {
                    Text("Security")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                } footer: {
                    if AppSettings.shared.supportsBiometric {
                        Text("When enabled, \(AppSettings.shared.biometricType.displayName) will be required each time you open the app.")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                
                // 交互设置
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(String(localized: "Haptic Feedback"))
                                .foregroundStyle(AppColors.primaryText)
                            
                            Text("Vibration feedback for actions")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settings.hapticFeedbackEnabled)
                            .labelsHidden()
                            .tint(AppColors.accent)
                            .onChange(of: settings.hapticFeedbackEnabled) { _, newValue in
                                AppSettings.shared.hapticFeedbackEnabled = newValue
                            }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Auto Refresh")
                                .foregroundStyle(AppColors.primaryText)
                            
                            Text("Automatically refresh server status")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settings.autoRefreshEnabled)
                            .labelsHidden()
                            .tint(AppColors.accent)
                            .onChange(of: settings.autoRefreshEnabled) { _, newValue in
                                AppSettings.shared.autoRefreshEnabled = newValue
                            }
                    }
                    
                    if settings.autoRefreshEnabled {
                        HStack {
                            Text("Refresh Interval")
                                .foregroundStyle(AppColors.primaryText)
                            
                            Spacer()
                            
                            Text("\(settings.refreshInterval) sec")
                                .foregroundStyle(AppColors.secondaryText)
                            
                            Stepper("", value: $settings.refreshInterval, in: 3...30)
                                .labelsHidden()
                                .onChange(of: settings.refreshInterval) { _, newValue in
                                    AppSettings.shared.refreshInterval = newValue
                                }
                        }
                    }
                } header: {
                    Text("Interaction")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 测试
                Section {
                    Button {
                        testHapticFeedback()
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap")
                            Text("Test Haptic Feedback")
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                    .disabled(!settings.hapticFeedbackEnabled)
                    
                    if AppSettings.shared.supportsBiometric {
                        Button {
                            testBiometricAuth()
                        } label: {
                            HStack {
                                Image(systemName: AppSettings.shared.biometricType.icon)
                                Text("Test \(AppSettings.shared.biometricType.displayName)")
                            }
                            .foregroundStyle(AppColors.secondaryAccent)
                        }
                    }
                } header: {
                    Text("Testing")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 数据管理
                Section {
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle")
                            Text("Reset All Settings")
                        }
                        .foregroundStyle(AppColors.offline)
                    }
                } header: {
                    Text("Data Management")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                } footer: {
                    Text("This will reset all settings to their default values. Your servers and connection data will not be affected.")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 关于
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(AppColors.primaryText)
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    HStack {
                        Text("Build")
                            .foregroundStyle(AppColors.primaryText)
                        
                        Spacer()
                        
                        Text("2026.04.22")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub Repository")
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                } header: {
                    Text("About")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Reset All Settings?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    AppSettings.shared.resetAllSettings()
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text("All settings will be restored to their default values.")
            }
        }
        // 使用动态颜色方案
        .preferredColorScheme(settings.colorScheme)
    }
    
    private func testHapticFeedback() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func testBiometricAuth() {
        Task {
            _ = await AppSettings.shared.authenticateWithBiometric()
        }
    }
}

#Preview {
    SettingsView()
}