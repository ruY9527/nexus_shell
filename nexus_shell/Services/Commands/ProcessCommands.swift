//
//  ProcessCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 进程管理命令模拟
enum ProcessCommands {
    
    static func execute(_ command: String, username: String) -> String? {
        switch command {
        case "ps":
            return ProcessGenerator.generatePSSimple()
        case "ps -ef":
            return ProcessGenerator.generatePSEF(username: username)
        case "ps aux":
            return ProcessGenerator.generatePSAux(username: username)
        case "ps -aux":
            return ProcessGenerator.generatePSAux(username: username)
        case "ps aux --sort=-%cpu":
            return ProcessGenerator.generatePSAuxSortedCPU(username: username)
        case "ps aux --sort=-%mem":
            return ProcessGenerator.generatePSAuxSortedMem(username: username)
        case "pstree":
            return ProcessGenerator.generatePSTree(username: username)
        case "pstree -p":
            return ProcessGenerator.generatePSTreeWithPID(username: username)
        case "pgrep ssh":
            return "1234\n1235\n"
        case "pgrep python":
            return "12346\n"
        case "pgrep nginx":
            return "12347\n12348\n"
        case "pgrep -l ssh":
            return "1234 sshd\n1235 sshd\n"
        case "pgrep -u root":
            return "1\n2\n100\n"
        case "pkill -h":
            return "Usage: pkill [options] <pattern>\nOptions:\n  -e, --echo       echo kill command\n  -l, --list       list name of the process\n  -u, --user       match by user\n"
        case "kill -l":
            return ProcessGenerator.generateKillSignals()
        case "killall -l":
            return ProcessGenerator.generateKillSignals()
        case "strace ls":
            return ProcessGenerator.generateStrace()
        case "ltrace ls":
            return ProcessGenerator.generateLtrace()
        case "pidof sshd":
            return "1234 1235\n"
        case "pidof nginx":
            return "12347\n"
        case "pidof bash":
            return "12345\n"
        default:
            return nil
        }
    }
}

/// 进程生成器
enum ProcessGenerator {
    
    static func generatePSSimple() -> String {
        return """
        PID TTY          TIME CMD
        12345 pts/0    00:00:00 bash
        12346 pts/0    00:00:00 ps
        
        """
    }
    
    static func generatePSEF(username: String) -> String {
        return """
        UID        PID  PPID  C STIME TTY          TIME CMD
        root         1     0  0 10:00 ?        00:00:01 /sbin/init
        root         2     0  0 10:00 ?        00:00:00 [kthreadd]
        root       100     2  0 10:00 ?        00:00:00 [kworker/u4:0]
        root      1234     1  0 10:00 ?        00:00:00 /usr/sbin/sshd
        \(username) 12345  1234  0 10:00 pts/0    00:00:00 bash
        \(username) 12346 12345  0 10:00 pts/0    00:00:00 ps -ef
        
        """
    }
    
    static func generatePSAux(username: String) -> String {
        return """
        USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        root         1  0.0  0.1  10000  1000 ?        Ss   10:00   0:01 /sbin/init
        root         2  0.0  0.0      0     0 ?        S    10:00   0:00 [kthreadd]
        root       100  0.0  0.0      0     0 ?        S    10:00   0:00 [kworker/u4:0]
        root      1234  0.0  0.1  20000  2000 ?        Ss   10:00   0:00 /usr/sbin/sshd -D
        \(username) 12345  0.0  0.1  15000  3500 pts/0   Ss   10:00   0:00 bash
        root      12347  0.2  0.5  50000 10000 ?        S    10:00   0:10 nginx: worker
        \(username) 12346  0.0  0.1  20000  1000 pts/0   R    10:00   0:00 ps aux
        
        """
    }
    
