//
//  SystemCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 系统信息命令模拟
enum SystemCommands {
    
    static func execute(_ command: String, host: String, username: String) -> String? {
        switch command {
        case "uname":
            return "Linux\n"
        case "uname -a":
            return SystemInfoGenerator.generateUnameAll(host: host)
        case "uname -r":
            return "5.15.0-generic\n"
        case "uname -m":
            return "x86_64\n"
        case "uname -s":
            return "Linux\n"
        case "hostname":
            return (host.components(separatedBy: ".").first ?? host) + "\n"
        case "hostname -f":
            return host + "\n"
        case "hostname -I":
            return "192.168.1.100 10.0.0.1\n"
        case "uptime":
            return SystemInfoGenerator.generateUptime()
        case "date":
            return Date().formatted(date: .complete, time: .complete) + "\n"
        case "date +%Y-%m-%d":
            return Date().formatted(.iso8601) + "\n"
        case "date +%H:%M:%S":
            return Date().formatted(date: .omitted, time: .shortened) + "\n"
        case "cal":
            return SystemInfoGenerator.generateCalendar()
        case "timedatectl":
            return SystemInfoGenerator.generateTimedatectl()
        case "whoami":
            return username + "\n"
        case "id":
            return "uid=1000(\(username)) gid=1000(\(username)) groups=1000(\(username)),4(adm),27(sudo)\n"
        case "groups":
            return "adm sudo \(username)\n"
        case "w":
            return UserGenerator.generateW(username: username)
        case "who":
            return UserGenerator.generateWho(username: username)
        case "users":
            return username + "\n"
        case "last":
            return UserGenerator.generateLast(username: username)
        case "last -n 5":
            return UserGenerator.generateLast(username: username, limit: 5)
        case "lastlog":
            return UserGenerator.generateLastLog(username: username)
        case "lscpu":
            return SystemInfoGenerator.generateLscpu()
        case "lsblk":
            return DiskGenerator.generateLsblk()
        case "lsmem":
            return SystemInfoGenerator.generateLsmem()
        case "arch":
            return "x86_64\n"
        case "nproc":
            return "4\n"
        case "getconf LONG_BIT":
            return "64\n"
        case "printenv", "env":
            return SystemInfoGenerator.generateEnv(username: username)
        case "echo $PATH":
            return "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n"
        case "echo $HOME":
            return "/home/\(username)\n"
        case "echo $USER":
            return username + "\n"
        case "echo $SHELL":
            return "/bin/bash\n"
        case "echo $LANG":
            return "en_US.UTF-8\n"
        case "echo $PWD":
            return "/home/\(username)\n"
        case "echo $HOSTNAME":
            return (host.components(separatedBy: ".").first ?? host) + "\n"
        case "locale":
            return SystemInfoGenerator.generateLocale()
        case "locale -a":
            return "C\nC.UTF-8\nen_US.utf8\nPOSIX\n"
        default:
            return nil
        }
    }
}

/// 系统信息生成器
enum SystemInfoGenerator {
    
    static func generateUnameAll(host: String) -> String {
        return "Linux \(host) 5.15.0-generic #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux\n"
    }
    
    static func generateUptime() -> String {
        let now = Date()
        return " \(now.formatted(date: .omitted, time: .shortened)) up 42 days,  1:23,  2 users,  load average: 0.52, 0.58, 0.45\n"
    }
    
    static func generateCalendar() -> String {
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        return """
            \(monthName(month)) \(year)
        Su Mo Tu We Th Fr Sa
           1  2  3  4  5  6
        7  8  9 10 11 12 13
        14 15 16 17 18 19 20
        21 22 23 24 25 26 27
        28 29 30
        
        """
    }
    
    static func generateTimedatectl() -> String {
        return """
               Local time: \(Date().formatted(date: .complete, time: .complete))
           Universal time: \(Date().formatted(date: .complete, time: .complete))
                 RTC time: \(Date().formatted(date: .abbreviated, time: .shortened))
                Time zone: UTC (UTC, +0000)
        System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no

        """
    }
    
