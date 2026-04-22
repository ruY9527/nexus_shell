//
//  ResourceCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 资源监控命令模拟
enum ResourceCommands {
    
    static func execute(_ command: String) -> String? {
        switch command {
        case "free":
            return ResourceGenerator.generateFree(unit: "KB")
        case "free -h":
            return ResourceGenerator.generateFree(unit: "human")
        case "free -m":
            return ResourceGenerator.generateFree(unit: "MB")
        case "free -g":
            return ResourceGenerator.generateFree(unit: "GB")
        case "free -b":
            return ResourceGenerator.generateFree(unit: "bytes")
        case "df":
            return DiskGenerator.generateDF(unit: "KB")
        case "df -h":
            return DiskGenerator.generateDF(unit: "human")
        case "df -m":
            return DiskGenerator.generateDF(unit: "MB")
        case "df -k":
            return DiskGenerator.generateDF(unit: "KB")
        case "df -i":
            return DiskGenerator.generateDFInodes()
        case "df -T":
            return DiskGenerator.generateDFWithFS()
        case "du":
            return DiskGenerator.generateDU(path: "/home", unit: "KB")
        case "du -h":
            return DiskGenerator.generateDU(path: "/home", unit: "human")
        case "du -sh":
            return DiskGenerator.generateDUSummary(path: "/home")
        case "du -sh /":
            return DiskGenerator.generateDUSummary(path: "/")
        case "du -sh /home":
            return DiskGenerator.generateDUSummary(path: "/home")
        case "du -sh /var":
            return DiskGenerator.generateDUSummary(path: "/var")
        case "du -sh /usr":
            return DiskGenerator.generateDUSummary(path: "/usr")
        case "top":
            return TopGenerator.generate()
        case "top -bn1":
            return TopGenerator.generate()
        case "htop":
            return TopGenerator.generateHTop()
        case "vmstat":
            return ResourceGenerator.generateVMStat()
        case "vmstat 1 5":
            return ResourceGenerator.generateVMStat(interval: 1, count: 5)
        case "iostat":
            return ResourceGenerator.generateIOStat()
        case "iostat -x":
            return ResourceGenerator.generateIOStatExtended()
        case "sar":
            return ResourceGenerator.generateSAR()
        case "sar -u 1 3":
            return ResourceGenerator.generateSARCPU(interval: 1, count: 3)
        case "sar -r 1 3":
            return ResourceGenerator.generateSARMemory(interval: 1, count: 3)
        case "mpstat":
            return ResourceGenerator.generateMPStat()
        case "mpstat -P ALL":
            return ResourceGenerator.generateMPStatAll()
        case "pidstat":
            return ResourceGenerator.generatePIDStat()
        default:
            return nil
        }
    }
}

/// 资源生成器
enum ResourceGenerator {
    
    static func generateFree(unit: String) -> String {
        let header = "              total        used        free      shared  buff/cache   available"
        
        switch unit {
        case "human":
            return """
            \(header)
            Mem:           2.0Gi       1.3Gi       748Mi        50Mi       200Mi       1.4Gi
            Swap:          1.0Gi          0Bi       1.0Gi
            
            """
        case "MB":
            return """
            \(header)
            Mem:           2048        1300         748          50         200        1400
            Swap:          1024           0        1024
            
            """
        case "GB":
            return """
            \(header)
            Mem:              2           1           0           0           0           1
            Swap:             1           0           1
            
            """
        case "bytes":
            return """
            \(header)
            Mem:        2147483648  1363148800   786432000    52428800   209715200  1468006400
            Swap:       1073741824           0  1073741824
            
            """
        default: // KB
            return """
            \(header)
            Mem:        2048000     1300000      748000       50000      200000     1400000
            Swap:       1024000           0     1024000
            
            """
        }
    }
    
