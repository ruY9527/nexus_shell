//
//  PackageCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/23.
//

import Foundation

/// 包管理命令模拟
enum PackageCommands {

    static func execute(_ command: String) -> String? {
        switch command {
        case "apt", "apt-get":
            return PackageGenerator.generateAPTHelp()
        case "apt update", "apt-get update":
            return PackageGenerator.generateAPTUpdate()
        case "apt upgrade", "apt-get upgrade":
            return PackageGenerator.generateAPTUpgrade()
        case "apt list --installed":
            return PackageGenerator.generateAPTListInstalled()
        case "apt list --upgradable":
            return PackageGenerator.generateAPTListUpgradable()
        case "dpkg -l":
            return PackageGenerator.generateDPKGList()
        case "dpkg -i":
            return "dpkg: error: --install needs at least one package file name argument\n"
        case "yum":
            return PackageGenerator.generateYUMHelp()
        case "yum update":
            return PackageGenerator.generateYUMUpdate()
        case "yum list installed":
            return PackageGenerator.generateYUMListInstalled()
        case "dnf":
            return PackageGenerator.generateDNFHelp()
        case "dnf update":
            return PackageGenerator.generateDNFUpdate()
        case "dnf list installed":
            return PackageGenerator.generateYUMListInstalled()
        case "snap list":
            return PackageGenerator.generateSnapList()
        case "pip list", "pip3 list":
            return PackageGenerator.generatePipList()
        case "pip --version", "pip3 --version":
            return "pip 22.0.2 from /usr/lib/python3/dist-packages/pip (python 3.10)\n"
        case "npm --version":
            return "8.19.2\n"
        case "npm list":
            return PackageGenerator.generateNPMList()
        default:
            if command.hasPrefix("apt install ") || command.hasPrefix("apt-get install ") {
                let pkg = command.split(separator: " ").last ?? ""
                return PackageGenerator.generateAPTInstall(String(pkg))
            }
            if command.hasPrefix("apt remove ") || command.hasPrefix("apt-get remove ") {
                let pkg = command.split(separator: " ").last ?? ""
                return PackageGenerator.generateAPTRemove(String(pkg))
            }
            if command.hasPrefix("yum install ") || command.hasPrefix("dnf install ") {
                let pkg = command.split(separator: " ").last ?? ""
                return PackageGenerator.generateYUMInstall(String(pkg))
            }
            if command.hasPrefix("pip install ") || command.hasPrefix("pip3 install ") {
                let pkg = command.split(separator: " ").last ?? ""
                return PackageGenerator.generatePipInstall(String(pkg))
            }
            return nil
        }
    }
}

/// 包管理命令输出生成器
enum PackageGenerator {

    static func generateAPTHelp() -> String {
        return """
        apt 2.4.5 (amd64)
        Usage: apt [options] command

        Commands:
          install    - Install new packages
          remove     - Remove packages
          purge      - Remove packages and their configuration files
          update     - Update package list
          upgrade    - Upgrade the system
          list       - List packages
          search     - Search for packages
          show       - Show package details

        """
    }

    static func generateAPTUpdate() -> String {
        return """
        Get:1 http://security.ubuntu.com/ubuntu jammy-security InRelease [110 kB]
        Get:2 http://archive.ubuntu.com/ubuntu jammy InRelease [270 kB]
        Get:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [109 kB]
        Reading package lists... Done

        """
    }

    static func generateAPTUpgrade() -> String {
        return """
        Reading package lists... Done
        Calculating upgrade... Done
        The following packages will be upgraded:
          libssl1.1 openssl
        2 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
        Need to get 1,234 kB of archives.
        After this operation, 512 kB of additional disk space will be used.
        Do you want to continue? [Y/n]

        """
    }

    static func generateAPTInstall(_ pkg: String) -> String {
        return """
        Reading package lists... Done
        Building dependency tree... Done
        Reading state information... Done
        The following NEW packages will be installed:
          \(pkg)
        0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
        Need to get 0 B/123 kB of archives.
        After this operation, 456 kB of additional disk space will be used.
        Selecting previously unselected package \(pkg).
        Unpacking \(pkg) (1.0.0) ...
        Setting up \(pkg) (1.0.0) ...

        """
    }