    static func generateLscpu() -> String {
        return """
        Architecture:            x86_64
          CPU op-mode(s):        32-bit, 64-bit
          Address sizes:         46 bits physical, 48 bits virtual
          Byte Order:            Little Endian
        CPU(s):                  4
          On-line CPU(s) list:   0-3
          Vendor ID:             GenuineIntel
          Model name:            Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
            CPU family:          6
            Model:               142
            Thread(s) per core:  2
            Core(s) per socket:  2
            Socket(s):           1
            Stepping:            4
            CPU max MHz:         4000.0000
            CPU min MHz:         400.0000
            BogoMIPS:            3999.00
        Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon nopl xtopology tsc_reliable nonstop_tsc cpuid pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single pti ssbd ibrs ibpb stibp fsgsbase tsc_adjust bmi1 avx2 smep bmi2 invpcid mpx rdseed adx smap clflushopt xsaveopt xsavec xsaves arat md_clear flush_l1d arch_capabilities
        Virtualization:         VT-x
        Hypervisor vendor:      KVM
        Virtualization type:    full
        Caches (sum of all):    
          L1d:                   64 KiB (2 instances)
          L1i:                   64 KiB (2 instances)
          L2:                    512 KiB (2 instances)
          L3:                    4 MiB (1 instance)
        NUMA:                    
          NUMA node(s):          1
          NUMA node0 CPU(s):     0-3
        
        """
    }
    
    static func generateLsmem() -> String {
        return """
        RANGE                                  SIZE  STATE  REMOVABLE  BLOCK
        0x0000000000000000-0x0000000007ffffff  128M  online    no      0
        0x0000000008000000-0x000000000fffffff  128M  online    no      1
        0x0000000010000000-0x0000000017ffffff  128M  online    no      2
        0x0000000018000000-0x000000001fffffff  128M  online    no      3
        
        Memory block size:       128M
        Total online memory:     512M
        Total offline memory:    0B
        
        """
    }
    
    static func generateCPUInfo() -> String {
        return """
        processor       : 0
        vendor_id       : GenuineIntel
        cpu family      : 6
        model           : 142
        model name      : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
        stepping        : 4
        microcode       : 0x96
        cpu MHz         : 2000.000
        cache size      : 8192 KB
        physical id     : 0
        
        """
    }
    
    static func generateFullCPUInfo() -> String {
        var output = ""
        for i in 0..<4 {
            output += """
            processor       : \(i)
            vendor_id       : GenuineIntel
            cpu family      : 6
            model           : 142
            model name      : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
            stepping        : 4
            microcode       : 0x96
            cpu MHz         : 2000.000
            cache size      : 8192 KB
            physical id     : 0
            siblings        : 4
            core id         : \(i / 2)
            cpu cores       : 2
            apicid          : \(i)
            initial apicid  : \(i)
            fpu             : yes
            fpu_exception   : yes
            cpuid level     : 22
            wp              : yes
            flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon nopl xtopology tsc_reliable nonstop_tsc cpuid pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch cpuid_fault invpcid_single pti ssbd ibrs ibpb stibp fsgsbase tsc_adjust bmi1 avx2 smep bmi2 invpcid mpx rdseed adx smap clflushopt xsaveopt xsavec xsaves arat md_clear flush_l1d arch_capabilities
            bugs            : cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit srbds mmio_stale_data
            bogomips        : 3999.00
            clflush size    : 64
            cache_alignment : 64
            address sizes   : 46 bits physical, 48 bits virtual
            power management:
            
            """
        }
        return output
    }
    
    static func generateMemInfo() -> String {
        return """
        MemTotal:       2048000 kB
        MemFree:         748000 kB
        MemAvailable:    1400000 kB
        
        """
    }
    
