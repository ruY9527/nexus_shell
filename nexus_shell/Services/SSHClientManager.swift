//
//  SSHClientManager.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Network

/// 用于在并发环境中安全地修改值的包装类
final class UnsafeSendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) var value: T
    nonisolated init(_ value: T) { self.value = value }
}

/// SSH 客户端管理器
final class SSHClientManager {
    static let shared = SSHClientManager()
    private init() {}

    private static var usesSimulatedNetworkForUITests: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--ui-testing") && arguments.contains("--ui-testing-simulated-network")
    }
    
    // MARK: - Connection Test
    
    static func testConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async -> ConnectionTestResult {
        let reachable = await testNetworkReachability(host: host, port: port)
        if !reachable {
            return .failure("Network unreachable or connection refused")
        }
        
        var credentials: String?
        switch authMethod {
        case .password:
            credentials = KeychainHelper.shared.getPassword(for: serverId)
        case .privateKey:
            credentials = KeychainHelper.shared.getPrivateKey(for: serverId)
        }

        if credentials == nil && usesSimulatedNetworkForUITests {
            credentials = "ui-test-credentials"
        }
        
        guard credentials != nil else {
            return .failure("Authentication credentials not found")
        }
        
        do {
            try await Task.sleep(for: .milliseconds(500))
            return .success
        } catch {
            return .failure("Connection timeout")
        }
    }
    
    static func testNetworkReachability(host: String, port: Int) async -> Bool {
        if usesSimulatedNetworkForUITests {
            return true
        }

        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                to: .hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port))),
                using: .tcp
            )

            final class ResumeState: Sendable {
                let hasResumed = UnsafeSendableBox<Bool>(false)
            }
            let resumeState = ResumeState()

            connection.stateUpdateHandler = { state in
                guard !resumeState.hasResumed.value else { return }
                switch state {
                case .ready:
                    connection.cancel()
                    resumeState.hasResumed.value = true
                    continuation.resume(returning: true)
                case .failed, .waiting:
                    connection.cancel()
                    resumeState.hasResumed.value = true
                    continuation.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                guard !resumeState.hasResumed.value else { return }
                connection.cancel()
                resumeState.hasResumed.value = true
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - SSH Connection
    
    func createConnection(
        host: String,
        port: Int,
        username: String,
        authMethod: AuthMethod,
        serverId: UUID
    ) async throws -> SSHConnection {
        var credentials: String?
        switch authMethod {
        case .password:
            credentials = KeychainHelper.shared.getPassword(for: serverId)
        case .privateKey:
            credentials = KeychainHelper.shared.getPrivateKey(for: serverId)
        }

        if credentials == nil && Self.usesSimulatedNetworkForUITests {
            credentials = "ui-test-credentials"
        }
        
        guard let credentials else {
            throw SSHError.authenticationFailed("Credentials not found")
        }
        
        let connection = SSHConnection(
            host: host,
            port: port,
            username: username,
            authMethod: authMethod,
            credentials: credentials,
            serverId: serverId
        )
        
        try await connection.connect()
        return connection
    }
}

// MARK: - Types

enum ConnectionTestResult {
    case success
    case failure(String)
}

enum SSHError: Error, LocalizedError {
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String)
    case timeout
    case disconnected
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed(let msg): return "Authentication failed: \(msg)"
        case .commandFailed(let msg): return "Command failed: \(msg)"
        case .timeout: return "Connection timeout"
        case .disconnected: return "Connection disconnected"
        }
    }
}

struct MonitorUpdate {
    let serverId: UUID
    let cpuUsage: Double
    let memoryUsage: Double
    let status: ServerStatus
}

// MARK: - SSH Connection

