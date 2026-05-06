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

                // SSH 连接设置
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Connection Timeout")
                                .foregroundStyle(AppColors.primaryText)
                            Text("Timeout for establishing SSH connection")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Spacer()
                        Text("\(Int(settings.defaultSSHConfig.connectionTimeout))s")
                            .foregroundStyle(AppColors.secondaryText)
                        Stepper("", value: Binding(
                            get: { Int(settings.defaultSSHConfig.connectionTimeout) },
                            set: { newValue in
                                var config = settings.defaultSSHConfig
                                config.connectionTimeout = TimeInterval(newValue)
                                settings.updateSSHConfig(config)
                            }
                        ), in: 5...60)
                            .labelsHidden()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Auto Reconnect")
                                .foregroundStyle(AppColors.primaryText)
                            Text("Automatically reconnect on connection loss")
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.defaultSSHConfig.autoReconnect },
                            set: { newValue in
                                var config = settings.defaultSSHConfig
                                config.autoReconnect = newValue
                                settings.updateSSHConfig(config)
                            }
                        ))
                        .labelsHidden()
                        .tint(AppColors.accent)
                    }

                    if settings.defaultSSHConfig.autoReconnect {
                        HStack {
                            Text("Max Reconnect Attempts")
                                .foregroundStyle(AppColors.primaryText)
                            Spacer()
                            Text("\(settings.defaultSSHConfig.maxReconnectAttempts)")
                                .foregroundStyle(AppColors.secondaryText)
                            Stepper("", value: Binding(
                                get: { settings.defaultSSHConfig.maxReconnectAttempts },
                                set: { newValue in
                                    var config = settings.defaultSSHConfig
                                    config.maxReconnectAttempts = newValue
                                    settings.updateSSHConfig(config)
                                }
                            ), in: 1...10)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text("SSH Connection")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                } footer: {
                    Text("Auto mode tries real SSH first, falls back to simulated commands on failure.")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
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

                    HStack {
                        Text("Author")
                            .foregroundStyle(AppColors.primaryText)

                        Spacer()

                        Text("baobaoyang")
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Link(destination: URL(string: "https://github.com/ruY9527/nexus_shell")!) {
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
}

#Preview {
    SettingsView()
}