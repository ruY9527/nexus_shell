import Foundation
import SwiftData

@Observable
final class TerminalViewModel {
    var buffer = TerminalBuffer()
    var currentInput: String = ""
    var commandHistoryIndex: Int = -1
    var isConnecting: Bool = false
    var isConnected: Bool = false
    var errorMessage: String?

    let server: Server
    private let sshService: SSHService
    private let keychainService: KeychainService
    private let historyService: CommandHistoryService?
    private var commandHistory: [String] = []
    private var startTime: Date?

    init(server: Server, modelContext: ModelContext? = nil) {
        self.server = server
        self.sshService = SSHService()
        self.keychainService = KeychainService.shared
        self.historyService = modelContext.map { CommandHistoryService(modelContext: $0) }
    }

    var sessionState: SessionState {
        sshService.state
    }

    var statusColor: String {
        switch sessionState {
        case .connected: return "#34C759"
        case .connecting, .reconnecting: return "#FF9500"
        case .error: return "#FF3B30"
        case .disconnected: return "#8E8E93"
        }
    }

    var statusText: String {
        sessionState.displayText
    }

    var recentCommands: [String] {
        if let historyService {
            return historyService.getUniqueCommands(for: server.id, limit: 50)
        }
        return commandHistory.reversed()
    }

    var quickCommands: [QuickCommand] {
        QuickCommand.defaultCommands
    }

    func connect() async {
        isConnecting = true
        errorMessage = nil

        do {
            var password: String?
            var privateKeyPath: String?

            if server.authMethod == .password {
                password = try keychainService.getPassword(for: server.id)
            } else {
                if let keyData = try keychainService.getPrivateKey(for: server.id) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(server.id.uuidString)_key")
                    try keyData.write(to: tempURL)
                    privateKeyPath = tempURL.path
                }
            }

            try await sshService.connect(to: server, password: password, privateKeyPath: privateKeyPath)
            isConnected = true

            buffer.appendOutput(String(localized: "Connected to \(server.displayAddress)\n", comment: "Terminal connection message"))
            buffer.appendOutput(String(localized: "Last login: \(Date().shortFormatted)\n\n", comment: "Terminal last login message"))

            try await startShell()
        } catch {
            errorMessage = error.localizedDescription
            buffer.appendOutput(String(localized: "Connection failed: \(error.localizedDescription)\n", comment: "Terminal error message"))
        }

        isConnecting = false
    }

    func disconnect() {
        sshService.disconnect()
        isConnected = false
        buffer.appendOutput(String(localized: "\nConnection closed.\n", comment: "Terminal disconnection message"))
    }

    func sendCommand(_ command: String) {
        guard !command.isEmpty else { return }

        currentInput = ""
        commandHistory.append(command)
        commandHistoryIndex = -1

        startTime = Date()
        saveToHistory(command: command)

        if command == "clear" {
            buffer.clear()
            sshService.sendInput(command + "\n")
            return
        }

        sshService.sendInput(command + "\n")
    }

    func sendSpecialKey(_ key: SpecialKey) {
        sshService.sendInput(key.rawValue)
    }

    func historyUp() {
        guard !commandHistory.isEmpty, commandHistoryIndex < commandHistory.count - 1 else { return }
        commandHistoryIndex += 1
        currentInput = commandHistory[commandHistory.count - 1 - commandHistoryIndex]
    }

    func historyDown() {
        guard commandHistoryIndex > 0 else {
            commandHistoryIndex = -1
            currentInput = ""
            return
        }
        commandHistoryIndex -= 1
        currentInput = commandHistory[commandHistory.count - 1 - commandHistoryIndex]
    }

    func resizeTerminal(width: Int, height: Int) {
        buffer.resize(columns: width, rows: height)
        sshService.resizeTerminal(width: width, height: height)
    }

    private func startShell() async throws {
        try await sshService.startShell { [weak self] output in
            Task { @MainActor in
                self?.buffer.appendOutput(output)
            }
        }
    }

    private func saveToHistory(command: String, output: String = "") {
        guard let historyService else { return }
        let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        historyService.saveCommand(command, serverId: server.id, output: output, duration: duration)
    }
}

enum SpecialKey: String, CaseIterable {
    case escape = "\u{1B}"
    case tab = "\t"
    case ctrlC = "\u{03}"
    case ctrlD = "\u{04}"
    case ctrlZ = "\u{1A}"
    case arrowUp = "\u{1B}[A"
    case arrowDown = "\u{1B}[B"
    case arrowRight = "\u{1B}[C"
    case arrowLeft = "\u{1B}[D"

    var displayName: String {
        switch self {
        case .escape: return String(localized: "ESC", comment: "Special key label")
        case .tab: return String(localized: "Tab", comment: "Special key label")
        case .ctrlC: return String(localized: "Ctrl+C", comment: "Special key label")
        case .ctrlD: return String(localized: "Ctrl+D", comment: "Special key label")
        case .ctrlZ: return String(localized: "Ctrl+Z", comment: "Special key label")
        case .arrowUp: return "↑"
        case .arrowDown: return "↓"
        case .arrowRight: return "→"
        case .arrowLeft: return "←"
        }
    }
}
