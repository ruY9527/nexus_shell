import Foundation
import SwiftData

@Observable
final class SettingsViewModel {
    var biometricEnabled: Bool = false
    var biometricType: BiometricType = .none
    var autoLockTimeout: TimeInterval = 300
    var defaultPort: String = "22"
    var sshConnectionTimeout: TimeInterval = 10
    var sshCommandTimeout: TimeInterval = 30
    var terminalFontSize: Double = 14
    var terminalFontName: String = "Menlo"
    var colorScheme: ColorSchemeOption = .system
    var hapticFeedback: Bool = true
    var quickCommands: [QuickCommand] = []
    var language: LanguageOption = .system

    private var modelContext: ModelContext

    enum LanguageOption: String, CaseIterable {
        case system = "System"
        case en = "en"
        case zhHans = "zh-Hans"

        var displayName: String {
            switch self {
            case .system: return String(localized: "System", comment: "Language option")
            case .en: return "English"
            case .zhHans: return "简体中文"
            }
        }

        var localeIdentifier: String? {
            switch self {
            case .system: return nil
            case .en: return "en"
            case .zhHans: return "zh-Hans"
            }
        }
    }

    enum ColorSchemeOption: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var displayName: String {
            switch self {
            case .system: return String(localized: "System", comment: "Color scheme option")
            case .light: return String(localized: "Light", comment: "Color scheme option")
            case .dark: return String(localized: "Dark", comment: "Color scheme option")
            }
        }
    }

    @MainActor
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.biometricType = BiometricService.shared.biometricType
        loadSettings()
    }

    func loadSettings() {
        let defaults = UserDefaults.standard

        // Register defaults for keys that should have non-zero initial values
        defaults.register(defaults: [
            "haptic_feedback": true,
            "auto_lock_timeout": 300.0,
            "ssh_connection_timeout": 10.0,
            "ssh_command_timeout": 30.0,
            "terminal_font_size": 14.0
        ])

        biometricEnabled = defaults.bool(forKey: "biometric_enabled")
        autoLockTimeout = defaults.double(forKey: "auto_lock_timeout")
        defaultPort = defaults.string(forKey: "default_port") ?? "22"
        sshConnectionTimeout = defaults.double(forKey: "ssh_connection_timeout")
        sshCommandTimeout = defaults.double(forKey: "ssh_command_timeout")
        terminalFontSize = defaults.double(forKey: "terminal_font_size")
        terminalFontName = defaults.string(forKey: "terminal_font_name") ?? "Menlo"
        colorScheme = ColorSchemeOption(rawValue: defaults.string(forKey: "color_scheme") ?? "System") ?? .system
        hapticFeedback = defaults.bool(forKey: "haptic_feedback")
        language = LanguageOption(rawValue: defaults.string(forKey: "app_language") ?? "System") ?? .system

        let descriptor = FetchDescriptor<QuickCommand>(sortBy: [SortDescriptor(\.sortOrder)])
        quickCommands = (try? modelContext.fetch(descriptor)) ?? []

        if quickCommands.isEmpty {
            QuickCommand.defaultCommands.forEach { modelContext.insert($0) }
            quickCommands = QuickCommand.defaultCommands
            try? modelContext.save()
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(biometricEnabled, forKey: "biometric_enabled")
        defaults.set(autoLockTimeout, forKey: "auto_lock_timeout")
        defaults.set(defaultPort, forKey: "default_port")
        defaults.set(sshConnectionTimeout, forKey: "ssh_connection_timeout")
        defaults.set(sshCommandTimeout, forKey: "ssh_command_timeout")
        defaults.set(terminalFontSize, forKey: "terminal_font_size")
        defaults.set(terminalFontName, forKey: "terminal_font_name")
        defaults.set(colorScheme.rawValue, forKey: "color_scheme")
        defaults.set(hapticFeedback, forKey: "haptic_feedback")
        defaults.set(language.rawValue, forKey: "app_language")
    }

    func toggleBiometric() async {
        if biometricEnabled {
            do {
                let success = try await BiometricService.shared.authenticate(reason: String(localized: "Enable biometric lock for Nexus Shell", comment: "Biometric toggle reason"))
                biometricEnabled = success
            } catch {
                biometricEnabled = false
            }
        }
        saveSettings()
    }

    func addQuickCommand(_ command: QuickCommand) {
        modelContext.insert(command)
        quickCommands.append(command)
        try? modelContext.save()
    }

    func deleteQuickCommand(_ command: QuickCommand) {
        modelContext.delete(command)
        quickCommands.removeAll { $0.id == command.id }
        try? modelContext.save()
    }

    func resetToDefaults() {
        let defaults = UserDefaults.standard
        let keys = ["biometric_enabled", "auto_lock_timeout", "default_port",
                     "ssh_connection_timeout", "ssh_command_timeout",
                     "terminal_font_size", "terminal_font_name",
                     "color_scheme", "haptic_feedback", "app_language"]
        keys.forEach { defaults.removeObject(forKey: $0) }
        loadSettings()
    }

    func clearAllHistory() {
        try? modelContext.delete(model: CommandHistory.self)
        try? modelContext.save()
    }
}