actor SSHConnection {
    let host: String
    let port: Int
    let username: String
    let authMethod: AuthMethod
    let credentials: String
    let serverId: UUID
    
    private var isConnected = false
    private var outputHandler: ((String) -> Void)?
    private var currentDirectory = ""
    private let homeDirectory: String
    
    init(host: String, port: Int, username: String, authMethod: AuthMethod, credentials: String, serverId: UUID) {
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.credentials = credentials
        self.serverId = serverId
        self.homeDirectory = "/home/\(username)"
        self.currentDirectory = homeDirectory
    }
    
    func connect() async throws {
        try await Task.sleep(for: .milliseconds(300))
        
        let reachable = await SSHClientManager.testNetworkReachability(host: host, port: port)
        if !reachable {
            throw SSHError.connectionFailed("Cannot reach server at \(host):\(port)")
        }
        
        isConnected = true
        currentDirectory = homeDirectory
        
        outputHandler?("Welcome to \(host)!\nLast login: \(Date().formatted(date: .abbreviated, time: .shortened))\n\n")
    }
    
    func disconnect() {
        isConnected = false
        outputHandler?("Connection closed.\n")
    }
    
    func execute(command: String) async throws -> String {
        guard isConnected else { throw SSHError.disconnected }
        
        let delay = UInt64.random(in: 50...200)
        try await Task.sleep(for: .milliseconds(delay))
        
        let output = simulateCommandOutput(command)
        outputHandler?(output)
        return output
    }
    
    func setOutputHandler(_ handler: @escaping (String) -> Void) {
        self.outputHandler = handler
    }
    
    func checkConnection() -> Bool { isConnected }
    
    func getCurrentDirectory() -> String { currentDirectory }
    
    // MARK: - Command Simulation
    
    private func simulateCommandOutput(_ command: String) -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // cd 命令处理
        if trimmed.hasPrefix("cd ") {
            let path = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
            if path == ".." {
                let components = currentDirectory.split(separator: "/")
                if components.count > 1 {
                    currentDirectory = "/" + components.dropLast().joined(separator: "/")
                    if currentDirectory.isEmpty { currentDirectory = "/" }
                }
            } else if path == "/" { currentDirectory = "/" }
            else if path == "~" || path.isEmpty { currentDirectory = homeDirectory }
            else if path.hasPrefix("/") { currentDirectory = path }
            else { currentDirectory = currentDirectory + "/" + path }
            return ""
        }
        
        if trimmed == "clear" { return "\u{001B}[2J\u{001B}[H" }
        
        // 命令输出映射
        switch trimmed {
        case "ls": return generateLSOutput(simple: true, showHidden: false)
        case "ls -l": return generateLSOutput(simple: false, showHidden: false)
        case "ls -la": return generateLSOutput(simple: false, showHidden: true)
        case "ls -lh": return generateLSOutput(simple: false, showHidden: false, humanReadable: true)
        case "ls -lha": return generateLSOutput(simple: false, showHidden: true, humanReadable: true)
        case "pwd": return currentDirectory + "\n"
        case "whoami": return username + "\n"
        case "date": return Date().formatted(date: .complete, time: .complete) + "\n"
        case "uptime": return " \(Date().formatted(date: .omitted, time: .shortened)) up 1 day,  2:15,  1 user,  load average: 0.52, 0.58, 0.45\n"
        case "free": return "              total        used        free\nMem:        2048000     1300000      748000\nSwap:       1024000           0     1024000\n"
        case "free -h": return "              total        used        free\nMem:           2.0Gi       1.3Gi       748Mi\nSwap:          1.0Gi          0Bi       1.0Gi\n"
        case "free -m": return "              total        used        free\nMem:           2048        1300         748\nSwap:          1024           0        1024\n"
        case "df": return "Filesystem     1K-blocks     Used Available Use% Mounted on\n/dev/sda1       52428800 15728640  36700160  30% /\n/dev/sda2      104857600 47185920  57671680  45% /home\n"
        case "df -h": return "Filesystem      Size  Used Avail Use% Mounted on\n/dev/sda1       50G   15G   35G  30% /\n/dev/sda2      100G   45G   55G  45% /home\n"
        case "df -m": return "Filesystem     1M-blocks     Used Available Use% Mounted on\n/dev/sda1          51200    15360    35840  30% /\n/dev/sda2         102400    46080    56320  45% /home\n"
        case "top -bn1 | head -5": return generateTopOutput(lines: 5)
        case "top -bn1": return generateTopOutput()
        case "ps aux": return "USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\nroot         1  0.0  0.1      -     - ?        Ss   10:00   0:00 /sbin/init\n\(username)   12345  0.0  0.1      -     - pts/0    Ss   10:00   0:00 bash\n"
        case "uname -a": return "Linux \(host) 5.15.0-generic #1 SMP x86_64 GNU/Linux\n"
        case "hostname": return (host.components(separatedBy: ".").first ?? host) + "\n"
        case "ifconfig": return generateIfconfigOutput()
        case "ip addr": return generateIPOutput()
        case "netstat -tuln": return "Active Internet connections\nProto Recv-Q Send-Q Local Address     Foreign Address   State\ntcp        0      0 0.0.0.0:22        0.0.0.0:*         LISTEN\ntcp        0      0 0.0.0.0:80        0.0.0.0:*         LISTEN\n"
        case "docker ps": return "CONTAINER ID   IMAGE          COMMAND        STATUS       PORTS              NAMES\na1b2c3d4e5f6   nginx:latest   \"nginx...\"     Up 2 hours   0.0.0.0:80->80/tcp web-server\n"
        case "docker images": return "REPOSITORY   TAG      IMAGE ID       CREATED        SIZE\nnginx        latest   def0a1b2c3d4   2 weeks ago    142MB\nredis        latest   abc1b2c3d4e5  3 weeks ago    117MB\n"
        case "systemctl status sshd": return "● ssh.service - OpenSSH Daemon\n   Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        case "cat /etc/os-release": return "PRETTY_NAME=\"Ubuntu 22.04.3 LTS\"\nNAME=\"Ubuntu\"\nVERSION_ID=\"22.04\"\n"
        case "env": return "SHELL=/bin/bash\nUSER=\(username)\nHOME=\(homeDirectory)\nPATH=/usr/local/bin:/usr/bin:/bin\n"
        case "echo $PATH": return "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n"
        case "echo $HOME": return homeDirectory + "\n"
        case "echo $USER": return username + "\n"
        case "id": return "uid=1000(\(username)) gid=1000(\(username))\n"
        case "w": return "USER     TTY        FROM             LOGIN@\n\(username) pts/0      192.168.1.1      10:00\n"
        case "history": return "    1  ls -la\n    2  pwd\n    3  cd /var/log\n"
        case "ping -c 4 localhost": return "PING localhost (127.0.0.1) 56(84) bytes of data.\n64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.021 ms\n64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.018 ms\n64 bytes from localhost (127.0.0.1): icmp_seq=3 ttl=64 time=0.015 ms\n64 bytes from localhost (127.0.0.1): icmp_seq=4 ttl=64 time=0.012 ms\n\n--- localhost ping statistics ---\n4 packets transmitted, 4 received, 0% packet loss, time 3068ms\n"
        case "ping -c 4 8.8.8.8": return "PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.\n64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.5 ms\n64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=11.8 ms\n64 bytes from 8.8.8.8: icmp_seq=3 ttl=117 time=13.2 ms\n64 bytes from 8.8.8.8: icmp_seq=4 ttl=117 time=12.1 ms\n\n--- 8.8.8.8 ping statistics ---\n4 packets transmitted, 4 received, 0% packet loss, time 3007ms\n"
        case "cat /proc/meminfo": return "MemTotal:        2048000 kB\nMemFree:          748000 kB\nMemAvailable:     1400000 kB\nBuffers:           50000 kB\nCached:           200000 kB\nSwapTotal:       1024000 kB\nSwapFree:        1024000 kB\n"
        case "cat /proc/cpuinfo | head -10": return "processor       : 0\nvendor_id        : GenuineIntel\ncpu family       : 6\nmodel            : 142\nmodel name       : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz\nstepping         : 4\nmicrocode        : 0x96\ncpu MHz          : 2000.000\ncache size       : 8192 KB\nphysical id      : 0\n"
        case "systemctl status nginx": return "● nginx.service - A high performance web server\n   Loaded: loaded (/lib/systemd/system/nginx.service; enabled)\n   Active: active (running) since Mon 2024-04-22 09:00:00 UTC\n Main PID: 1235 (nginx)\n    Tasks: 3\n   Memory: 5.2M\n"
        case "systemctl status docker": return "● docker.service - Docker Application Container Engine\n   Loaded: loaded (/lib/systemd/system/docker.service; enabled)\n   Active: active (running) since Mon 2024-04-22 08:00:00 UTC\n Main PID: 1234 (dockerd)\n    Tasks: 12\n   Memory: 45.2M\n"
        case "tail -20 /var/log/syslog": return "Apr 22 10:00:01 server CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)\nApr 22 10:05:01 server sshd[12346]: Accepted publickey for admin from 192.168.1.1\nApr 22 10:10:01 server systemd[1]: Started Daily apt download activities.\nApr 22 10:15:01 server kernel: [UFW BLOCK] IN=eth0 OUT= MAC=00:11:22:33:44:55\n"
        case "lsblk": return "NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT\nsda      8:0    0  150G  0 disk\nsda1     8:1    0   50G  0 part /\nsda2     8:2    0  100G  0 part /home\n"
        case "lscpu": return "Architecture:        x86_64\nCPU op-mode(s):      32-bit, 64-bit\nCPU(s):              4\nThread(s) per core:  2\nCore(s) per socket:  2\nSocket(s):           1\nModel name:          Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz\nCPU MHz:             2000.000\n"
        case "", " ": return ""
        case "exit": return "logout\n"
        default:
            if trimmed.hasPrefix("echo ") {
                return String(trimmed.dropFirst(5)) + "\n"
            }
            return "\(trimmed): executed\n"
        }
    }
    
    private func generateLSOutput(simple: Bool, showHidden: Bool = true, humanReadable: Bool = false) -> String {
        let allFiles = ["Documents", "Downloads", ".bashrc", ".bash_history", "app.log"]
        let files = showHidden ? allFiles : allFiles.filter { !$0.hasPrefix(".") }
        
        if simple { return files.joined(separator: "  ") + "\n" }
        
        let now = Date()
        let output = files.map { name in
            let size = name.hasPrefix(".") ? 1024 : 4096
            let sizeStr = humanReadable ? "\(size/1024)K" : "\(size)"
            let perms = name.hasSuffix("s") ? "drwxr-xr-x" : "-rw-r--r--"
            return "\(perms)  1 \(username) \(username)  \(sizeStr)  \(now.formatted(date: .abbreviated, time: .omitted))  \(name)"
        }.joined(separator: "\n")
        return "total 20\n" + output + "\n"
    }
    
    private func generateTopOutput(lines: Int = 15) -> String {
        let header = """
        top - \(Date().formatted(date: .omitted, time: .shortened)) up 1 day,  2:15,  1 user,  load average: 0.52, 0.58, 0.45
        Tasks:  85 total,   1 running,  84 sleeping
        %Cpu(s):  5.2 us,  2.1 sy,  0.0 ni, 92.5 id
        MiB Mem :   2048.0 total,    748.0 free,   1300.0 used
        
        """
        if lines <= 5 { return header }
        return header + "  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND\n12345 \(username)   20   0   15000   3500   2000 R   5.2   0.2   0:00.01 top\n"
    }
    
    private func generateIfconfigOutput() -> String {
        return """
        eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
                inet 192.168.1.100  netmask 255.255.255.0
                ether 00:11:22:33:44:55
        
        lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
                inet 127.0.0.1  netmask 255.0.0.0
        
        """
    }
    
    private func generateIPOutput() -> String {
        return """
        1: lo: <LOOPBACK,UP,LOWER_UP>
            inet 127.0.0.1/8 scope host lo
        2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
            inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0
        
        """
    }
}

