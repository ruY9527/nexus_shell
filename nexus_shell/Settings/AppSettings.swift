//
//  AppSettings.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// 应用设置管理类
/// 使用 UserDefaults 存储
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let autoRefreshEnabled = "autoRefreshEnabled"
        static let refreshInterval = "refreshInterval"
        static let terminalFontSize = "terminalFontSize"
        static let colorScheme = "colorScheme"
        static let language = "language"
        static let sshMode = "sshMode"
        static let defaultSSHConfig = "defaultSSHConfig"
    }

    /// SSH 连接模式
    enum SSHModes: String, CaseIterable, Codable {
        case real = "real"

        var displayName: String {
            return "Real SSH"
        }

        var description: String {
            return "Use real SSH connection"
        }
    }

    private let defaults = UserDefaults.standard

    // MARK: - Settings

    var hapticFeedbackEnabled: Bool {
        get { defaults.bool(forKey: Keys.hapticFeedbackEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.hapticFeedbackEnabled)
            notifyChange()
        }
    }

    var autoRefreshEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoRefreshEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.autoRefreshEnabled)
            notifyChange()
        }
    }

    var refreshInterval: Int {
        get {
            let value = defaults.integer(forKey: Keys.refreshInterval)
            return value == 0 ? 5 : value
        }
        set {
            defaults.set(newValue, forKey: Keys.refreshInterval)
            notifyChange()
        }
    }

    var terminalFontSize: Int {
        get {
            let value = defaults.integer(forKey: Keys.terminalFontSize)
            return value == 0 ? 14 : value
        }
        set {
            defaults.set(newValue, forKey: Keys.terminalFontSize)
            notifyChange()
        }
    }

    var colorSchemeString: String {
        get { defaults.string(forKey: Keys.colorScheme) ?? "dark" }
        set {
            defaults.set(newValue, forKey: Keys.colorScheme)
            notifyChange()
        }
    }

    /// 获取 SwiftUI ColorScheme
    var preferredColorScheme: ColorScheme? {
        switch colorSchemeString {
        case "dark":
            return .dark
        case "light":
            return .light
        case "system":
            return nil  // nil 表示跟随系统
        default:
            return .dark
        }
    }

    var language: String {
        get { defaults.string(forKey: Keys.language) ?? "system" }
        set {
            defaults.set(newValue, forKey: Keys.language)
            notifyChange()
        }
    }

    /// SSH 连接模式
    var sshMode: SSHModes {
        get {
            guard let value = defaults.string(forKey: Keys.sshMode),
                  let mode = SSHModes(rawValue: value) else {
                return .real
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.sshMode)
            notifyChange()
        }
    }

    /// 默认 SSH 配置（JSON 编码的 SSHConfig）
    var defaultSSHConfig: SSHConfig {
        get {
            guard let data = defaults.data(forKey: Keys.defaultSSHConfig),
                  let config = try? JSONDecoder().decode(SSHConfig.self, from: data) else {
                return .default
            }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.defaultSSHConfig)
            }
            notifyChange()
        }
    }

    // MARK: - Initialization

    private init() {
        // 设置首次启动的默认值
        if defaults.object(forKey: Keys.hapticFeedbackEnabled) == nil {
            defaults.set(true, forKey: Keys.hapticFeedbackEnabled)
        }
        if defaults.object(forKey: Keys.autoRefreshEnabled) == nil {
            defaults.set(true, forKey: Keys.autoRefreshEnabled)
        }
        if defaults.object(forKey: Keys.refreshInterval) == nil {
            defaults.set(5, forKey: Keys.refreshInterval)
        }
        if defaults.object(forKey: Keys.terminalFontSize) == nil {
            defaults.set(14, forKey: Keys.terminalFontSize)
        }
        if defaults.object(forKey: Keys.colorScheme) == nil {
            defaults.set("dark", forKey: Keys.colorScheme)
        }
        if defaults.object(forKey: Keys.language) == nil {
            defaults.set("system", forKey: Keys.language)
        }
        if defaults.object(forKey: Keys.sshMode) == nil {
            defaults.set(SSHModes.real.rawValue, forKey: Keys.sshMode)
        }
    }

    private func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    // MARK: - Reset

    func resetAllSettings() {
        defaults.set(true, forKey: Keys.hapticFeedbackEnabled)
        defaults.set(true, forKey: Keys.autoRefreshEnabled)
        defaults.set(5, forKey: Keys.refreshInterval)
        defaults.set(14, forKey: Keys.terminalFontSize)
        defaults.set("dark", forKey: Keys.colorScheme)
        defaults.set("system", forKey: Keys.language)
        defaults.set(SSHModes.real.rawValue, forKey: Keys.sshMode)
        defaults.removeObject(forKey: Keys.defaultSSHConfig)

        notifyChange()

        if hapticFeedbackEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Settings Observable Object

/// 用于 SwiftUI 视图监听设置变化
@MainActor
class SettingsObserver: ObservableObject {
    static let shared = SettingsObserver()

    @Published var colorScheme: ColorScheme?
    @Published var hapticFeedbackEnabled: Bool
    @Published var autoRefreshEnabled: Bool
    @Published var refreshInterval: Int
    @Published var terminalFontSize: Int
    @Published var colorSchemeString: String
    @Published var language: String
    @Published var sshMode: AppSettings.SSHModes
    @Published var defaultSSHConfig: SSHConfig

    private init() {
        colorScheme = AppSettings.shared.preferredColorScheme
        hapticFeedbackEnabled = AppSettings.shared.hapticFeedbackEnabled
        autoRefreshEnabled = AppSettings.shared.autoRefreshEnabled
        refreshInterval = AppSettings.shared.refreshInterval
        terminalFontSize = AppSettings.shared.terminalFontSize
        colorSchemeString = AppSettings.shared.colorSchemeString
        language = AppSettings.shared.language
        sshMode = AppSettings.shared.sshMode
        defaultSSHConfig = AppSettings.shared.defaultSSHConfig

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsChanged,
            object: nil
        )
    }

    @objc private func settingsDidChange() {
        colorScheme = AppSettings.shared.preferredColorScheme
        hapticFeedbackEnabled = AppSettings.shared.hapticFeedbackEnabled
        autoRefreshEnabled = AppSettings.shared.autoRefreshEnabled
        refreshInterval = AppSettings.shared.refreshInterval
        terminalFontSize = AppSettings.shared.terminalFontSize
        colorSchemeString = AppSettings.shared.colorSchemeString
        language = AppSettings.shared.language
        sshMode = AppSettings.shared.sshMode
        defaultSSHConfig = AppSettings.shared.defaultSSHConfig
    }

    func setColorScheme(_ value: String) {
        AppSettings.shared.colorSchemeString = value
    }

    func updateSSHConfig(_ config: SSHConfig) {
        AppSettings.shared.defaultSSHConfig = config
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let settingsChanged = Notification.Name("AppSettingsChanged")
}