    static func generateAPTRemove(_ pkg: String) -> String {
        return """
        Reading package lists... Done
        Building dependency tree... Done
        Reading state information... Done
        The following packages will be REMOVED:
          \(pkg)
        0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
        After this operation, 456 kB disk space will be freed.
        Do you want to continue? [Y/n]

        """
    }

    static func generateAPTListInstalled() -> String {
        return """
        Listing... Done
        adduser/jammy,now 3.118ubuntu5 all [installed,automatic]
        apt/jammy,now 2.4.5 amd64 [installed]
        bash/jammy,now 5.1-6ubuntu1 amd64 [installed]
        coreutils/jammy,now 8.32-4.1ubuntu1 amd64 [installed]
        curl/jammy,now 7.81.0-1ubuntu1.10 amd64 [installed]
        git/jammy,now 2.34.1-1ubuntu1.10 amd64 [installed]
        nginx/jammy,now 1.18.0-0ubuntu1.3 amd64 [installed]
        openssh-server/jammy,now 8.9p1-3ubuntu0.1 amd64 [installed]
        python3/jammy,now 3.10.6-1~22.04 amd64 [installed,automatic]

        """
    }

    static func generateAPTListUpgradable() -> String {
        return """
        Listing... Done
        libssl1.1/jammy-security 1.1.1f-1ubuntu2.16 amd64 [upgradable from: 1.1.1f-1ubuntu2.15]
        openssl/jammy-security 1.1.1f-1ubuntu2.16 amd64 [upgradable from: 1.1.1f-1ubuntu2.15]

        """
    }

    static func generateDPKGList() -> String {
        return """
        Desired=Unknown/Install/Remove/Purge/Hold
        | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
        |/ Err?=(none)/reinst-required/(Status,Err: uppercase=bad)
        || Name           Version        Architecture Description
        +++-==============-==============-============-=================================
        ii  adduser        3.118ubuntu5   all          add and remove users and groups
        ii  apt            2.4.5          amd64        commandline package manager
        ii  bash           5.1-6ubuntu1   amd64        GNU Bourne Again SHell
        ii  coreutils      8.32-4.1ubuntu1 amd64       GNU core utilities
        ii  curl           7.81.0-1ubuntu1.10 amd64    command line tool for transferring data with URL syntax
        ii  git            2.34.1-1ubuntu1.10 amd64    fast, scalable, distributed revision control system
        ii  nginx          1.18.0-0ubuntu1.3 amd64     small, powerful, scalable web/proxy server
        ii  openssh-server 8.9p1-3ubuntu0.1 amd64      secure shell (SSH) server

        """
    }

    static func generateYUMHelp() -> String {
        return """
        Loaded plugins: fastestmirror
        Usage: yum [options] COMMAND

        List of Commands:
          check          Check for problems in the rpmdb
          check-update   Check for available package updates
          clean          Remove cached data
          deplist        List a package's dependencies
          downgrade      downgrade a package
          erase          Remove a package or packages from your system
          group          Display, or use, the groups information
          help           Display a helpful usage message
          history        Display or use the transaction history
          info           Display details about a package or group of packages
          install        Install a package or packages on your system
          list           List a package or groups of packages
          makecache      Generate the metadata cache
          provides       Find what package provides a given value
          reinstall      reinstall a package
          remove         Remove a package or packages from your system
          repolist       List the enabled repositories
          search         Search package details for the given string
          update         Update a package or packages on your system
          upgrade        Update packages taking obsoletes into account

        """
    }

    static func generateYUMUpdate() -> String {
        return """
        Loaded plugins: fastestmirror
        Loading mirror speeds from cached hostfile
         * base: mirror.centos.org
         * updates: mirror.centos.org
         * extras: mirror.centos.org
        No packages marked for update

        """
    }