// MARK: - Server Monitor

actor ServerMonitor {
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let interval: TimeInterval = 30.0
    private var handler: ((MonitorUpdate) -> Void)?
    
    func setUpdateHandler(_ h: @escaping (MonitorUpdate) -> Void) { handler = h }
    
    func startMonitoring(serverId: UUID, connection: SSHConnection) {
        stopMonitoring(serverId)
        let task = Task {
            while !Task.isCancelled {
                do {
                    let cpuOutput = try await connection.execute(command: "top -bn1 | head -5")
                    let memOutput = try await connection.execute(command: "free -m")
                    
                    let cpu = parseCPU(cpuOutput)
                    let mem = parseMem(memOutput)
                    let status: ServerStatus = (cpu > 80 || mem > 80) ? .warning : .online
                    
                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: cpu, memoryUsage: mem, status: status))
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    handler?(MonitorUpdate(serverId: serverId, cpuUsage: 0, memoryUsage: 0, status: .offline))
                    break
                }
            }
        }
        tasks[serverId] = task
    }
    
    func stopMonitoring(_ id: UUID) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }
    
    func stopAll() { tasks.keys.forEach { stopMonitoring($0) } }
    
    private func parseCPU(_ output: String) -> Double {
        if let range = output.range(of: "([\\d.]+) us", options: .regularExpression) {
            let nums = String(output[range]).extractNumbers()
            return nums.first ?? 45.5
        }
        return 45.5
    }
    
    private func parseMem(_ output: String) -> Double {
        for line in output.split(separator: "\n") {
            if line.contains("Mem:") {
                let nums = String(line).extractNumbers()
                if nums.count >= 2 { return (nums[1] / nums[0]) * 100.0 }
            }
        }
        return 62.3
    }
}

extension String {
    nonisolated func extractNumbers() -> [Double] {
        let regex = try? NSRegularExpression(pattern: "[\\d.]+")
        let matches = regex?.matches(in: self, range: NSRange(startIndex..., in: self))
        return matches?.compactMap { m in
            guard let r = Range(m.range, in: self) else { return nil }
            return Double(self[r])
        } ?? []
    }
}
