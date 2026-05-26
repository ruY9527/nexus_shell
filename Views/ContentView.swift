import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .servers
    @State private var isUnlocked: Bool = false
    @State private var showBiometric: Bool = false
    @State private var backgroundTime: Date?

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
        .onChange(of: scenePhase) { _, newPhase in
            let biometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
            guard biometricEnabled else { return }

            if newPhase == .background {
                backgroundTime = Date()
            } else if newPhase == .active {
                let timeout = UserDefaults.standard.double(forKey: "auto_lock_timeout")
                if timeout == 0 { return } // "Never" selected

                if let backgroundTime {
                    let elapsed = Date().timeIntervalSince(backgroundTime)
                    if elapsed >= timeout {
                        isUnlocked = false
                        checkBiometricLock()
                    }
                }
                backgroundTime = nil
            }
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
    @Environment(\.modelContext) private var modelContext
    @State private var recentServers: [Server] = []

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

                if !recentServers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Connections")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(recentServers) { server in
                            NavigationLink {
                                TerminalView(server: server)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: server.color))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Image(systemName: "server.rack")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                        }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(server.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(server.displayAddress)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Terminal")
            .onAppear { loadRecentServers() }
        }
    }

    private func loadRecentServers() {
        let descriptor = FetchDescriptor<Server>(
            predicate: #Predicate { $0.lastConnected != nil },
            sortBy: [SortDescriptor(\.lastConnected, order: .reverse)]
        )
        recentServers = (try? modelContext.fetch(descriptor).prefix(5).map { $0 }) ?? []
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Server.self, ServerGroup.self, CommandHistory.self, QuickCommand.self])
}
