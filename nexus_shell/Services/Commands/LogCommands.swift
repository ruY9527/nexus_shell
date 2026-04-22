//
//  LogCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 日志命令模拟
enum LogCommands {
    
    static func execute(_ command: String) -> String? {
        switch command {
        case "tail /var/log/syslog":
            return LogGenerator.generateSyslog()
        case "tail -20 /var/log/syslog":
            return LogGenerator.generateSyslog()
        case "tail -f /var/log/syslog":
            return LogGenerator.generateSyslog() + "(Press Ctrl+C to stop)\n"
        case "tail /var/log/auth.log":
            return LogGenerator.generateAuthLog()
        case "tail -20 /var/log/auth.log":
            return LogGenerator.generateAuthLog()
        case "tail /var/log/messages":
            return LogGenerator.generateSyslog()
        case "tail /var/log/kern.log":
            return LogGenerator.generateKernLog()
        case "tail /var/log/nginx/access.log":
            return LogGenerator.generateNginxAccessLog()
        case "tail /var/log/nginx/error.log":
            return LogGenerator.generateNginxErrorLog()
        case "tail /var/log/mysql/error.log":
            return LogGenerator.generateMySQLErrorLog()
        case "tail /var/log/docker.log":
            return LogGenerator.generateDockerLog()
        case "tail /var/log/apt/history.log":
            return LogGenerator.generateAPTHistoryLog()
        case "head /var/log/syslog":
            return LogGenerator.generateSyslogHeader()
        case "head -20 /var/log/syslog":
            return LogGenerator.generateSyslogHeader()
        case "grep":
            return "Usage: grep [OPTION]... PATTERN [FILE]...\n"
        case "grep error /var/log/syslog":
            return LogGenerator.generateSyslogErrors()
        case "grep ERROR /var/log/syslog":
            return LogGenerator.generateSyslogErrors()
        case "grep -i error /var/log/syslog":
            return LogGenerator.generateSyslogErrors()
        case "grep -c error /var/log/syslog":
            return "5\n"
        case "grep -n error /var/log/syslog":
            return LogGenerator.generateSyslogErrorsWithNumbers()
        case "grep ssh /var/log/auth.log":
            return LogGenerator.generateAuthLogSSH()
        case "awk":
            return "Usage: awk [options] 'script' file(s)\n"
        case "sed":
            return "Usage: sed [options] 'command' file(s)\n"
        case "cut":
            return "Usage: cut [options] file\n"
        case "sort":
            return "Usage: sort [options] file(s)\n"
        case "uniq":
            return "Usage: uniq [options] file\n"
        case "wc":
            return "Usage: wc [options] file(s)\n"
        case "wc -l /var/log/syslog":
            return "12345 /var/log/syslog\n"
        case "wc -w /var/log/syslog":
            return "50000 /var/log/syslog\n"
        case "wc -c /var/log/syslog":
            return "1000000 /var/log/syslog\n"
        case "diff":
            return "Usage: diff [options] file1 file2\n"
        case "patch":
            return "Usage: patch [options] [origfile [patchfile]]\n"
        case "tee":
            return "Usage: tee [OPTION]... [FILE]...\n"
        case "xargs":
            return "Usage: xargs [options] [command [initial-args]]\n"
        case "more":
            return "(Press space to continue, q to quit)\n"
        case "less":
            return "(Press h for help, q to quit)\n"
        case "head":
            return "Usage: head [OPTION]... [FILE]...\n"
        case "head -n 5":
            return "Usage: head -n NUM [FILE]...\n"
        case "tail":
            return "Usage: tail [OPTION]... [FILE]...\n"
        case "tail -n 5":
            return "Usage: tail -n NUM [FILE]...\n"
        case "logrotate":
            return "Usage: logrotate [options] <configfile>\n"
        case "logrotate -d /etc/logrotate.conf":
            return LogGenerator.generateLogrotateDebug()
        case "logrotate -f /etc/logrotate.conf":
            return "" // 静默成功
        case "logger":
            return "Usage: logger [options] [message]\n"
        case "logger test message":
            return "" // 静默成功
        case "dmesg":
            return LogGenerator.generateDmesg()
        case "dmesg -T":
            return LogGenerator.generateDmesgTimestamped()
        case "dmesg | tail":
            return LogGenerator.generateDmesgTail()
        default:
            return nil
        }
    }
}

/// 日志生成器
enum LogGenerator {
    