    static func generatePSAuxSortedCPU(username: String) -> String {
        return """
        USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        root      12347  5.2  0.5  50000 10000 ?        R    10:00   0:10 nginx: worker
        \(username) 12346  3.5  0.1  20000  1000 pts/0   R    10:00   0:00 ps aux
        root      12348  2.1  1.0 100000 20000 ?        S    10:00   0:05 python3 app.py
        root         1  0.0  0.1  10000  1000 ?        Ss   10:00   0:01 /sbin/init
        
        """
    }
    
    static func generatePSAuxSortedMem(username: String) -> String {
        return """
        USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        root      12348  2.1  5.0 500000 50000 ?        S    10:00   0:05 docker
        root      12347  0.2  1.0 100000 20000 ?        S    10:00   0:10 python3
        root      12349  0.1  0.5  50000 10000 ?        S    10:00   0:02 nginx: master
        \(username) 12345  0.0  0.1  15000  3500 pts/0   Ss   10:00   0:00 bash
        
        """
    }
    
    static func generatePSAuxFiltered(_ pattern: String) -> String {
        return """
        USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        root      1234  0.0  0.1  20000  2000 ?        Ss   10:00   0:00 /usr/sbin/sshd -D
        root      1235  0.0  0.1  15000  1500 ?        S    10:00   0:00 sshd: \(pattern)
        
        """
    }
    
    static func generatePSAux(lines: Int) -> String {
        var output = """
        USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        
        """
        for i in 0..<lines {
            output += "root      \(i)  0.0  0.0  10000  1000 ?        S    10:00   0:00 process\(i)\n"
        }
        return output
    }
    
    static func generatePSTree(username: String) -> String {
        return """
        systemd─┬─(sd-pam)
               ├─sshd───sshd───bash───pstree
               ├─nginx───nginx
               ├─python3
               └─2*[kworker]
        
        """
    }
    
    static func generatePSTreeWithPID(username: String) -> String {
        return """
        systemd(1)─┬─(sd-pam)(100)
                   ├─sshd(1234)───sshd(1235)───bash(12345)───pstree(12346)
                   ├─nginx(12347)───nginx(12348)
                   ├─python3(12349)
                   └─2*[kworker(50,51)]
        
        """
    }
    
    static func generateKillSignals() -> String {
        return """
        1 HUP      2 INT      3 QUIT    4 ILL      5 TRAP     6 ABRT     7 BUS
        8 FPE      9 KILL    10 USR1   11 SEGV    12 USR2    13 PIPE    14 ALRM
        15 TERM    16 STKFLT  17 CHLD   18 CONT    19 STOP    20 TSTP    21 TTIN
        22 TTOU    23 URG     24 XCPU   25 XFSZ    26 VTALRM  27 PROF    28 WINCH
        29 POLL    30 PWR     31 SYS
        
        """
    }
    
    static func generateStrace() -> String {
        return """
        execve("/usr/bin/ls", ["ls"], 0x7ffd12345678 /* 50 vars */) = 0
        brk(NULL)                               = 0x561234567890
        arch_prctl(0x3001 /* ARCH_??? */, 0x7ffd12345678) = -1 EINVAL (Invalid argument)
        mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7ffd12345678
        access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
        openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
        newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=50000, ...}, AT_EMPTY_PATH) = 0
        mmap(NULL, 50000, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7ffd12345678
        close(3)                                = 0
        exit_group(0)                           = ?
        +++ exited with 0 +++
        
        """
    }
    
    static func generateLtrace() -> String {
        return """
        __libc_start_main(0x401000, 1, 0x7ffd12345678, 0x401200 <unfinished ...>
        setlocale(LC_ALL, "")                                         = "en_US.UTF-8"
        bindtextdomain("ls", "/usr/share/locale")                     = "/usr/share/locale"
        textdomain("ls")                                              = "ls"
        __cxa_atexit(0x401300, 0, 0x7ffd12345678)                      = 0
        malloc(1024)                                                  = 0x561234567890
        free(0x561234567890)                                          = <void>
        exit(0)                                                       = <void>
        +++ exited (status 0) +++
        
        """
    }
}