    static func generateYUMInstall(_ pkg: String) -> String {
        return """
        Loaded plugins: fastestmirror
        Loading mirror speeds from cached hostfile
         * base: mirror.centos.org
        Resolving Dependencies
        --> Running transaction check
        ---> Package \(pkg).x86_64 0:1.0.0 will be installed
        --> Finished Dependency Resolution

        Dependencies Resolved

        ================================================================================
         Package          Arch            Version          Repository       Size
        ================================================================================
        Installing:
         \(pkg)           x86_64          1.0.0            base            123 k

        Transaction Summary
        ================================================================================
        Install  1 Package

        Total download size: 123 k
        Installed size: 456 k
        Downloading packages:
        \(pkg)-1.0.0.x86_64.rpm                       |  123 kB  00:00:01
        Running transaction check
        Running transaction test
        Transaction test succeeded
        Running transaction
          Installing : \(pkg)-1.0.0.x86_64                          1/1
          Verifying  : \(pkg)-1.0.0.x86_64                          1/1

        Installed:
          \(pkg).x86_64 0:1.0.0

        Complete!

        """
    }

    static func generateYUMListInstalled() -> String {
        return """
        Loaded plugins: fastestmirror
        Installed Packages
        bash.x86_64                        4.2.46-34.el7               @base
        coreutils.x86_64                   8.22-24.el7                 @base
        curl.x86_64                        7.29.0-59.el7               @base
        git.x86_64                         1.8.3.1-23.el7              @base
        nginx.x86_64                       1.20.1-10.el7               @epel
        openssh-server.x86_64              7.4p1-21.el7                @base
        python3.x86_64                     3.6.8-18.el7                @updates

        """
    }

    static func generateDNFHelp() -> String {
        return """
        DNF version: 4.2.7
        Usage: dnf [options] COMMAND

        List of Commands:
          alias         List or create command aliases
          autoremove    Remove all packages that were installed only as dependencies
          check-update  Check for available package upgrades
          clean         Remove cached data
          distro-sync   Synchronize installed packages to the latest available versions
          downgrade     Downgrade a package
          group         Display, or use, the groups information
          help          Display a helpful usage message
          history        Display, or use, the transaction history
          info          Display details about a package or group of packages
          install       Install a package or packages on your system
          list          List all packages known to DNF
          makecache     Generate the metadata cache
          mark          Mark packages for installation or removal
          module        Manage modules
          reinstall      reinstall a package
          remove        Remove a package or packages from your system
          repolist      Display the list of enabled repositories
          repoquery     Search for packages matching the specified criteria
          search        Search package details for the given string
          update        Update packages taking obsoletes into account
          upgrade       Upgrade packages

        """
    }

    static func generateDNFUpdate() -> String {
        return """
        Last metadata expiration check: 0:23:45 ago on Mon Apr 22 10:00:00 2026.
        Dependencies resolved.
        Nothing to do.
        Complete!

        """
    }

    static func generateSnapList() -> String {
        return """
        Name    Version   Rev    Tracking       Publisher   Notes
        core    16-2.58   12941  latest/stable  canonical✓  core
        lxd     5.0.0     24321  latest/stable  canonical✓  -
        snapd   2.58      19122  latest/stable  canonical✓  snapd

        """
    }

    static func generatePipList() -> String {
        return """
        Package          Version
        ---------------- -------
        pip              22.0.2
        setuptools       59.6.0
        wheel            0.37.1
        requests         2.28.1
        flask            2.2.2
        django           4.1.3
        numpy            1.23.5
        pandas           1.5.2

        """
    }

    static func generatePipInstall(_ pkg: String) -> String {
        return """
        Collecting \(pkg)
          Downloading \(pkg)-1.0.0-py3-none-any.whl (123 kB)
             ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 123.0/123.0 kB 5.2 MB/s eta 0:00:00
        Installing collected packages: \(pkg)
        Successfully installed \(pkg)-1.0.0

        """
    }

    static func generateNPMList() -> String {
        return """
        /usr/local/lib
        ├── express@4.18.2
        ├── lodash@4.17.21
        ├── moment@2.29.4
        ├── react@18.2.0
        └── webpack@5.75.0

        """
    }
}