    static func generateSyslog() -> String {
        return """
        Apr 22 10:00:01 server CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
        Apr 22 10:05:01 server sshd[12346]: Accepted publickey for admin from 192.168.1.1 port 54321 ssh2
        Apr 22 10:10:01 server systemd[1]: Started Daily apt download activities.
        Apr 22 10:15:01 server kernel: [UFW BLOCK] IN=eth0 OUT= MAC=00:11:22:33:44:55 SRC=10.0.0.1 DST=192.168.1.100
        Apr 22 10:20:01 server nginx[12347]: Request processed successfully from 192.168.1.2
        Apr 22 10:25:01 server docker[12350]: Container web-server started
        Apr 22 10:30:01 server mysql[12352]: Query executed in 0.05 seconds
        
        """
    }
    
    static func generateSyslogHeader() -> String {
        return """
        Apr 22 00:00:01 server rsyslogd:  [origin software="rsyslogd" swVersion="8.2112.0" x-pid="100" x-info="https://www.rsyslog.com"] start
        Apr 22 00:00:02 server kernel: [    0.000000] Linux version 5.15.0-generic (builder@buildhost) (gcc (Ubuntu 11.2.0-19ubuntu1) 11.2.0)
        Apr 22 00:00:03 server kernel: [    0.000001] Command line: BOOT_IMAGE=/vmlinuz-5.15.0-generic root=/dev/sda1
        
        """
    }
    
    static func generateSyslogErrors() -> String {
        return """
        Apr 22 10:15:01 server kernel: [ERROR] Network interface eth0 timeout
        Apr 22 10:20:01 server nginx[12347]: [error] Connection refused from 192.168.1.3
        Apr 22 10:25:01 server mysql[12352]: [ERROR] Query timeout exceeded
        
        """
    }
    
    static func generateSyslogErrorsWithNumbers() -> String {
        return """
        5:Apr 22 10:15:01 server kernel: [ERROR] Network interface eth0 timeout
        10:Apr 22 10:20:01 server nginx[12347]: [error] Connection refused
        15:Apr 22 10:25:01 server mysql[12352]: [ERROR] Query timeout exceeded
        
        """
    }
    
    static func generateAuthLog() -> String {
        return """
        Apr 22 10:00:01 server sshd[12346]: Accepted publickey for admin from 192.168.1.1 port 54321 ssh2
        Apr 22 10:00:02 server sshd[12346]: pam_unix(sshd:session): session opened for user admin
        Apr 22 10:05:01 server sudo: admin : TTY=pts/0 ; PWD=/home/admin ; USER=root ; COMMAND=/usr/bin/apt update
        Apr 22 10:10:01 server sshd[12347]: Failed password for invalid user test from 192.168.1.5 port 12345 ssh2
        Apr 22 10:15:01 server sshd[12347]: Connection closed by 192.168.1.5 port 12345 [preauth]
        
        """
    }
    
    static func generateAuthLogSSH() -> String {
        return """
        Apr 22 10:00:01 server sshd[12346]: Accepted publickey for admin from 192.168.1.1 port 54321 ssh2
        Apr 22 10:00:02 server sshd[12346]: pam_unix(sshd:session): session opened for user admin
        Apr 22 10:10:01 server sshd[12347]: Failed password for invalid user test from 192.168.1.5
        
        """
    }
    
    static func generateKernLog() -> String {
        return """
        Apr 22 10:00:01 server kernel: [    0.000000] Linux version 5.15.0-generic
        Apr 22 10:00:02 server kernel: [    1.000000] ACPI: Core revision 20210730
        Apr 22 10:00:03 server kernel: [    2.000000] PCI: Using configuration type 1 for base access
        Apr 22 10:00:04 server kernel: [    3.000000] HugeTLB registered 2.00 MiB page size
        
        """
    }
    
    static func generateSSHLogs() -> String {
        return """
        -- Logs begin at \(Date().formatted(date: .abbreviated, time: .shortened)) --
        Apr 22 08:00:00 server sshd[1]: Server listening on 0.0.0.0 port 22
        Apr 22 09:00:00 server sshd[123]: Accepted publickey for admin
        Apr 22 10:00:00 server sshd[456]: Accepted password for user1
        
        """
    }
    
    static func generateNginxLogs() -> String {
        return """
        -- Logs begin at \(Date().formatted(date: .abbreviated, time: .shortened)) --
        Apr 22 10:00:01 server nginx[12347]: Starting nginx server
        Apr 22 10:00:02 server nginx[12347]: Listening on port 80
        Apr 22 10:05:01 server nginx[12347]: Request from 192.168.1.1
        
        """
    }
    
    static func generateDockerLogs() -> String {
        return """
        -- Logs begin at \(Date().formatted(date: .abbreviated, time: .shortened)) --
        Apr 22 10:00:01 server dockerd[12350]: Starting Docker daemon
        Apr 22 10:00:02 server dockerd[12350]: Loading containers from /var/lib/docker
        Apr 22 10:05:01 server dockerd[12350]: Container web-server started
        
        """
    }
    
