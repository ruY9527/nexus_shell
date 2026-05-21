import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var showClearHistory: Bool = false
    @State private var showResetDefaults: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    List {
                        Section("Security") {
                            if viewModel.biometricType != .none {
                                Toggle(isOn: Binding(
                                    get: { viewModel.biometricEnabled },
                                    set: { _ in Task { await viewModel.toggleBiometric() } }
                                )) {
                                    Label(String(localized: "Lock with \(viewModel.biometricType.displayName)", comment: "Toggle label"), systemImage: "lock.fill")
                                }
                            }

                            VStack(alignment: .leading) {
                                Text("Auto-lock timeout")
                                    .font(.body)
                                Picker("", selection: Binding(
                                    get: { viewModel.autoLockTimeout },
                                    set: { viewModel.autoLockTimeout = $0; viewModel.saveSettings() }
                                )) {
                                    Text("1 minute").tag(TimeInterval(60))
                                    Text("5 minutes").tag(TimeInterval(300))
                                    Text("15 minutes").tag(TimeInterval(900))
                                    Text("Never").tag(TimeInterval(0))
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        Section("SSH") {
                            HStack {
                                Text("Default Port")
                                Spacer()
                                TextField("22", text: Binding(
                                    get: { viewModel.defaultPort },
                                    set: { viewModel.defaultPort = $0; viewModel.saveSettings() }
                                ))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            }

                            VStack(alignment: .leading) {
                                Text(String(localized: "Connection Timeout: \(Int(viewModel.sshConnectionTimeout))s", comment: "Settings label"))
                                Slider(
                                    value: Binding(
                                        get: { viewModel.sshConnectionTimeout },
                                        set: { viewModel.sshConnectionTimeout = $0; viewModel.saveSettings() }
                                    ),
                                    in: 5...60,
                                    step: 5
                                )
                            }

                            VStack(alignment: .leading) {
                                Text(String(localized: "Command Timeout: \(Int(viewModel.sshCommandTimeout))s", comment: "Settings label"))
                                Slider(
                                    value: Binding(
                                        get: { viewModel.sshCommandTimeout },
                                        set: { viewModel.sshCommandTimeout = $0; viewModel.saveSettings() }
                                    ),
                                    in: 10...120,
                                    step: 10
                                )
                            }
                        }

                        Section("Terminal") {
                            VStack(alignment: .leading) {
                                Text(String(localized: "Font Size: \(Int(viewModel.terminalFontSize))", comment: "Settings label"))
                                Slider(
                                    value: Binding(
                                        get: { viewModel.terminalFontSize },
                                        set: { viewModel.terminalFontSize = $0; viewModel.saveSettings() }
                                    ),
                                    in: 10...24,
                                    step: 1
                                )
                            }

                            Picker("Font", selection: Binding(
                                get: { viewModel.terminalFontName },
                                set: { viewModel.terminalFontName = $0; viewModel.saveSettings() }
                            )) {
                                Text("Menlo").tag("Menlo")
                                Text("SF Mono").tag("SF Mono")
                                Text("Courier").tag("Courier")
                                Text("Monaco").tag("Monaco")
                            }

                            Toggle(isOn: Binding(
                                get: { viewModel.hapticFeedback },
                                set: { viewModel.hapticFeedback = $0; viewModel.saveSettings() }
                            )) {
                                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                            }
                        }

                        Section("Appearance") {
                            Picker("Language", selection: Binding(
                                get: { viewModel.language },
                                set: { viewModel.language = $0; viewModel.saveSettings() }
                            )) {
                                ForEach(SettingsViewModel.LanguageOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }

                            Picker("Color Scheme", selection: Binding(
                                get: { viewModel.colorScheme },
                                set: { viewModel.colorScheme = $0; viewModel.saveSettings() }
                            )) {
                                ForEach(SettingsViewModel.ColorSchemeOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                        }

                        Section("Quick Commands") {
                            ForEach(viewModel.quickCommands) { command in
                                HStack {
                                    Image(systemName: command.icon)
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading) {
                                        Text(command.name)
                                        Text(command.command)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onDelete { offsets in
                                offsets.forEach { viewModel.deleteQuickCommand(viewModel.quickCommands[$0]) }
                            }

                            NavigationLink("Add Quick Command") {
                                AddQuickCommandView(viewModel: viewModel)
                            }
                        }

                        Section("Data") {
                            Button {
                                showClearHistory = true
                            } label: {
                                Label("Clear Command History", systemImage: "trash")
                                    .foregroundStyle(.red)
                            }

                            Button {
                                showResetDefaults = true
                            } label: {
                                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                                    .foregroundStyle(.red)
                            }
                        }

                        Section("About") {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("Build")
                                Spacer()
                                Text("1")
                                    .foregroundStyle(.secondary)
                            }

                            Link(destination: URL(string: "https://github.com/nexusshell")!) {
                                Label("GitHub", systemImage: "link")
                            }
                        }
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Settings")
            .alert("Clear History?", isPresented: $showClearHistory) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel?.clearAllHistory()
                }
            } message: {
                Text("This will permanently delete all command history.")
            }
            .alert("Reset Settings?", isPresented: $showResetDefaults) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel?.resetToDefaults()
                }
            } message: {
                Text("This will reset all settings to their default values.")
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

struct AddQuickCommandView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: SettingsViewModel

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var icon: String = "terminal.fill"
    @State private var category: String = "General"

    let icons = ["terminal.fill", "bolt.fill", "folder.fill", "doc.text.fill",
                 "info.circle.fill", "server.rack", "shippingbox.fill", "network"]

    var body: some View {
        Form {
            Section("Command") {
                TextField("Name", text: $name)
                TextField("Command", text: $command)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(self.icon == icon ? Color.blue.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { self.icon = icon }
                    }
                }
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    Text("General").tag("General")
                    Text("System").tag("System")
                    Text("Network").tag("Network")
                    Text("Docker").tag("Docker")
                    Text("Files").tag("Files")
                    Text("Custom").tag("Custom")
                }
            }
        }
        .navigationTitle("Add Quick Command")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let cmd = QuickCommand(
                        name: name,
                        command: command,
                        icon: icon,
                        category: category,
                        sortOrder: viewModel.quickCommands.count
                    )
                    viewModel.addQuickCommand(cmd)
                    dismiss()
                }
                .disabled(name.isEmpty || command.isEmpty)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Server.self, ServerGroup.self, CommandHistory.self, QuickCommand.self])
}
