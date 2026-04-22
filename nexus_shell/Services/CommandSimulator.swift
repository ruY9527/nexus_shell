//
//  CommandSimulator.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 命令模拟器 - 模拟 Linux 命令输出
final class CommandSimulator {
    
    // MARK: - Properties
    
    private let host: String
    private let username: String
    private let port: Int
    private var currentDirectory: String
    private let homeDirectory: String
    
    // MARK: - Initialization
    
    init(host: String, username: String, port: Int) {
        self.host = host
        self.username = username
        self.port = port
        self.homeDirectory = "/home/\(username)"
        self.currentDirectory = homeDirectory
    }
    
    // MARK: - Public Methods
    
    /// 模拟命令执行并返回输出
    func simulate(_ command: String) -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 处理空命令
        if trimmed.isEmpty { return "" }
        
        // 处理 clear 命令
        if trimmed == "clear" { return "\u{001B}[2J\u{001B}[H" }
        
        // 处理 cd 命令（改变当前目录）
        if handleCDCommand(trimmed) { return "" }
        
        // 处理带管道的命令
        if trimmed.contains("|") {
            return handlePipedCommand(trimmed)
        }
        
        // 处理基础命令
        return handleBasicCommand(trimmed)
    }
    
    /// 更新当前目录
    func setCurrentDirectory(_ path: String) {
        currentDirectory = path
    }
    
    /// 获取当前目录
    func getCurrentDirectory() -> String {
        return currentDirectory
    }
    
    // MARK: - CD Command Handler
    
    private func handleCDCommand(_ command: String) -> Bool {
        guard command.hasPrefix("cd ") else { return false }
        
        let path = command.dropFirst(3).trimmingCharacters(in: .whitespaces)
        
        if path == ".." {
            let components = currentDirectory.split(separator: "/")
            if components.count > 1 {
                currentDirectory = "/" + components.dropLast().joined(separator: "/")
                if currentDirectory.isEmpty { currentDirectory = "/" }
            }
        } else if path == "/" {
            currentDirectory = "/"
        } else if path == "~" || path.isEmpty {
            currentDirectory = homeDirectory
        } else if path.hasPrefix("/") {
            currentDirectory = path
        } else {
            currentDirectory = currentDirectory + "/" + path
        }
        
        return true
    }
    
    // MARK: - Piped Command Handler
    
    private func handlePipedCommand(_ command: String) -> String {
        let parts = command.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // 处理常见管道命令
        switch command {
        case "top -bn1 | head -5":
            return TopGenerator.generate(lines: 5)
        case "ps aux | head -10":
            return ProcessGenerator.generatePSAux(lines: 10)
        case "ps aux | grep":
            return ProcessGenerator.generatePSAuxFiltered(parts.last ?? "")
        case "cat /proc/cpuinfo | head -10":
            return SystemInfoGenerator.generateCPUInfo()
        case "cat /proc/meminfo | head -10":
            return SystemInfoGenerator.generateMemInfo()
        case "ls -la | grep":
            return FileGenerator.generateLSFiltered(parts.last ?? "", username: username)
        case "df -h | grep":
            return DiskGenerator.generateDFFiltered(parts.last ?? "")
        case "netstat -tuln | grep":
            return NetworkGenerator.generateNetstatFiltered(parts.last ?? "")
        case "journalctl -u ssh --no-pager -n 10":
            return LogGenerator.generateSSHLogs()
        case "dmesg | tail -20":
            return LogGenerator.generateDmesg()
        default:
            // 简单管道模拟
            var output = handleBasicCommand(parts.first ?? "")
            for part in parts.dropFirst() {
                output = applyPipeFilter(output, filter: part)
            }
            return output
        }
    }
    
    private func applyPipeFilter(_ input: String, filter: String) -> String {
        let lines = input.split(separator: "\n")
        
        if filter.hasPrefix("head -") {
            let count = Int(filter.dropFirst(6)) ?? 5
            return lines.prefix(count).joined(separator: "\n") + "\n"
        }
        
        if filter.hasPrefix("tail -") {
            let count = Int(filter.dropFirst(6)) ?? 5
            return lines.suffix(count).joined(separator: "\n") + "\n"
        }
        
        if filter.hasPrefix("grep ") {
            let pattern = filter.dropFirst(5).trimmingCharacters(in: .whitespaces)
            return lines.filter { $0.contains(pattern) }.joined(separator: "\n") + "\n"
        }
        
        if filter == "wc -l" {
            return "\(lines.count)\n"
        }
        
        if filter == "sort" {
            return lines.sorted().joined(separator: "\n") + "\n"
        }
        
        if filter == "uniq" {
            return lines.uniqued().joined(separator: "\n") + "\n"
        }
        
        return input
    }
    
    // MARK: - Basic Command Handler
    
    private func handleBasicCommand(_ command: String) -> String {
        // 文件系统命令
        if let output = FileCommands.execute(command, username: username, currentDir: currentDirectory) {
            return output
        }
        
        // 系统信息命令
        if let output = SystemCommands.execute(command, host: host, username: username) {
            return output
        }
        
        // 资源监控命令
        if let output = ResourceCommands.execute(command) {
            return output
        }
        
        // 网络命令
        if let output = NetworkCommands.execute(command, host: host) {
            return output
        }
        
        // 进程管理命令
        if let output = ProcessCommands.execute(command, username: username) {
            return output
        }
        
        // Docker 命令
        if let output = DockerCommands.execute(command) {
            return output
        }
        
        // 服务管理命令
        if let output = ServiceCommands.execute(command) {
            return output
        }
        
        // 用户管理命令
        if let output = UserCommands.execute(command, username: username, homeDirectory: homeDirectory) {
            return output
        }
        
        // 日志命令
        if let output = LogCommands.execute(command) {
            return output
        }
        
        // 包管理命令
        if let output = PackageCommands.execute(command) {
            return output
        }
        
        // 实用工具命令（压缩、SSH、系统工具、文本处理、编码等）
        if let output = UtilityCommands.execute(command, username: username, homeDirectory: homeDirectory) {
            return output
        }
        
        // 特殊命令处理
        switch command {
        case "exit", "logout":
            return "logout\n"
        case "", " ":
            return ""
        default:
            // echo 命令
            if command.hasPrefix("echo ") {
                return String(command.dropFirst(5)) + "\n"
            }
            // cat 命令
            if command.hasPrefix("cat ") {
                return handleCatCommand(String(command.dropFirst(4)))
            }
            // touch 命令
            if command.hasPrefix("touch ") {
                return "" // 静默成功
            }
            // mkdir 命令
            if command.hasPrefix("mkdir ") {
                return "" // 静默成功
            }
            // rm 命令
            if command.hasPrefix("rm ") {
                return "" // 静默成功
            }
            // cp 命令
            if command.hasPrefix("cp ") {
                return "" // 静默成功
            }
            // mv 命令
            if command.hasPrefix("mv ") {
                return "" // 静默成功
            }
            // chmod 命令
            if command.hasPrefix("chmod ") {
                return "" // 静默成功
            }
            // chown 命令
            if command.hasPrefix("chown ") {
                return "" // 静默成功
            }
            // grep 命令（无管道）
            if command.hasPrefix("grep ") {
                return "Usage: grep [OPTION]... PATTERN [FILE]...\nTry 'grep --help' for more information.\n"
            }
            // find 命令
            if command.hasPrefix("find ") {
                return handleFindCommand(String(command.dropFirst(5)))
            }
            // which 命令
            if command.hasPrefix("which ") {
                return handleWhichCommand(String(command.dropFirst(6)))
            }
            // man 命令
            if command.hasPrefix("man ") {
                return "No manual entry for \(command.dropFirst(4))\n"
            }
            // help 命令
            if command == "help" || command == "--help" {
                return generateHelpOutput()
            }
            // history 命令
            if command == "history" {
                return UserGenerator.generateHistory()
            }
            
            return "\(command): command not found\n"
        }
    }
    
    // MARK: - Cat Command Handler
    
    private func handleCatCommand(_ path: String) -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespaces)
        
        switch trimmedPath {
        case "/etc/os-release":
            return SystemInfoGenerator.generateOSRelease()
        case "/etc/hostname":
            return (host.components(separatedBy: ".").first ?? host) + "\n"
        case "/etc/passwd":
            return UserGenerator.generatePasswd(username: username)
        case "/etc/group":
            return UserGenerator.generateGroup(username: username)
        case "/etc/hosts":
            return NetworkGenerator.generateHosts()
        case "/etc/resolv.conf":
            return NetworkGenerator.generateResolvConf()
        case "/proc/cpuinfo":
            return SystemInfoGenerator.generateFullCPUInfo()
        case "/proc/meminfo":
            return SystemInfoGenerator.generateFullMemInfo()
        case "/proc/version":
            return SystemInfoGenerator.generateProcVersion()
        case "/proc/loadavg":
            return "0.52 0.58 0.45 1/85 12345\n"
        case "/proc/uptime":
            return "86400.52 86000.00\n" // 系统运行时间（秒）
        case "/var/log/syslog", "/var/log/messages":
            return LogGenerator.generateSyslog()
        case "/var/log/auth.log":
            return LogGenerator.generateAuthLog()
        case "~/.bashrc":
            return FileGenerator.generateBashrc(username: username)
        case "~/.bash_history":
            return UserGenerator.generateHistory()
        case "/etc/fstab":
            return DiskGenerator.generateFstab()
        case "/etc/mtab", "/proc/mounts":
            return DiskGenerator.generateMounts()
        default:
            // 如果路径以 /proc/ 开头，尝试处理
            if trimmedPath.hasPrefix("/proc/") {
                return handleProcFile(trimmedPath)
            }
            return "cat: \(trimmedPath): No such file or directory\n"
        }
    }
    
    private func handleProcFile(_ path: String) -> String {
        switch path {
        case "/proc/1/status":
            return "Name:    init\nState:    S (sleeping)\nPid:    1\nPPid:    0\n"
        case "/proc/self/status":
            return "Name:    bash\nState:    S (sleeping)\nPid:    12345\nPPid:    12344\nUid:    1000    1000    1000    1000\n"
        case "/proc/self/cmdline":
            return "/bin/bash\0"
        case "/proc/self/environ":
            return "SHELL=/bin/bash\nUSER=\(username)\nHOME=\(homeDirectory)\n"
        case "/proc/net/tcp":
            return NetworkGenerator.generateProcNetTCP()
        case "/proc/net/dev":
            return NetworkGenerator.generateProcNetDev()
        default:
            return "cat: \(path): No such file or directory\n"
        }
    }
    
    // MARK: - Find Command Handler
    
    private func handleFindCommand(_ args: String) -> String {
        let parts = args.split(separator: " ").map { String($0) }
        var output = ""
        let searchPath = parts.first ?? currentDirectory
        
        // 模拟一些常见的查找结果
        let commonFiles = [
            "\(searchPath)/Documents/report.pdf",
            "\(searchPath)/Downloads/archive.tar.gz",
            "\(searchPath)/src/main.py",
            "\(searchPath)/config/app.conf",
            "\(searchPath)/logs/app.log"
        ]
        
        for file in commonFiles {
            output += file + "\n"
        }
        
        return output
    }
    
    // MARK: - Which Command Handler
    
    private func handleWhichCommand(_ cmd: String) -> String {
        let commonCommands = [
            "ls": "/usr/bin/ls",
            "cat": "/usr/bin/cat",
            "grep": "/usr/bin/grep",
            "sed": "/usr/bin/sed",
            "awk": "/usr/bin/awk",
            "find": "/usr/bin/find",
            "ssh": "/usr/bin/ssh",
            "scp": "/usr/bin/scp",
            "curl": "/usr/bin/curl",
            "wget": "/usr/bin/wget",
            "python": "/usr/bin/python3",
            "python3": "/usr/bin/python3",
            "perl": "/usr/bin/perl",
            "ruby": "/usr/bin/ruby",
            "node": "/usr/bin/node",
            "npm": "/usr/bin/npm",
            "docker": "/usr/bin/docker",
            "git": "/usr/bin/git",
            "vim": "/usr/bin/vim",
            "nano": "/usr/bin/nano",
            "top": "/usr/bin/top",
            "htop": "/usr/bin/htop",
            "ps": "/usr/bin/ps",
            "kill": "/usr/bin/kill",
            "killall": "/usr/bin/killall",
            "systemctl": "/usr/bin/systemctl",
            "service": "/usr/sbin/service",
            "journalctl": "/usr/bin/journalctl",
            "tar": "/usr/bin/tar",
            "gzip": "/usr/bin/gzip",
            "zip": "/usr/bin/zip",
            "unzip": "/usr/bin/unzip",
            "chmod": "/usr/bin/chmod",
            "chown": "/usr/bin/chown",
            "cp": "/usr/bin/cp",
            "mv": "/usr/bin/mv",
            "rm": "/usr/bin/rm",
            "mkdir": "/usr/bin/mkdir",
            "rmdir": "/usr/bin/rmdir",
            "touch": "/usr/bin/touch",
            "ln": "/usr/bin/ln",
            "df": "/usr/bin/df",
            "du": "/usr/bin/du",
            "free": "/usr/bin/free",
            "mount": "/usr/bin/mount",
            "umount": "/usr/bin/umount",
            "fdisk": "/usr/sbin/fdisk",
            "parted": "/usr/sbin/parted",
            "lsblk": "/usr/bin/lsblk",
            "lscpu": "/usr/bin/lscpu",
            "lsmem": "/usr/bin/lsmem",
            "uname": "/usr/bin/uname",
            "hostname": "/usr/bin/hostname",
            "whoami": "/usr/bin/whoami",
            "id": "/usr/bin/id",
            "who": "/usr/bin/who",
            "w": "/usr/bin/w",
            "last": "/usr/bin/last",
            "lastlog": "/usr/bin/lastlog",
            "ping": "/usr/bin/ping",
            "traceroute": "/usr/bin/traceroute",
            "netstat": "/usr/bin/netstat",
            "ss": "/usr/bin/ss",
            "ip": "/usr/sbin/ip",
            "ifconfig": "/usr/sbin/ifconfig",
            "route": "/usr/sbin/route",
            "arp": "/usr/sbin/arp",
            "nslookup": "/usr/bin/nslookup",
            "dig": "/usr/bin/dig",
            "host": "/usr/bin/host",
            "nmap": "/usr/bin/nmap",
            "tcpdump": "/usr/sbin/tcpdump",
            "iptables": "/usr/sbin/iptables",
            "ufw": "/usr/sbin/ufw",
            "env": "/usr/bin/env",
            "printenv": "/usr/bin/printenv",
            "export": "export: shell built-in command",
            "alias": "alias: shell built-in command",
            "source": "source: shell built-in command",
            "history": "history: shell built-in command",
            "man": "/usr/bin/man",
            "info": "/usr/bin/info",
            "help": "help: shell built-in command"
        ]
        
        let cmdName = cmd.trimmingCharacters(in: .whitespaces)
        if let path = commonCommands[cmdName] {
            return path + "\n"
        }
        
        return ""
    }
    
    // MARK: - Help Output
    
    private func generateHelpOutput() -> String {
        return """
        Available commands (simulated):
        
        File system:     ls, ls -l, ls -la, ls -lh, cd, pwd, cat, touch, mkdir, rm, cp, mv, find, which
        System info:     uname, hostname, uptime, date, whoami, id, w, who, last, lscpu, lsblk, lsmem
        Resources:       free, free -h, free -m, df, df -h, df -m, du, du -h, top, htop, vmstat, iostat
        Processes:       ps, ps aux, ps aux | grep, kill, killall, pgrep, pkill, pstree, pidstat
        Network:         ifconfig, ip addr, ip route, netstat, ss, ping, traceroute, nslookup, dig, nmap
        Docker:          docker ps, docker images, docker logs, docker exec, docker stats, docker compose
        Services:        systemctl status/list/start/stop/restart, service, journalctl, crontab
        Users:           whoami, id, groups, passwd, useradd, userdel, usermod, last, lastlog, chage
        Logs:            journalctl, tail /var/log/syslog, cat /var/log/auth.log, dmesg, grep
        Package:         apt/apt-get, dpkg, yum, dnf, snap, pip, npm
        Compression:     tar, gzip, gunzip, zip, unzip, 7z, bzip2, xz
        SSH/Transfer:    ssh-keygen, ssh-copy-id, scp, sftp, rsync
        System utils:    lsof, nc (netcat), screen, tmux, nohup, watch, time, dd, yes, expect
        Text processing: sed, awk, cut, tr, rev, shuf, fmt, fold, paste, join, split, nl, pr
        Encoding:        base64, md5sum, sha256sum, sha1sum, cksum, xxd, hexdump, od, strings
        
        Type any command to see simulated output.
        
        """
    }
}

// MARK: - Array Extension

extension Array where Element: Equatable {
    func uniqued() -> [Element] {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}