    static func generateFullMemInfo() -> String {
        return """
        MemTotal:       2048000 kB
        MemFree:         748000 kB
        MemAvailable:    1400000 kB
        Buffers:          50000 kB
        Cached:          200000 kB
        SwapCached:            0 kB
        Active:          800000 kB
        Inactive:        300000 kB
        Active(anon):    600000 kB
        Inactive(anon):  100000 kB
        Active(file):    200000 kB
        Inactive(file):  200000 kB
        Unevictable:           0 kB
        Mlocked:               0 kB
        SwapTotal:      1024000 kB
        SwapFree:       1024000 kB
        Dirty:               0 kB
        Writeback:           0 kB
        AnonPages:      700000 kB
        Mapped:          100000 kB
        Shmem:            50000 kB
        KReclaimable:     30000 kB
        Slab:             60000 kB
        SReclaimable:     30000 kB
        SUnreclaim:       30000 kB
        KernelStack:       4000 kB
        PageTables:        8000 kB
        NFS_Unstable:          0 kB
        Bounce:                0 kB
        WritebackTmp:          0 kB
        CommitLimit:    2048000 kB
        Committed_AS:   1500000 kB
        VmallocTotal:   34359738367 kB
        VmallocUsed:       2000 kB
        VmallocChunk:          0 kB
        Percpu:             500 kB
        HardwareCorrupted:     0 kB
        AnonHugePages:         0 kB
        ShmemHugePages:        0 kB
        ShmemPmdMapped:        0 kB
        FileHugePages:         0 kB
        FilePmdMapped:         0 kB
        HugePages_Total:       0
        HugePages_Free:        0
        HugePages_Rsvd:        0
        HugePages_Surp:        0
        Hugepagesize:       2048 kB
        Hugetlb:               0 kB
        DirectMap4k:      50000 kB
        DirectMap2M:     2000000 kB
        DirectMap1G:           0 kB
        
        """
    }
    
    static func generateOSRelease() -> String {
        return """
        PRETTY_NAME="Ubuntu 22.04.3 LTS"
        NAME="Ubuntu"
        VERSION_ID="22.04"
        VERSION="22.04.3 LTS (Jammy Jellyfish)"
        ID=ubuntu
        ID_LIKE=debian
        HOME_URL="https://www.ubuntu.com/"
        SUPPORT_URL="https://help.ubuntu.com/"
        BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
        PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
        UBUNTU_CODENAME=jammy
        
        """
    }
    
    static func generateProcVersion() -> String {
        return "Linux version 5.15.0-generic (builder@buildhost) (gcc (Ubuntu 11.2.0-19ubuntu1) 11.2.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #1 SMP PREEMPT_DYNAMIC x86_64\n"
    }
    
    static func generateEnv(username: String) -> String {
        return """
        SHELL=/bin/bash
        TERM=xterm-256color
        USER=\(username)
        HOME=/home/\(username)
        LOGNAME=\(username)
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        LANG=en_US.UTF-8
        LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:
        MAIL=/var/mail/\(username)
        SSH_TTY=/dev/pts/0
        SSH_CONNECTION=192.168.1.1 54321 192.168.1.100 22
        XDG_SESSION_ID=123
        XDG_RUNTIME_DIR=/run/user/1000
        XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop
        LESSOPEN=| /usr/bin/lesspipe %s
        LESSCLOSE=/usr/bin/lesspipe %s %s
        _=/usr/bin/env
        
        """
    }
    
    static func generateLocale() -> String {
        return """
        LANG=en_US.UTF-8
        LANGUAGE=en_US:en
        LC_CTYPE="en_US.UTF-8"
        LC_NUMERIC="en_US.UTF-8"
        LC_TIME="en_US.UTF-8"
        LC_COLLATE="en_US.UTF-8"
        LC_MONETARY="en_US.UTF-8"
        LC_MESSAGES="en_US.UTF-8"
        LC_PAPER="en_US.UTF-8"
        LC_NAME="en_US.UTF-8"
        LC_ADDRESS="en_US.UTF-8"
        LC_TELEPHONE="en_US.UTF-8"
        LC_MEASUREMENT="en_US.UTF-8"
        LC_IDENTIFICATION="en_US.UTF-8"
        LC_ALL=
        
        """
    }
    
    private static func monthName(_ month: Int) -> String {
        let months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        return months[month - 1]
    }
}