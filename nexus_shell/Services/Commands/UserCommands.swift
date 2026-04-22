//
//  UserCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 用户管理命令模拟
enum UserCommands {
    
    static func execute(_ command: String, username: String, homeDirectory: String) -> String? {
        switch command {
        case "passwd":
            return "Changing password for \(username).\n(current) UNIX password: \n"
        case "passwd --status":
            return "\(username) P 04/22/2026 0 99999 7 -1\n"
        case "useradd":
            return "Usage: useradd [options] LOGIN\n"
        case "useradd testuser":
            return "" // 静默成功
        case "useradd -m testuser":
            return "" // 静默成功
        case "userdel":
            return "Usage: userdel [options] LOGIN\n"
        case "userdel testuser":
            return "" // 静默成功
        case "userdel -r testuser":
            return "" // 靜默成功
        case "usermod":
            return "Usage: usermod [options] LOGIN\n"
        case "usermod -aG sudo testuser":
            return "" // 靜默成功
        case "groupadd":
            return "Usage: groupadd [options] GROUP\n"
        case "groupadd developers":
            return "" // 靜默成功
        case "groupdel":
            return "Usage: groupdel [options] GROUP\n"
        case "groupdel developers":
            return "" // 靜默成功
        case "groups":
            return "adm sudo \(username)\n"
        case "groups root":
            return "root\n"
        case "getent passwd":
            return UserGenerator.generatePasswd(username: username)
        case "getent group":
            return UserGenerator.generateGroup(username: username)
        case "getent shadow":
            return "Permission denied. You must be root.\n"
        case "newgrp":
            return "Usage: newgrp [-] [group]\n"
        case "su":
            return "Password: \n"
        case "su -":
            return "Password: \n"
        case "su root":
            return "Password: \n"
        case "sudo":
            return "usage: sudo -h | -K | -k | -V\n"
        case "sudo -l":
            return UserGenerator.generateSudoList(username: username)
        case "sudo whoami":
            return "root\n"
        case "sudo -u root whoami":
            return "root\n"
        case "chage":
            return "Usage: chage [options] LOGIN\n"
        case "chage -l":
            return UserGenerator.generateChageList(username: username)
        case "chage -l root":
            return UserGenerator.generateChageList(username: "root")
        case "finger":
            return UserGenerator.generateFinger(username: username)
        case "finger root":
            return UserGenerator.generateFinger(username: "root")
        case "login":
            return "login: "
        case "logout":
            return "logout\n"
        case "exit":
            return "logout\n"
        case "users":
            return username + "\n"
        case "who -a":
            return UserGenerator.generateWhoAll(username: username)
        case "who -b":
            return "system boot  \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        case "who -H":
            return UserGenerator.generateWhoWithHeader(username: username)
        case "who -q":
            return "\(username)\n# users=1\n"
        case "who -r":
            return "run-level 5 \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        default:
            return nil
        }
    }
}

/// 用户生成器
enum UserGenerator {
    
    static func generatePasswd(username: String) -> String {
        return """
        root:x:0:0:root:/root:/bin/bash
        daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
        bin:x:2:2:bin:/bin:/usr/sbin/nologin
        sys:x:3:3:sys:/dev:/usr/sbin/nologin
        sync:x:4:65534:sync:/bin:/bin/sync
        games:x:5:60:games:/usr/games:/usr/sbin/nologin
        \(username):x:1000:1000:\(username):/home/\(username):/bin/bash
        nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
        
        """
    }
    
    static func generateGroup(username: String) -> String {
        return """
        root:x:0:
        daemon:x:1:
        bin:x:2:
        sys:x:3:
        adm:x:4:\(username)
        sudo:x:27:\(username)
        \(username):x:1000:
        
        """
    }
    
    static func generateHistory() -> String {
        return """
            1  ls -la
            2  pwd
            3  cd /var/log
            4  tail -f syslog
            5  cat /etc/passwd
            6  grep ERROR syslog
            7  systemctl status nginx
            8  docker ps -a
            9  vim /etc/nginx/nginx.conf
           10  reboot
        
        """
    }
    
    static func generateW(username: String) -> String {
        return """
        \(Date().formatted(date: .omitted, time: .shortened)) up 42 days,  1:23,  2 users,  load average: 0.52, 0.58, 0.45
        USER     TTY        FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
        \(username) pts/0     192.168.1.1      10:00    0.00s  0.05s  0.01s w
        
        """
    }
    
    static func generateWho(username: String) -> String {
        return """
        \(username) pts/0        \(Date().formatted(date: .abbreviated, time: .shortened)) (192.168.1.1)
        
        """
    }
    
    static func generateWhoAll(username: String) -> String {
        return """
        \(username) pts/0        \(Date().formatted(date: .abbreviated, time: .shortened)) (192.168.1.1)
        system boot  \(Date().formatted(date: .abbreviated, time: .shortened))
        
        """
    }
    
    static func generateWhoWithHeader(username: String) -> String {
        return """
        NAME     LINE         TIME             COMMENT
        \(username) pts/0        \(Date().formatted(date: .abbreviated, time: .shortened)) (192.168.1.1)
        
        """
    }
    
    static func generateLast(username: String, limit: Int = 10) -> String {
        var output = username + "   pts/0        192.168.1.1      \(Date().formatted(date: .abbreviated, time: .shortened))   still logged in\n"
        output += "reboot   system boot  5.15.0-generic   \(Date().formatted(date: .abbreviated, time: .shortened))   still running\n"
        output += "\nwtmp begins \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        return output
    }
    
    static func generateLastLog(username: String) -> String {
        return """
        Username         Port     From             Latest
        root             pts/0    192.168.1.1      \(Date().formatted(date: .abbreviated, time: .shortened))
        \(username)             pts/0    192.168.1.1      \(Date().formatted(date: .abbreviated, time: .shortened))
        daemon           **Never logged in**
        bin              **Never logged in**
        
        """
    }
    
    static func generateSudoList(username: String) -> String {
        return """
        Matching Defaults entries for \(username) on server:
            env_reset, mail_badpass
        
        User \(username) may run the following commands on server:
            (ALL : ALL) ALL
        
        """
    }
    
    static func generateChageList(username: String) -> String {
        return """
        Last password change                                    : Apr 22, 2026
        Password expires                                        : never
        Password inactive                                       : never
        Account expires                                         : never
        Minimum number of days between password change          : 0
        Maximum number of days between password change          : 99999
        Number of days of warning before password expires       : 7
        
        """
    }
    
    static func generateFinger(username: String) -> String {
        return """
        Login: \(username)                             Name: \(username)
        Directory: /home/\(username)                   Shell: /bin/bash
        On since \(Date().formatted(date: .abbreviated, time: .shortened)) on pts/0 from 192.168.1.1
        No mail.
        No Plan.
        
        """
    }
}