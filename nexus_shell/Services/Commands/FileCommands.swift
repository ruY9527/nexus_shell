//
//  FileCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 文件系统命令模拟
enum FileCommands {
    
    static func execute(_ command: String, username: String, currentDir: String) -> String? {
        switch command {
        case "ls":
            return FileGenerator.generateLS(simple: true, showHidden: false)
        case "ls -l":
            return FileGenerator.generateLS(simple: false, showHidden: false, username: username)
        case "ls -la":
            return FileGenerator.generateLS(simple: false, showHidden: true, username: username)
        case "ls -lh":
            return FileGenerator.generateLS(simple: false, showHidden: false, username: username, humanReadable: true)
        case "ls -lha":
            return FileGenerator.generateLS(simple: false, showHidden: true, username: username, humanReadable: true)
        case "ls -a":
            return FileGenerator.generateLS(simple: true, showHidden: true)
        case "pwd":
            return currentDir + "\n"
        case "tree":
            return FileGenerator.generateTree()
        case "tree -L 2":
            return FileGenerator.generateTree(depth: 2)
        case "file /etc/passwd":
            return "/etc/passwd: ASCII text\n"
        case "stat /etc/passwd":
            return FileGenerator.generateStat(path: "/etc/passwd")
        case "basename /etc/passwd":
            return "passwd\n"
        case "dirname /etc/passwd":
            return "/etc\n"
        case "realpath .":
            return currentDir + "\n"
        case "readlink /proc/self":
            return "/proc/12345\n"
        case "ln --help":
            return "Usage: ln [OPTION]... [-T] TARGET LINK_NAME\nCreate hard links or symbolic links.\n"
        case "symlink test":
            return "" // 静默成功
        default:
            return nil
        }
    }
}

/// 文件生成器
enum FileGenerator {
    
    static func generateLS(simple: Bool, showHidden: Bool, username: String = "root", humanReadable: Bool = false) -> String {
        let allFiles = [
            ("Documents", true, 4096),
            ("Downloads", true, 4096),
            ("Projects", true, 4096),
            ("Pictures", true, 4096),
            ("Music", true, 4096),
            ("Videos", true, 4096),
            (".bashrc", false, 1024),
            (".bash_history", false, 2048),
            (".bash_profile", false, 512),
            (".profile", false, 256),
            (".ssh", true, 4096),
            (".vimrc", false, 512),
            ("app.log", false, 8192),
            ("config.conf", false, 1024),
            ("README.md", false, 2048)
        ]
        
        let files = showHidden ? allFiles : allFiles.filter { !$0.1 } // 不隐藏
        
        if simple {
            return files.map { $0.0 }.joined(separator: "  ") + "\n"
        }
        
        let now = Date()
        let total = files.reduce(0) { $0 + $1.2 }
        
        let output = files.map { (name, isDir, size) in
            let perms = isDir ? "drwxr-xr-x" : "-rw-r--r--"
            let sizeStr = humanReadable ? formatSize(size) : "\(size)"
            return "\(perms)  1 \(username) \(username)  \(sizeStr)  \(now.formatted(date: .abbreviated, time: .omitted))  \(name)"
        }.joined(separator: "\n")
        
        return "total \(humanReadable ? formatSize(total) : String(total))\n" + output + "\n"
    }
    
    static func generateLSFiltered(_ pattern: String, username: String) -> String {
        let files = generateLS(simple: false, showHidden: true, username: username)
        return files.split(separator: "\n")
            .filter { $0.contains(pattern) }
            .joined(separator: "\n") + "\n"
    }
    
    static func generateTree(depth: Int = 3) -> String {
        var output = currentDirectory() + "\n"
        output += "├── Documents\n"
        output += "│   ├── report.pdf\n"
        output += "│   └── notes.txt\n"
        output += "├── Downloads\n"
        output += "│   ├── archive.tar.gz\n"
        output += "│   └── installer.sh\n"
        if depth >= 2 {
            output += "├── Projects\n"
            output += "│   ├── src\n"
            if depth >= 3 {
                output += "│   │   ├── main.py\n"
                output += "│   │   └── utils.py\n"
            }
            output += "│   └── tests\n"
        }
        output += "├── .bashrc\n"
        output += "└── .ssh\n"
        output += "    ├── id_rsa\n"
        output += "    └── authorized_keys\n"
        return output
    }
    
    static func generateStat(path: String) -> String {
        return """
        File: \(path)
        Size: 1024        Blocks: 8          IO Block: 4096   regular file
        Device: 801h/2049d      Inode: 12345       Links: 1
        Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
        Access: \(Date().formatted(date: .abbreviated, time: .shortened))
        Modify: \(Date().formatted(date: .abbreviated, time: .shortened))
        Change: \(Date().formatted(date: .abbreviated, time: .shortened))
        
        """
    }
    
    static func generateBashrc(username: String) -> String {
        return """
        # ~/.bashrc: executed by bash(1) for non-login shells.
        
        # If not running interactively, don't do anything
        [ -z "$PS1" ] && return
        
        # don't put duplicate lines or lines starting with space in the history.
        HISTCONTROL=ignoreboth
        
        # append to the history file, don't overwrite it
        shopt -s histappend
        
        # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
        HISTSIZE=1000
        HISTFILESIZE=2000
        
        # check the window size after each command and, if necessary,
        shopt -s checkwinsize
        
        # set variable identifying the chroot you work in
        if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
            debian_chroot=$(cat /etc/debian_chroot)
        fi
        
        # set a fancy prompt (non-color, unless we know we "want" color)
        case "$TERM" in
            xterm-color|*-256color) color_prompt=yes;;
        esac
        
        # Alias definitions.
        if [ -f ~/.bash_aliases ]; then
            . ~/.bash_aliases
        fi
        
        """
    }
    
    private static func formatSize(_ bytes: Int) -> String {
        if bytes >= 1024 * 1024 * 1024 {
            return "\(bytes / (1024 * 1024 * 1024))G"
        } else if bytes >= 1024 * 1024 {
            return "\(bytes / (1024 * 1024))M"
        } else if bytes >= 1024 {
            return "\(bytes / 1024)K"
        }
        return "\(bytes)"
    }
    
    private static func currentDirectory() -> String {
        return "/home/user"
    }
}