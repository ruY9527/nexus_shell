import SwiftUI
import SwiftData

@main
struct NexusShellApp: App {
    @AppStorage("color_scheme") private var colorScheme: String = "System"
    @AppStorage("app_language") private var appLanguage: String = "System"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(appLanguage)
                .preferredColorScheme(resolvedColorScheme)
                .environment(\.locale, resolvedLocale)
        }
        .modelContainer(for: [
            Server.self,
            ServerGroup.self,
            CommandHistory.self,
            QuickCommand.self
        ])
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorScheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    private var resolvedLocale: Locale {
        switch appLanguage {
        case "en": return Locale(identifier: "en")
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        default: return Locale.current
        }
    }
}