    static func generateVMStat(interval: Int = 0, count: Int = 1) -> String {
        let header = "procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----"
        let subHeader = " r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs  us sy id wa st"
        
        var output = "\(header)\n\(subHeader)\n"
        
        for _ in 0..<count {
            let r = Int.random(in: 0...2)
            let b = Int.random(in: 0...1)
            output += " \(r)  \(b)      0 748000  50000 200000    0    0    \(Int.random(in: 0...10))    \(Int.random(in: 0...5))  \(Int.random(in: 100...500))  \(Int.random(in: 200...800))   5  2 92  1  0\n"
        }
        
        return output
    }
    
    static func generateIOStat() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        avg-cpu:  %%user   %%nice %%system %%iowait  %%steal   %%idle
                   5.25    0.00    2.10    0.50     0.00    92.15
        
        Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
        sda               5.00       100.00        50.00        0.00     500000     250000          0
        sdb               0.00         0.00         0.00        0.00          0          0          0
        
        """
    }
    
    static func generateIOStatExtended() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        avg-cpu:  %%user   %%nice %%system %%iowait  %%steal   %%idle
                   5.25    0.00    2.10    0.50     0.00    92.15
        
        Device            r/s     w/s     d/s   rkB/s   wkB/s   dkB/s   rrqm/s   wrqm/s   drqm/s  rrrqm   wrrqm   drrqm  r_await  w_await  d_await  aqu-sz  rareq-sz  wareq-sz  dareq-sz  svctm   %%util
        sda              3.00    2.00    0.00   60.00   40.00    0.00     0.10     0.10     0.00     0.0     0.0     0.0     2.00     3.00     0.00     0.01     20.00     20.00     0.00     1.00     0.50
        sdb              0.00    0.00    0.00    0.00    0.00    0.00     0.00     0.00     0.00     0.0     0.0     0.0     0.00     0.00     0.00     0.00      0.00      0.00      0.00     0.00     0.00
        
        """
    }
    
    static func generateSAR() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        10:00:01 AM     CPU     %%user     %%nice   %%system   %%iowait    %%steal     %%idle
        10:00:02 AM     all      5.25      0.00      2.10      0.50      0.00     92.15
        Average:        all      5.25      0.00      2.10      0.50      0.00     92.15
        
        """
    }
    
    static func generateSARCPU(interval: Int, count: Int) -> String {
        var output = """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        10:00:01 AM     CPU     %%user     %%nice   %%system   %%iowait    %%steal     %%idle
        
        """
        for i in 0..<count {
            let user = Double.random(in: 3...7)
            let system = Double.random(in: 1...3)
            let idle = 100 - user - system - 0.5
            output += "10:00:0\(i+2) AM     all    \(String(format: "%.2f", user))      0.00    \(String(format: "%.2f", system))      0.50      0.00    \(String(format: "%.2f", idle))\n"
        }
        output += "Average:        all      5.25      0.00      2.10      0.50      0.00     92.15\n"
        return output
    }
    
    static func generateSARMemory(interval: Int, count: Int) -> String {
        var output = """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        10:00:01 AM kbmemfree   kbavail   kbmemused  %%memused kbbuffers  kbcached  kbcommit   %%commit  kbactive   kbinact   kbdirty
        
        """
        for i in 0..<count {
            output += "10:00:0\(i+2) AM    748000   1400000    1300000     65.00     50000    200000   1500000     73.00    800000    300000         0\n"
        }
        output += "Average:        748000   1400000    1300000     65.00     50000    200000   1500000     73.00    800000    300000         0\n"
        return output
    }
    
    static func generateMPStat() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        10:00:01 AM  CPU    %%usr    %%nice    %%sys   %%iowait    %%irq   %%soft  %%steal  %%guest   %%gnice   %%idle
        10:00:02 AM  all    5.25    0.00    2.10    0.50    0.00    0.10    0.00    0.00    0.00    92.05
        
        """
    }
    
    static func generateMPStatAll() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        10:00:01 AM  CPU    %%usr    %%nice    %%sys   %%iowait    %%irq   %%soft  %%steal  %%guest   %%gnice   %%idle
        10:00:02 AM  all    5.25    0.00    2.10    0.50    0.00    0.10    0.00    0.00    0.00    92.05
        10:00:02 AM    0    6.00    0.00    2.50    0.50    0.00    0.10    0.00    0.00    0.00    90.90
        10:00:02 AM    1    5.00    0.00    1.80    0.40    0.00    0.10    0.00    0.00    0.00    92.70
        10:00:02 AM    2    5.50    0.00    2.00    0.60    0.00    0.10    0.00    0.00    0.00    91.80
        10:00:02 AM    3    4.50    0.00    2.10    0.50    0.00    0.10    0.00    0.00    0.00    92.80
        
        """
    }
    
    static func generatePIDStat() -> String {
        return """
        Linux 5.15.0-generic (server)   04/22/2026      _x86_64_        (4 CPU)
        
        #      Time   UID       PID    %%usr    %%system    %%guest    %%wait   %%CPU   CPU  minflt/s  majflt/s     VSZ     RSS   %%MEM  StkSize  StkRef   Command
        10:00:01 AM  1000     12345    0.10      0.05      0.00      0.00   0.15     0      1.00      0.00   15000    3500   0.17        0        0   bash
        10:00:01 AM  1000     12346    0.50      0.20      0.00      0.00   0.70     1      5.00      0.00  100000   20000   1.00        0        0   python
        10:00:01 AM     0        100    0.00      0.10      0.00      0.00   0.10     2      0.00      0.00      0        0   0.00        0        0   kworker
        
        """
    }
}

/// Top 生成器
enum TopGenerator {
    
    static func generate(lines: Int = 15) -> String {
        let header = """
        top - \(Date().formatted(date: .omitted, time: .shortened)) up 42 days,  1:23,  2 users,  load average: 0.52, 0.58, 0.45
        Tasks:  85 total,   1 running,  84 sleeping,   0 stopped,   0 zombie
        %Cpu(s):  5.2 us,  2.1 sy,  0.0 ni, 92.5 id,  0.2 wa,  0.0 hi,  0.0 si,  0.0 st
        MiB Mem :   2048.0 total,    748.0 free,   1300.0 used,    200.0 buff/cache
        MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.  1400.0 avail Mem
        
        """
        
        if lines <= 5 { return header }
        
        let processHeader = "  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND\n"
        let processes = """
        12345 root      20   0   15000   3500   2000 R   5.2   0.2   0:00.01 top
        12346 root      20   0  100000  20000  10000 S   3.5   1.0   0:05.23 python
        12347 root      20   0   50000  10000   5000 S   2.1   0.5   0:10.45 nginx
        1     root      20   0   10000   1000    500 S   0.0   0.1   0:00.01 init
        2     root      20   0       0      0      0 S   0.0   0.0   0:00.00 kthreadd
        
        """
        
        return header + processHeader + processes
    }
    
    static func generateHTop() -> String {
        return """
        CPU[                          5.2%] Tasks: 85, 1 thr; 1 running
        Mem[||||||||||||||||||||||  65.0%] Load average: 0.52 0.58 0.45
        Swp[                          0.0%] Uptime: 42 days, 01:23:00
        
        PID USER  PRI NI  VIRT   RES   SHR S CPU% MEM%   TIME+  Command
        12345 root  20  0  15000  3500  2000 R  5.2  0.2  0:00.01 htop
        12346 root  20  0 100000 20000 10000 S  3.5  1.0  0:05.23 python3 app.py
        12347 root  20  0  50000 10000  5000 S  2.1  0.5  0:10.45 nginx: worker
        12348 root  20  0  80000 15000  8000 S  1.8  0.7  0:08.12 docker
        1     root  20  0  10000  1000   500 S  0.0  0.1  0:00.01 /sbin/init
        
        """
    }
}

/// 磁盘生成器
enum DiskGenerator {
    
    static func generateLsblk() -> String {
        return """
        NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
        sda      8:0    0   150G  0 disk
        sda1     8:1    0    50G  0 part /
        sda2     8:2    0   100G  0 part /home
        sdb      8:16   0   500G  0 disk
        sr0     11:0    1  1024M  0 rom
        
        """
    }
    
    static func generateDF(unit: String) -> String {
        let header = "Filesystem     1K-blocks    Used Available Use% Mounted on"
        
        switch unit {
        case "human":
            return """
            \(header)
            /dev/sda1         50G     15G      35G  30% /
            /dev/sda2        100G     45G      55G  45% /home
            /dev/sdb1        500G    200G     300G  40% /data
            tmpfs             2G      0G       2G   0% /dev/shm
            devtmpfs          2G      0G       2G   0% /dev
            
            """
        case "MB":
            return """
            \(header)
            /dev/sda1        51200   15360    35840  30% /
            /dev/sda2       102400   46080    56320  45% /home
            /dev/sdb1       512000  204800   307200  40% /data
            
            """
        default: // KB
            return """
            \(header)
            /dev/sda1       52428800 15728640  36700160  30% /
            /dev/sda2      104857600 47185920  57671680  45% /home
            /dev/sdb1      524288000 209715200 314572800  40% /data
            
            """
        }
    }
    
    static func generateDFInodes() -> String {
        return """
        Filesystem       Inodes    IUsed    IFree IUse% Mounted on
        /dev/sda1        3200000   150000  3050000    5% /
        /dev/sda2        6400000   300000  6100000    5% /home
        /dev/sdb1       32000000  1000000 31000000    3% /data
        
        """
    }
    
    static func generateDFWithFS() -> String {
        return """
        Filesystem     Type     1K-blocks    Used Available Use% Mounted on
        /dev/sda1      ext4      52428800 15728640  36700160  30% /
        /dev/sda2      ext4     104857600 47185920  57671680  45% /home
        /dev/sdb1      ext4     524288000 209715200 314572800  40% /data
        tmpfs          tmpfs       2097152        0   2097152   0% /dev/shm
        
        """
    }
    
    static func generateDFFiltered(_ pattern: String) -> String {
        return generateDF(unit: "human")
    }
    
    static func generateDU(path: String, unit: String) -> String {
        switch unit {
        case "human":
            return """
            4.0K    \(path)/.bashrc
            2.0K    \(path)/.bash_profile
            50M     \(path)/Documents
            100M    \(path)/Downloads
            200M    \(path)/Projects
            350M    \(path)
            
            """
        default:
            return """
            4       \(path)/.bashrc
            2       \(path)/.bash_profile
            50000   \(path)/Documents
            100000  \(path)/Downloads
            200000  \(path)/Projects
            350000  \(path)
            
            """
        }
    }
    
    static func generateDUSummary(path: String) -> String {
        switch path {
        case "/":
            return "15G     /\n"
        case "/home":
            return "350M    /home\n"
        case "/var":
            return "2.5G    /var\n"
        case "/usr":
            return "5.0G    /usr\n"
        case "/opt":
            return "1.0G    /opt\n"
        case "/tmp":
            return "50M     /tmp\n"
        default:
            return "100M    \(path)\n"
        }
    }
    
    static func generateFstab() -> String {
        return """
        # /etc/fstab: static file system information.
        #
        # <file system> <mount point>   <type>  <options>       <dump>  <pass>
        /dev/sda1       /               ext4    errors=remount-ro 0       1
        /dev/sda2       /home           ext4    defaults        0       2
        /dev/sdb1       /data           ext4    defaults        0       2
        tmpfs           /dev/shm        tmpfs   defaults        0       0
        
        """
    }
    
    static func generateMounts() -> String {
        return """
        /dev/sda1 / ext4 rw,errors=remount-ro 0 0
        /dev/sda2 /home ext4 rw 0 0
        /dev/sdb1 /data ext4 rw 0 0
        proc /proc proc rw,noexec,nosuid,nodev 0 0
        sysfs /sys sysfs rw,noexec,nosuid,nodev 0 0
        devpts /dev/pts devpts rw,noexec,nosuid,gid=5,mode=620 0 0
        tmpfs /run tmpfs rw,noexec,nosuid,size=10%,mode=755 0 0
        tmpfs /dev/shm tmpfs rw 0 0
        
        """
    }
}