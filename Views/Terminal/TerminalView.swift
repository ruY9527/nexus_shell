import SwiftUI
import SwiftData

struct TerminalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TerminalViewModel
    @State private var showQuickCommands: Bool = false
    @State private var showCommandHistory: Bool = false
    @State private var fontSize: Double = 14
    @State private var fontName: String = "Menlo"

    let server: Server

    private var terminalFont: Font {
        if fontName == "SF Mono" {
            return .system(size: fontSize, design: .monospaced)
        }
        return .custom(fontName, size: fontSize)
    }

    init(server: Server) {
        self.server = server
        _viewModel = State(initialValue: TerminalViewModel(server: server))
    }

    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusBar(viewModel: viewModel)

            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.buffer.fullAttributedString)
                            .font(terminalFont)
                            .textSelection(.enabled)
                            .lineSpacing(0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .id("terminal-bottom")
                    }
                    .onChange(of: viewModel.buffer.lineCount) {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("terminal-bottom", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    let cols = Int(geometry.size.width / (fontSize * 0.6))
                    let rows = Int(geometry.size.height / (fontSize * 1.4))
                    viewModel.resizeTerminal(width: max(cols, 40), height: max(rows, 10))
                }
                .onChange(of: geometry.size) {
                    let cols = Int(geometry.size.width / (fontSize * 0.6))
                    let rows = Int(geometry.size.height / (fontSize * 1.4))
                    viewModel.resizeTerminal(width: max(cols, 40), height: max(rows, 10))
                }
            }
            .background(Color(.systemBackground))

            TerminalToolbar(viewModel: viewModel)
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showQuickCommands = true
                    } label: {
                        Label("Quick Commands", systemImage: "bolt.fill")
                    }

                    Button {
                        showCommandHistory = true
                    } label: {
                        Label("Command History", systemImage: "clock.fill")
                    }

                    Divider()

                    Button {
                        fontSize = max(10, fontSize - 1)
                        UserDefaults.standard.set(fontSize, forKey: "terminal_font_size")
                    } label: {
                        Label("Decrease Font", systemImage: "textformat.size.smaller")
                    }

                    Button {
                        fontSize = min(24, fontSize + 1)
                        UserDefaults.standard.set(fontSize, forKey: "terminal_font_size")
                    } label: {
                        Label("Increase Font", systemImage: "textformat.size.larger")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.disconnect()
                        dismiss()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showQuickCommands) {
            QuickCommandsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCommandHistory) {
            CommandHistorySheet(viewModel: viewModel)
        }
        .onAppear {
            let defaults = UserDefaults.standard
            let savedFontSize = defaults.double(forKey: "terminal_font_size")
            if savedFontSize > 0 { fontSize = savedFontSize }
            fontName = defaults.string(forKey: "terminal_font_name") ?? "Menlo"

            viewModel = TerminalViewModel(server: server, modelContext: modelContext)
            Task { await viewModel.connect() }
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}

struct ConnectionStatusBar: View {
    let viewModel: TerminalViewModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: viewModel.statusColor))
                .frame(width: 8, height: 8)

            Text(viewModel.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(server.displayAddress)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }

    private var server: Server {
        viewModel.server
    }
}

struct QuickCommandsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TerminalViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.quickCommands) { command in
                    Button {
                        HapticManager.selection()
                        viewModel.sendCommand(command.command)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: command.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading) {
                                Text(command.name)
                                    .font(.body)
                                Text(command.command)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Quick Commands", comment: "Sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", comment: "Cancel button")) { dismiss() }
                }
            }
        }
    }
}

struct CommandHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TerminalViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recentCommands, id: \.self) { command in
                    Button {
                        HapticManager.selection()
                        viewModel.sendCommand(command)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text(command)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
            .navigationTitle(Text("Command History", comment: "Sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", comment: "Cancel button")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TerminalView(server: .preview)
    }
    .modelContainer(for: [Server.self, ServerGroup.self, CommandHistory.self, QuickCommand.self])
}
