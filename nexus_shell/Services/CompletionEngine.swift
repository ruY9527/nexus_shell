//
//  CompletionEngine.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  命令自动补全引擎
//

import Foundation
import Combine

// MARK: - Completion Types

/// 补全项
struct CompletionItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let text: String
    let displayText: String
    let description: String?
    let icon: String?
    let score: Int
    let source: CompletionSource

    init(
        id: UUID = UUID(),
        text: String,
        displayText: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        score: Int = 0,
        source: CompletionSource
    ) {
        self.id = id
        self.text = text
        self.displayText = displayText ?? text
        self.description = description
        self.icon = icon
        self.score = score
        self.source = source
    }

    static func == (lhs: CompletionItem, rhs: CompletionItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 补全来源
enum CompletionSource: String, CaseIterable {
    case builtIn = "Built-in"
    case history = "History"
    case path = "Path"
    case argument = "Argument"

    var icon: String {
        switch self {
        case .builtIn: return "terminal"
        case .history: return "clock.arrow.circlepath"
        case .path: return "folder.fill"
        case .argument: return "text.alignleft"
        }
    }

    var color: String {
        switch self {
        case .builtIn: return "accent"
        case .history: return "warning"
        case .path: return "online"
        case .argument: return "secondaryText"
        }
    }
}

/// 补全上下文
struct CompletionContext {
    let input: String
    let cursorPosition: Int
    let currentWord: String
    let precedingWord: String?
    let isAtStartOfLine: Bool
    let currentDirectory: String

    init(
        input: String,
        cursorPosition: Int,
        currentWord: String,
        precedingWord: String? = nil,
        isAtStartOfLine: Bool? = nil,
        currentDirectory: String = "/home"
    ) {
        self.input = input
        self.cursorPosition = cursorPosition
        self.currentWord = currentWord
        self.precedingWord = precedingWord
        self.isAtStartOfLine = isAtStartOfLine ?? (cursorPosition == 0)
        self.currentDirectory = currentDirectory
    }
}

// MARK: - Completion Provider Protocol

/// 补全提供者协议
protocol CompletionProvider {
    func provideCompletions(for context: CompletionContext) -> [CompletionItem]
    func priority() -> Int
}

// MARK: - Built-in Command Provider

/// 内置命令补全提供者
final class BuiltInCompletionProvider: CompletionProvider {
    static let shared = BuiltInCompletionProvider()

    private init() {}

    func priority() -> Int { 100 }

    func provideCompletions(for context: CompletionContext) -> [CompletionItem] {
        let input = context.currentWord.lowercased()
        guard !input.isEmpty else { return [] }

        return builtInCommands
            .filter { cmd in
                cmd.name.lowercased().hasPrefix(input) ||
                cmd.aliases.contains { $0.lowercased().hasPrefix(input) }
            }
            .sorted { $0.name.count < $1.name.count }
            .prefix(8)
            .map { cmd in
                CompletionItem(
                    text: cmd.name,
                    displayText: cmd.name,
                    description: cmd.description,
                    icon: iconForCategory(cmd.category),
                    score: 100 + cmd.name.count,
                    source: .builtIn
                )
            }
    }

    private func iconForCategory(_ category: CommandCategory) -> String {
        switch category {
        case .fileSystem: return "folder"
        case .systemInfo: return "info.circle"
        case .resource: return "chart.bar"
        case .process: return "cpu"
        case .network: return "network"
        case .docker: return "shippingbox"
        case .service: return "gearshape"
        case .user: return "person"
        case .package: return "square.and.arrow.down"
        case .compression: return "archivebox"
        case .ssh: return "lock.shield"
        case .utility: return "wrench"
        case .textProcessing: return "text.alignleft"
        case .encoding: return "number"
        case .log: return "doc.text"
        }
    }
}

// MARK: - Built-in Commands Data

/// 命令类别
enum CommandCategory: String, CaseIterable {
    case fileSystem = "File System"
    case systemInfo = "System Info"
    case resource = "Resources"
    case process = "Processes"
    case network = "Network"
    case docker = "Docker"
    case service = "Services"
    case user = "Users"
    case package = "Packages"
    case compression = "Compression"
    case ssh = "SSH/Transfer"
    case utility = "Utilities"
    case textProcessing = "Text Processing"
    case encoding = "Encoding"
    case log = "Logs"
}

/// 内置命令定义
struct BuiltInCommand {
    let name: String
    let aliases: [String]
    let category: CommandCategory
    let description: String
    let arguments: [String]?

    init(name: String, aliases: [String] = [], category: CommandCategory, description: String, arguments: [String]? = nil) {
        self.name = name
        self.aliases = aliases
        self.category = category
        self.description = description
        self.arguments = arguments
    }
}

/// 内置命令列表
let builtInCommands: [BuiltInCommand] = [
    // File System
    BuiltInCommand(name: "ls", aliases: [], category: .fileSystem, description: "List directory contents", arguments: ["-l", "-la", "-lh", "-a", "-R"]),
    BuiltInCommand(name: "cd", aliases: [], category: .fileSystem, description: "Change directory"),
    BuiltInCommand(name: "pwd", aliases: [], category: .fileSystem, description: "Print working directory"),
    BuiltInCommand(name: "cat", aliases: [], category: .fileSystem, description: "Concatenate and display files"),
    BuiltInCommand(name: "touch", aliases: [], category: .fileSystem, description: "Create empty file"),
    BuiltInCommand(name: "mkdir", aliases: [], category: .fileSystem, description: "Make directories", arguments: ["-p"]),
    BuiltInCommand(name: "rm", aliases: [], category: .fileSystem, description: "Remove files", arguments: ["-r", "-f", "-rf"]),
    BuiltInCommand(name: "cp", aliases: [], category: .fileSystem, description: "Copy files", arguments: ["-r", "-f"]),
    BuiltInCommand(name: "mv", aliases: [], category: .fileSystem, description: "Move/rename files"),
    BuiltInCommand(name: "find", aliases: [], category: .fileSystem, description: "Search for files"),
    BuiltInCommand(name: "which", aliases: [], category: .fileSystem, description: "Locate a command"),
    BuiltInCommand(name: "stat", aliases: [], category: .fileSystem, description: "Display file status"),

    // System Info
    BuiltInCommand(name: "uname", aliases: [], category: .systemInfo, description: "Print system information", arguments: ["-a", "-r", "-m"]),
    BuiltInCommand(name: "hostname", aliases: [], category: .systemInfo, description: "Show/set hostname"),
    BuiltInCommand(name: "uptime", aliases: [], category: .systemInfo, description: "Show system uptime"),
    BuiltInCommand(name: "date", aliases: [], category: .systemInfo, description: "Display date and time"),
    BuiltInCommand(name: "whoami", aliases: [], category: .systemInfo, description: "Print current username"),
    BuiltInCommand(name: "id", aliases: [], category: .systemInfo, description: "Print user identity"),
    BuiltInCommand(name: "w", aliases: [], category: .systemInfo, description: "Show who is logged in"),
    BuiltInCommand(name: "who", aliases: [], category: .systemInfo, description: "Show who is logged in"),
    BuiltInCommand(name: "last", aliases: [], category: .systemInfo, description: "Show last logins"),
    BuiltInCommand(name: "lscpu", aliases: [], category: .systemInfo, description: "Display CPU information"),
    BuiltInCommand(name: "lsblk", aliases: [], category: .systemInfo, description: "List block devices"),
    BuiltInCommand(name: "lsmem", aliases: [], category: .systemInfo, description: "List memory devices"),

    // Resources
    BuiltInCommand(name: "free", aliases: [], category: .resource, description: "Display memory usage", arguments: ["-h", "-m", "-g"]),
    BuiltInCommand(name: "df", aliases: [], category: .resource, description: "Display disk usage", arguments: ["-h", "-m", "-T"]),
    BuiltInCommand(name: "du", aliases: [], category: .resource, description: "Estimate file usage", arguments: ["-h", "-sh"]),
    BuiltInCommand(name: "top", aliases: ["htop"], category: .resource, description: "Display processes", arguments: ["-bn1"]),
    BuiltInCommand(name: "vmstat", aliases: [], category: .resource, description: "Report virtual memory stats"),
    BuiltInCommand(name: "iostat", aliases: [], category: .resource, description: "Report CPU and I/O stats"),

    // Process
    BuiltInCommand(name: "ps", aliases: [], category: .process, description: "Report process status", arguments: ["aux", "ef"]),
    BuiltInCommand(name: "kill", aliases: [], category: .process, description: "Terminate process", arguments: ["-9", "-15"]),
    BuiltInCommand(name: "killall", aliases: [], category: .process, description: "Kill processes by name"),
    BuiltInCommand(name: "pgrep", aliases: [], category: .process, description: "Search for processes"),
    BuiltInCommand(name: "pkill", aliases: [], category: .process, description: "Kill processes by pattern"),
    BuiltInCommand(name: "pstree", aliases: [], category: .process, description: "Display process tree"),
    BuiltInCommand(name: "pidstat", aliases: [], category: .process, description: "Report process statistics"),

    // Network
    BuiltInCommand(name: "ifconfig", aliases: [], category: .network, description: "Configure network interface"),
    BuiltInCommand(name: "ip", aliases: [], category: .network, description: "Show/manipulate routing", arguments: ["addr", "route", "link"]),
    BuiltInCommand(name: "netstat", aliases: [], category: .network, description: "Network statistics", arguments: ["-tuln"]),
    BuiltInCommand(name: "ss", aliases: [], category: .network, description: "Socket statistics"),
    BuiltInCommand(name: "ping", aliases: [], category: .network, description: "Send ICMP echo", arguments: ["-c", "-i"]),
    BuiltInCommand(name: "traceroute", aliases: [], category: .network, description: "Trace route"),
    BuiltInCommand(name: "nslookup", aliases: [], category: .network, description: "DNS lookup"),
    BuiltInCommand(name: "dig", aliases: [], category: .network, description: "DNS lookup"),
    BuiltInCommand(name: "nmap", aliases: [], category: .network, description: "Network exploration"),
    BuiltInCommand(name: "curl", aliases: [], category: .network, description: "Transfer data"),
    BuiltInCommand(name: "wget", aliases: [], category: .network, description: "Download files"),

    // Docker
    BuiltInCommand(name: "docker", aliases: [], category: .docker, description: "Docker CLI", arguments: ["ps", "images", "logs", "exec", "stats", "compose"]),
    BuiltInCommand(name: "docker ps", aliases: ["docker container ls"], category: .docker, description: "List containers"),
    BuiltInCommand(name: "docker images", aliases: ["docker image ls"], category: .docker, description: "List images"),
    BuiltInCommand(name: "docker logs", aliases: [], category: .docker, description: "Fetch container logs", arguments: ["-f", "--tail"]),
    BuiltInCommand(name: "docker exec", aliases: [], category: .docker, description: "Execute command in container", arguments: ["-it"]),
    BuiltInCommand(name: "docker stats", aliases: [], category: .docker, description: "Container resource usage"),
    BuiltInCommand(name: "docker-compose", aliases: ["docker compose"], category: .docker, description: "Docker Compose CLI", arguments: ["up", "down", "ps", "logs"]),

    // Services
    BuiltInCommand(name: "systemctl", aliases: [], category: .service, description: "Control systemd", arguments: ["status", "start", "stop", "restart", "enable", "disable"]),
    BuiltInCommand(name: "service", aliases: [], category: .service, description: "Run a System V init script"),
    BuiltInCommand(name: "journalctl", aliases: [], category: .service, description: "Query systemd journal", arguments: ["-u", "-n", "-f"]),
    BuiltInCommand(name: "crontab", aliases: [], category: .service, description: "Schedule periodic jobs", arguments: ["-l", "-e"]),

    // User
    BuiltInCommand(name: "useradd", aliases: [], category: .user, description: "Create new user"),
    BuiltInCommand(name: "userdel", aliases: [], category: .user, description: "Delete user account"),
    BuiltInCommand(name: "usermod", aliases: [], category: .user, description: "Modify user account"),
    BuiltInCommand(name: "passwd", aliases: [], category: .user, description: "Change password"),
    BuiltInCommand(name: "groups", aliases: [], category: .user, description: "Print group names"),
    BuiltInCommand(name: "groupadd", aliases: [], category: .user, description: "Create new group"),
    BuiltInCommand(name: "lastlog", aliases: [], category: .user, description: "Show last login"),
    BuiltInCommand(name: "chage", aliases: [], category: .user, description: "Change user password expiry"),

    // Packages
    BuiltInCommand(name: "apt", aliases: ["apt-get"], category: .package, description: "Package manager", arguments: ["update", "upgrade", "install", "remove", "search"]),
    BuiltInCommand(name: "yum", aliases: [], category: .package, description: "Yellowdog Updater", arguments: ["install", "remove", "update", "list"]),
    BuiltInCommand(name: "dnf", aliases: [], category: .package, description: "Dandified YUM", arguments: ["install", "remove", "update", "list"]),
    BuiltInCommand(name: "dpkg", aliases: [], category: .package, description: "Debian package manager", arguments: ["-l", "-i"]),
    BuiltInCommand(name: "pip", aliases: [], category: .package, description: "Python package manager", arguments: ["install", "list", "show"]),
    BuiltInCommand(name: "npm", aliases: [], category: .package, description: "Node package manager", arguments: ["install", "list", "run"]),

    // Compression
    BuiltInCommand(name: "tar", aliases: [], category: .compression, description: "Archive utility", arguments: ["-cvf", "-xvf", "-tvf"]),
    BuiltInCommand(name: "gzip", aliases: ["gunzip"], category: .compression, description: "Compress/decompress files"),
    BuiltInCommand(name: "zip", aliases: ["unzip"], category: .compression, description: "Package and compress files"),
    BuiltInCommand(name: "bzip2", aliases: ["bunzip2"], category: .compression, description: "Block-sorting compressor"),
    BuiltInCommand(name: "xz", aliases: ["unxz"], category: .compression, description: "LZMA compressor"),

    // SSH/Transfer
    BuiltInCommand(name: "ssh", aliases: [], category: .ssh, description: "OpenSSH remote login"),
    BuiltInCommand(name: "scp", aliases: [], category: .ssh, description: "Secure copy"),
    BuiltInCommand(name: "sftp", aliases: [], category: .ssh, description: "Secure file transfer"),
    BuiltInCommand(name: "rsync", aliases: [], category: .ssh, description: "Fast file copying", arguments: ["-avz", "-e"]),
    BuiltInCommand(name: "ssh-keygen", aliases: [], category: .ssh, description: "SSH key generator"),
    BuiltInCommand(name: "ssh-copy-id", aliases: [], category: .ssh, description: "Copy SSH key to server"),

    // Utilities
    BuiltInCommand(name: "grep", aliases: [], category: .utility, description: "Search text patterns"),
    BuiltInCommand(name: "sed", aliases: [], category: .utility, description: "Stream editor"),
    BuiltInCommand(name: "awk", aliases: [], category: .utility, description: "Pattern scanning language"),
    BuiltInCommand(name: "cut", aliases: [], category: .utility, description: "Remove sections from lines"),
    BuiltInCommand(name: "sort", aliases: [], category: .utility, description: "Sort lines of text"),
    BuiltInCommand(name: "uniq", aliases: [], category: .utility, description: "Report/omit repeated lines"),
    BuiltInCommand(name: "wc", aliases: [], category: .utility, description: "Print word count"),
    BuiltInCommand(name: "head", aliases: [], category: .utility, description: "Output first lines", arguments: ["-n"]),
    BuiltInCommand(name: "tail", aliases: [], category: .utility, description: "Output last lines", arguments: ["-n", "-f"]),
    BuiltInCommand(name: "less", aliases: [], category: .utility, description: "Pager program"),
    BuiltInCommand(name: "more", aliases: [], category: .utility, description: "Pager program"),
    BuiltInCommand(name: "diff", aliases: [], category: .utility, description: "Compare files"),
    BuiltInCommand(name: "chmod", aliases: [], category: .utility, description: "Change permissions"),
    BuiltInCommand(name: "chown", aliases: [], category: .utility, description: "Change ownership"),
    BuiltInCommand(name: "ln", aliases: [], category: .utility, description: "Make links"),
    BuiltInCommand(name: "mount", aliases: [], category: .utility, description: "Mount filesystem"),
    BuiltInCommand(name: "umount", aliases: [], category: .utility, description: "Unmount filesystem"),

    // Encoding
    BuiltInCommand(name: "base64", aliases: [], category: .encoding, description: "Base64 encode/decode"),
    BuiltInCommand(name: "md5sum", aliases: [], category: .encoding, description: "Compute MD5 checksum"),
    BuiltInCommand(name: "sha256sum", aliases: [], category: .encoding, description: "Compute SHA256 checksum"),
    BuiltInCommand(name: "sha1sum", aliases: [], category: .encoding, description: "Compute SHA1 checksum"),
    BuiltInCommand(name: "cksum", aliases: [], category: .encoding, description: "Checksum and count bytes"),

    // Text Processing
    BuiltInCommand(name: "cat", aliases: [], category: .textProcessing, description: "Concatenate files"),
    BuiltInCommand(name: "tr", aliases: [], category: .textProcessing, description: "Translate characters"),
    BuiltInCommand(name: "rev", aliases: [], category: .textProcessing, description: "Reverse lines"),
    BuiltInCommand(name: "wc", aliases: [], category: .textProcessing, description: "Word count"),

    // Logs
    BuiltInCommand(name: "tail", aliases: [], category: .log, description: "Display last lines", arguments: ["-f", "-n"]),
    BuiltInCommand(name: "dmesg", aliases: [], category: .log, description: "Print kernel messages"),
    BuiltInCommand(name: "journalctl", aliases: [], category: .log, description: "Systemd journal", arguments: ["-u", "-f", "-n", "--since"]),

    // Shell Built-ins
    BuiltInCommand(name: "echo", aliases: [], category: .utility, description: "Print text"),
    BuiltInCommand(name: "export", aliases: [], category: .utility, description: "Set environment variable"),
    BuiltInCommand(name: "source", aliases: [".", "alias", "unalias", "history", "exit", "logout", "clear"], category: .utility, description: "Shell built-in commands"),
    BuiltInCommand(name: "help", aliases: ["--help"], category: .utility, description: "Show help"),
]

// MARK: - History Provider

/// 历史命令补全提供者
final class HistoryCompletionProvider: CompletionProvider {
    static let shared = HistoryCompletionProvider()

    private var historyStore: CommandHistoryStore

    private init() {
        self.historyStore = CommandHistoryStore.shared
    }

    func priority() -> Int { 90 }

    func provideCompletions(for context: CompletionContext) -> [CompletionItem] {
        let input = context.currentWord.lowercased()
        guard !input.isEmpty else { return [] }

        let history = historyStore.getRecentCommands()
        return history
            .filter { $0.lowercased().hasPrefix(input) }
            .prefix(5)
            .enumerated()
            .map { index, command in
                CompletionItem(
                    text: command,
                    displayText: command,
                    description: "History",
                    icon: "clock.arrow.circlepath",
                    score: 80 - index,
                    source: .history
                )
            }
    }
}

// MARK: - Path Provider

/// 路径补全提供者
final class PathCompletionProvider: CompletionProvider {
    static let shared = PathCompletionProvider()

    private init() {}

    func priority() -> Int { 70 }

    func provideCompletions(for context: CompletionContext) -> [CompletionItem] {
        let input = context.currentWord

        // 只有包含路径分隔符或 ~ 才进行路径补全
        guard input.contains("/") || input.hasPrefix("~") else { return [] }

        let fileManager = FileManager.default
        let currentDir = determineBaseDirectory(from: input, relativeTo: context.currentDirectory)
        let partialName = extractPartialName(from: input, baseDir: currentDir)

        // 安全检查：避免目录遍历
        guard !currentDir.contains("..") else { return [] }

        guard let contents = try? fileManager.contentsOfDirectory(atPath: currentDir) else {
            return []
        }

        return contents
            .filter { $0.lowercased().hasPrefix(partialName.lowercased()) }
            .sorted { first, second in
                // 目录优先
                let firstIsDir = isDirectory(at: currentDir + "/" + first)
                let secondIsDir = isDirectory(at: currentDir + "/" + second)
                if firstIsDir != secondIsDir { return firstIsDir }
                return first < second
            }
            .prefix(5)
            .map { name in
                let fullPath = currentDir == "/" ? "/" + name : currentDir + "/" + name
                let isDir = isDirectory(at: currentDir + "/" + name)
                let displayPath = fullPath + (isDir ? "/" : "")

                return CompletionItem(
                    text: displayPath,
                    displayText: name + (isDir ? "/" : ""),
                    description: isDir ? "Directory" : "File",
                    icon: isDir ? "folder.fill" : "doc.fill",
                    score: 50,
                    source: .path
                )
            }
    }

    private func determineBaseDirectory(from input: String, relativeTo currentDir: String) -> String {
        if input.hasPrefix("/") {
            // 绝对路径
            let components = input.split(separator: "/").dropLast()
            return "/" + components.joined(separator: "/")
        } else if input.hasPrefix("~") {
            // home 目录路径
            let afterTilde = String(input.dropFirst())
            let components = afterTilde.split(separator: "/").dropLast()
            let home = NSHomeDirectory()
            return components.isEmpty ? home : home + "/" + components.joined(separator: "/")
        } else {
            // 相对路径
            let components = input.split(separator: "/").dropLast()
            return components.isEmpty ? currentDir : currentDir + "/" + components.joined(separator: "/")
        }
    }

    private func extractPartialName(from input: String, baseDir: String) -> String {
        if input.hasPrefix("/") {
            return input.split(separator: "/").last.map(String.init) ?? ""
        } else if input.hasPrefix("~") {
            let afterTilde = String(input.dropFirst())
            return afterTilde.split(separator: "/").last.map(String.init) ?? ""
        } else {
            return input.split(separator: "/").last.map(String.init) ?? ""
        }
    }

    private func isDirectory(at path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}

// MARK: - Argument Provider

/// 命令参数补全提供者
final class ArgumentCompletionProvider: CompletionProvider {
    static let shared = ArgumentCompletionProvider()

    private init() {}

    func priority() -> Int { 80 }

    func provideCompletions(for context: CompletionContext) -> [CompletionItem] {
        // 只有当前面有命令名时才提供参数补全
        guard let precedingWord = context.precedingWord else { return [] }

        // 查找匹配的内置命令
        guard let command = builtInCommands.first(where: { $0.name == precedingWord }),
              let arguments = command.arguments else {
            return []
        }

        let input = context.currentWord.lowercased()
        return arguments
            .filter { $0.lowercased().hasPrefix(input) }
            .prefix(5)
            .map { arg in
                CompletionItem(
                    text: arg,
                    displayText: arg,
                    description: "Argument",
                    icon: "text.alignleft",
                    score: 60,
                    source: .argument
                )
            }
    }
}

// MARK: - Main Completion Engine

/// 主补全引擎 - 协调所有补全提供者
final class CompletionEngine: ObservableObject {
    static let shared = CompletionEngine()

    private let providers: [any CompletionProvider]
    private let builtInProvider = BuiltInCompletionProvider.shared
    private let historyProvider = HistoryCompletionProvider.shared
    private let pathProvider = PathCompletionProvider.shared
    private let argumentProvider = ArgumentCompletionProvider.shared

    @Published var currentCompletions: [CompletionItem] = []
    @Published var isShowingCompletions = false
    @Published var selectedIndex = 0

    private var debounceTask: Task<Void, Never>?

    private init() {
        self.providers = [
            builtInProvider,
            argumentProvider,
            historyProvider,
            pathProvider
        ].sorted { $0.priority() > $1.priority() }
    }

    // MARK: - Public Methods

    /// 获取补全建议
    func getCompletions(
        for input: String,
        cursorPosition: Int? = nil,
        currentDirectory: String = "/home"
    ) {
        // 取消之前的延迟任务
        debounceTask?.cancel()

        // 延迟触发，避免频繁计算
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(100))

            guard !Task.isCancelled else { return }

            let position = cursorPosition ?? input.count
            let context = createContext(from: input, cursorPosition: position, currentDirectory: currentDirectory)

            let completions = await computeCompletions(for: context)

            await MainActor.run {
                self.currentCompletions = completions
                self.isShowingCompletions = !completions.isEmpty
                self.selectedIndex = 0
            }
        }
    }

    /// 应用补全
    func applyCompletion(at index: Int) -> CompletionItem? {
        guard index >= 0 && index < currentCompletions.count else { return nil }

        let completion = currentCompletions[index]
        hideCompletions()
        return completion
    }

    /// 切换到下一个补全
    func selectNext() {
        guard !currentCompletions.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % currentCompletions.count
    }

    /// 切换到上一个补全
    func selectPrevious() {
        guard !currentCompletions.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + currentCompletions.count) % currentCompletions.count
    }

    /// 隐藏补全弹窗
    func hideCompletions() {
        isShowingCompletions = false
        currentCompletions = []
        selectedIndex = 0
    }

    /// Tab 键处理 - 展开补全
    func handleTab() -> CompletionItem? {
        guard isShowingCompletions && !currentCompletions.isEmpty else { return nil }
        return applyCompletion(at: selectedIndex)
    }

    // MARK: - Private Methods

    private func createContext(from input: String, cursorPosition: Int, currentDirectory: String) -> CompletionContext {
        let cursorPos = min(cursorPosition, input.count)

        // 提取当前单词
        let beforeCursor = String(input.prefix(cursorPos))
        let words = beforeCursor.components(separatedBy: .whitespaces)
        let currentWord = words.last ?? ""
        let precedingWord = words.count > 1 ? words[words.count - 2] : nil

        return CompletionContext(
            input: input,
            cursorPosition: cursorPos,
            currentWord: currentWord,
            precedingWord: precedingWord,
            isAtStartOfLine: words.count <= 1,
            currentDirectory: currentDirectory
        )
    }

    private func computeCompletions(for context: CompletionContext) async -> [CompletionItem] {
        var allCompletions: [CompletionItem] = []

        for provider in providers {
            let completions = provider.provideCompletions(for: context)
            allCompletions.append(contentsOf: completions)
        }

        return deduplicateAndSort(allCompletions)
    }

    private func deduplicateAndSort(_ items: [CompletionItem]) -> [CompletionItem] {
        var seen = Set<String>()
        var result: [CompletionItem] = []

        // 按分数排序，高分在前
        let sorted = items.sorted { $0.score > $1.score }

        for item in sorted {
            // 去重
            if !seen.contains(item.text) {
                seen.insert(item.text)
                result.append(item)
            }

            // 限制数量
            if result.count >= 10 { break }
        }

        return result
    }
}

// MARK: - Fuzzy Matching

extension CompletionEngine {
    /// 模糊匹配分数计算
    static func fuzzyMatchScore(pattern: String, candidate: String) -> Int {
        let pattern = pattern.lowercased()
        let candidate = candidate.lowercased()

        // 精确前缀匹配得分最高
        if candidate.hasPrefix(pattern) {
            return 1000 + candidate.count
        }

        // 包含匹配
        if candidate.contains(pattern) {
            return 500 + candidate.count
        }

        // 模糊匹配 - 计算共同字符
        var score = 0
        var patternIndex = pattern.startIndex
        var consecutiveBonus = 0

        for char in candidate {
            if patternIndex < pattern.endIndex && char == pattern[patternIndex] {
                score += 10
                consecutiveBonus += 5
                score += consecutiveBonus
                patternIndex = pattern.index(after: patternIndex)
            } else {
                consecutiveBonus = 0
            }
        }

        // 全部匹配才给分
        if patternIndex != pattern.endIndex {
            return 0
        }

        return score
    }
}
