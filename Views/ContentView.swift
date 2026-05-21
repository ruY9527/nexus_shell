import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .servers
    @State private var isUnlocked: Bool = false
    @State private var showBiometric: Bool = false

    enum Tab: String, CaseIterable {
        case servers = "Servers"
        case terminal = "Terminal"
        case settings = "Settings"
    }

    var body: some View {
        Group {
            if isUnlocked {
                TabView(selection: $selectedTab) {
                    ServerListView()
                        .tabItem {
                            Label("Servers", systemImage: "server.rack")
                        }
                        .tag(Tab.servers)

                    TerminalPlaceholderView()
                        .tabItem {
                            Label("Terminal", systemImage: "terminal")
                        }
                        .tag(Tab.terminal)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(Tab.settings)
                }
                .tint(.accentColor)
            } else {
                LockScreenView(isUnlocked: $isUnlocked)
            }
        }
        .onAppear {
            checkBiometricLock()
        }
    }

    private func checkBiometricLock() {
        let biometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
        if biometricEnabled {
            showBiometric = true
            Task {
                do {
                    let success = try await BiometricService.shared.authenticate(reason: String(localized: "Unlock Nexus Shell"))
                    isUnlocked = success
                } catch {
                    isUnlocked = true
                }
            }
        } else {
            isUnlocked = true
        }
    }
}

struct LockScreenView: View {
    @Binding var isUnlocked: Bool
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Nexus Shell")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Authenticate to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    do {
                        let success = try await BiometricService.shared.authenticate(reason: String(localized: "Unlock Nexus Shell"))
                        isUnlocked = success
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                Label(String(localized: "Unlock with \(BiometricService.shared.biometricType.displayName)"), systemImage: "faceid")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            Button("Use Password") {
                isUnlocked = true
            }
            .font(.subheadline)
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
}

struct TerminalPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "terminal")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Select a server to start")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Go to Servers tab and tap on a server to open a terminal session")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Terminal")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Server.self, ServerGroup.self, CommandHistory.self, QuickCommand.self])
}