    static func generateRecentLogs() -> String {
        return """
        Apr 22 10:30:01 server CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
        Apr 22 10:35:01 server sshd[12346]: Accepted publickey for admin
        Apr 22 10:40:01 server systemd[1]: Started Session 123 of user admin
        Apr 22 10:45:01 server nginx[12347]: Request from 192.168.1.2
        
        """
    }
    
    static func generateBootLogs() -> String {
        return """
        -- Logs begin at \(Date().formatted(date: .abbreviated, time: .shortened)) --
        Apr 22 08:00:00 server systemd[1]: Starting system...
        Apr 22 08:00:01 server kernel: Linux version 5.15.0-generic
        Apr 22 08:00:02 server systemd[1]: Started Journal Service
        Apr 22 08:00:03 server systemd[1]: Started OpenSSH server
        Apr 22 08:00:04 server systemd[1]: Started Docker
        Apr 22 08:00:05 server systemd[1]: Reached target Multi-User System
        
        """
    }
    
    static func generateErrorLogs() -> String {
        return """
        Apr 22 10:15:01 server kernel: [UFW BLOCK] Connection blocked
        Apr 22 10:20:01 server nginx[12347]: [error] Connection timeout
        Apr 22 10:25:01 server mysql[12352]: [ERROR] Disk space low
        
        """
    }
    
    static func generateDmesg() -> String {
        return """
        [    0.000000] Linux version 5.15.0-generic (builder@buildhost)
        [    0.000001] Command line: BOOT_IMAGE=/vmlinuz-5.15.0-generic
        [    1.000000] ACPI: Core revision 20210730
        [    2.000000] PCI: Using configuration type 1
        [    3.000000] HugeTLB registered 2.00 MiB page size
        [    4.000000] VFS: Mounted root (ext4 filesystem) readonly
        
        """
    }
    
    static func generateDmesgTimestamped() -> String {
        return """
        [Apr 22 10:00:00] Linux version 5.15.0-generic
        [Apr 22 10:00:01] Command line: BOOT_IMAGE=/vmlinuz-5.15.0-generic
        [Apr 22 10:00:02] ACPI: Core revision 20210730
        [Apr 22 10:00:03] PCI: Using configuration type 1
        
        """
    }
    
    static func generateDmesgTail() -> String {
        return """
        [  100.000000] eth0: link up (1000Mbps/Full duplex)
        [  101.000000] docker: network bridge created
        [  102.000000] nginx: worker process started
        
        """
    }
    
    static func generateNginxAccessLog() -> String {
        return """
        192.168.1.1 - - [22/Apr/2026:10:00:01 +0000] "GET / HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
        192.168.1.2 - - [22/Apr/2026:10:05:01 +0000] "GET /api/users HTTP/1.1" 200 567 "-" "curl/7.81.0"
        192.168.1.3 - - [22/Apr/2026:10:10:01 +0000] "POST /api/users HTTP/1.1" 201 89 "-" "PostmanRuntime/7.29.0"
        
        """
    }
    
    static func generateNginxErrorLog() -> String {
        return """
        2026/04/22 10:00:01 [error] 12347#0: *1 connect() failed (111: Connection refused)
        2026/04/22 10:05:01 [warn] 12347#0: *2 upstream server temporarily disabled
        
        """
    }
    
    static func generateMySQLErrorLog() -> String {
        return """
        2026-04-22T10:00:01.000000Z 0 [Note] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections.
        2026-04-22T10:05:01.000000Z 0 [Warning] [MY-010055] [Server] Query timeout exceeded.
        
        """
    }
    
    static func generateDockerLog() -> String {
        return """
        time="2026-04-22T10:00:01.000000000Z" level=info msg="Docker daemon started"
        time="2026-04-22T10:05:01.000000000Z" level=info msg="Container web-server started"
        time="2026-04-22T10:10:01.000000000Z" level=warning msg="Container memory limit reached"
        
        """
    }
    
    static func generateAPTHistoryLog() -> String {
        return """
        Start-Date: 2026-04-22  10:00:00
        Commandline: apt install nginx
        Install: nginx:amd64 (1.18.0-0ubuntu1)
        End-Date: 2026-04-22  10:00:05
        
        Start-Date: 2026-04-22  11:00:00
        Commandline: apt upgrade
        Upgrade: libssl:amd64 (1.1.1f-1ubuntu2, 1.1.1f-1ubuntu2.15)
        End-Date: 2026-04-22  11:00:10
        
        """
    }
    
    static func generateLogrotateDebug() -> String {
        return """
        considering log /var/log/syslog
        log needs rotating
        rotating log /var/log/syslog
        compressing log with gzip
        
        """
    }
}