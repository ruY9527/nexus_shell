//
//  UtilityCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/23.
//

import Foundation

/// 实用工具命令模拟
enum UtilityCommands {

    static func execute(_ command: String, username: String, homeDirectory: String) -> String? {
        // 压缩工具
        if let output = handleCompressionCommands(command) {
            return output
        }

        // SSH 相关
        if let output = handleSSHCommands(command, username: username, homeDirectory: homeDirectory) {
            return output
        }

        // 系统工具
        if let output = handleSystemUtilityCommands(command, username: username) {
            return output
        }

        // 文本处理
        if let output = handleTextProcessingCommands(command) {
            return output
        }

        // 编码/校验
        if let output = handleEncodingCommands(command) {
            return output
        }

        return nil
    }

    // MARK: - Compression Commands

    private static func handleCompressionCommands(_ command: String) -> String? {
        switch command {
        case "tar":
            return UtilityGenerator.generateTarHelp()
        case "tar --help":
            return UtilityGenerator.generateTarHelp()
        case "tar -cvf archive.tar file1 file2":
            return UtilityGenerator.generateTarCreate()
        case "tar -czvf archive.tar.gz file1 file2":
            return UtilityGenerator.generateTarGzipCreate()
        case "tar -xzvf archive.tar.gz":
            return UtilityGenerator.generateTarGzipExtract()
        case "tar -tvf archive.tar":
            return UtilityGenerator.generateTarList()
        case "tar -tzvf archive.tar.gz":
            return UtilityGenerator.generateTarGzipList()
        case "gzip":
            return "Usage: gzip [OPTION]... [FILE]...\nCompress files using Lempel-Ziv coding (LZ77).\n"
        case "gzip --help":
            return UtilityGenerator.generateGzipHelp()
        case "gzip -k file.txt":
            return "file.txt: 50.0% -- replaced with file.txt.gz\n"
        case "gzip -d file.txt.gz":
            return "" // 静默成功
        case "gunzip file.txt.gz":
            return "" // 静默成功
        case "zip":
            return "Usage: zip [OPTIONS]... [ZIPFILE] [FILES]...\n"
        case "zip -r archive.zip folder":
            return UtilityGenerator.generateZipCreate()
        case "zip archive.zip file1 file2":
            return UtilityGenerator.generateZipCreateFiles()
        case "unzip":
            return "Usage: unzip [OPTIONS]... ZIPFILE\n"
        case "unzip archive.zip":
            return UtilityGenerator.generateUnzip()
        case "unzip -l archive.zip":
            return UtilityGenerator.generateUnzipList()
        case "bzip2":
            return "Usage: bzip2 [OPTION]... [FILE]...\n"
        case "bzip2 -k file.txt":
            return "file.txt: 45.0% -- replaced with file.txt.bz2\n"
        case "bunzip2 file.txt.bz2":
            return "" // 静默成功
        case "xz":
            return "Usage: xz [OPTION]... [FILE]...\n"
        case "xz -k file.txt":
            return "file.txt: 40.0% -- replaced with file.txt.xz\n"
        case "unxz file.txt.xz":
            return "" // 静默成功
        case "7z":
            return "7-Zip [64] 17.05 : Copyright (c) 1999-2021 Igor Pavlov\nUsage: 7z <command> <switches> <archive_name> <file_names>\n"
        case "7z a archive.7z file1 file2":
            return UtilityGenerator.generate7zCreate()
        case "7z x archive.7z":
            return UtilityGenerator.generate7zExtract()
        case "7z l archive.7z":
            return UtilityGenerator.generate7zList()
        default:
            return nil
        }
    }

    // MARK: - SSH Commands

    private static func handleSSHCommands(_ command: String, username: String, homeDirectory: String) -> String? {
        switch command {
        case "ssh-keygen":
            return "Generating public/private rsa key pair.\nEnter file in which to save the key (/home/\(username)/.ssh/id_rsa): \n"
        case "ssh-keygen -t rsa":
            return "Generating public/private rsa key pair.\nEnter file in which to save the key (/home/\(username)/.ssh/id_rsa): \n"
        case "ssh-keygen -t rsa -b 4096":
            return "Generating public/private rsa key pair.\nEnter file in which to save the key (/home/\(username)/.ssh/id_rsa): \n"
        case "ssh-keygen -t ed25519":
            return "Generating public/private ed25519 key pair.\nEnter file in which to save the key (/home/\(username)/.ssh/id_ed25519): \n"
        case "ssh-keygen -t rsa -f /tmp/test_key":
            return UtilityGenerator.generateSSHKeygenOutput(path: "/tmp/test_key", keyType: "rsa")
        case "ssh-keygen -t ed25519 -f /tmp/test_key":
            return UtilityGenerator.generateSSHKeygenOutput(path: "/tmp/test_key", keyType: "ed25519")
        case "ssh-keygen -l -f ~/.ssh/id_rsa.pub":
            return "4096 SHA256:abc123def456 user@server (RSA)\n"
        case "ssh-keygen -l -f ~/.ssh/id_ed25519.pub":
            return "256 SHA256:abc123def456 user@server (ED25519)\n"
        case "ssh-copy-id":
            return "Usage: ssh-copy-id [-i [identity_file]] [user@]machine\n"
        case "ssh-copy-id user@server":
            return UtilityGenerator.generateSSHCopyID(username: "user", server: "server")
        case "ssh-copy-id -i ~/.ssh/id_rsa.pub user@server":
            return UtilityGenerator.generateSSHCopyID(username: "user", server: "server")
        case "scp":
            return "Usage: scp [OPTION]... [SRC]... [DEST]\nSecure copy files between hosts.\n"
        case "scp --help":
            return UtilityGenerator.generateSCPHelp()
        case "scp file.txt user@server:/home/user/":
            return UtilityGenerator.generateSCPUpload()
        case "scp user@server:/home/user/file.txt .":
            return UtilityGenerator.generateSCPDownload()
        case "scp -r folder user@server:/home/user/":
            return UtilityGenerator.generateSCPUploadFolder()
        case "scp -P 2222 file.txt user@server:/home/user/":
            return UtilityGenerator.generateSCPUploadPort()
        case "sftp":
            return "Usage: sftp [OPTIONS] [user@]host[:file ...]\nSecure File Transfer Program.\n"
        case "sftp user@server":
            return UtilityGenerator.generateSFTPConnect()
        case "rsync":
            return "Usage: rsync [OPTION]... SRC [SRC]... DEST\n"
        case "rsync --help":
            return UtilityGenerator.generateRsyncHelp()
        case "rsync -avz source/ dest/":
            return UtilityGenerator.generateRsyncLocal()
        case "rsync -avz source/ user@server:/dest/":
            return UtilityGenerator.generateRsyncRemote()
        case "rsync -avz user@server:/source/ dest/":
            return UtilityGenerator.generateRsyncRemoteDownload()
        case "rsync --progress source/ dest/":
            return UtilityGenerator.generateRsyncProgress()
        default:
            return nil
        }
    }

    // MARK: - System Utility Commands

    private static func handleSystemUtilityCommands(_ command: String, username: String) -> String? {
        switch command {
        case "lsof":
            return UtilityGenerator.generateLsofHelp()
        case "lsof -i":
            return UtilityGenerator.generateLsofNetwork()
        case "lsof -i :22":
            return UtilityGenerator.generateLsofPort(port: "22")
        case "lsof -i :80":
            return UtilityGenerator.generateLsofPort(port: "80")
        case "lsof -i TCP":
            return UtilityGenerator.generateLsofTCP()
        case "lsof -i UDP":
            return UtilityGenerator.generateLsofUDP()
        case "lsof -p 1":
            return UtilityGenerator.generateLsofPID(pid: "1")
        case "lsof -u root":
            return UtilityGenerator.generateLsofUser(user: "root")
        case "lsof -u \(username)":
            return UtilityGenerator.generateLsofUser(user: username)
        case "lsof +D /var":
            return UtilityGenerator.generateLsofDirectory(dir: "/var")
        case "nc":
            return "Usage: nc [OPTION]... [HOST] [PORT]\nNcat - Netcat reimplemented by Nmap project.\n"
        case "nc -h":
            return UtilityGenerator.generateNcHelp()
        case "nc -zv localhost 22":
            return UtilityGenerator.generateNcPortScan(host: "localhost", port: "22")
        case "nc -zv localhost 80":
            return UtilityGenerator.generateNcPortScan(host: "localhost", port: "80")
        case "nc -zv 192.168.1.1 22-80":
            return UtilityGenerator.generateNcPortRange(host: "192.168.1.1")
        case "nc -l 12345":
            return "Listening on 0.0.0.0 12345\n"
        case "nc localhost 12345":
            return "(Connection to localhost 12345 port [tcp/*] succeeded)\n"
        case "screen":
            return "Use: screen [-opts] [cmd [args]]\nScreen is a full-screen window manager.\n"
        case "screen -ls":
            return UtilityGenerator.generateScreenList()
        case "screen -S session1":
            return "" // 静默成功，创建新会话
        case "screen -r session1":
            return "" // 静默成功，恢复会话
        case "screen -X -S session1 quit":
            return "" // 静默成功
        case "tmux":
            return "Usage: tmux [-2lCuDV] [-c shell-command] [-f file] [-L socket-name] [-S socket-path]\n"
        case "tmux ls":
            return UtilityGenerator.generateTmuxList()
        case "tmux list-sessions":
            return UtilityGenerator.generateTmuxList()
        case "tmux new -s session1":
            return "" // 静默成功
        case "tmux new-session -s session1":
            return "" // 静默成功
        case "tmux attach -t session1":
            return "" // 静默成功
        case "tmux kill-session -t session1":
            return "" // 静默成功
        case "tmux kill-server":
            return "" // 静默成功
        case "nohup":
            return "Usage: nohup COMMAND [ARG]...\n"
        case "nohup command &":
            return "nohup: ignoring input and appending output to 'nohup.out'\n"
        case "nohup python app.py &":
            return "nohup: ignoring input and appending output to 'nohup.out'\n[1] 12345\n"
        case "watch":
            return "Usage: watch [options] command\n"
        case "watch -n 1 date":
            return "Every 1.0s: date\n\(Date().formatted(date: .complete, time: .complete))\n"
        case "watch -n 5 free -h":
            return "Every 5.0s: free -h\n(Press Ctrl+C to stop)\n"
        case "watch df -h":
            return "Every 2.0s: df -h\n(Press Ctrl+C to stop)\n"
        case "time":
            return "Usage: time [-apvV] [-f format] [-o file] [--append] [command ...]\n"
        case "time ls":
            return UtilityGenerator.generateTimeOutput(command: "ls")
        case "time ping -c 4 localhost":
            return UtilityGenerator.generateTimeOutput(command: "ping -c 4 localhost")
        case "dd":
            return "Usage: dd [OPERAND]...\nCopy and convert a file.\n"
        case "dd --help":
            return UtilityGenerator.generateDdHelp()
        case "dd if=/dev/zero of=test.txt bs=1M count=10":
            return UtilityGenerator.generateDdOutput(size: "10MB")
        case "dd if=/dev/sda of=/dev/sdb bs=4M":
            return "Copying disk... (this may take a while)\n"
        case "dd if=test.iso of=/dev/sdb bs=4M status=progress":
            return UtilityGenerator.generateDdProgress()
        case "yes":
            return "y\ny\ny\ny\ny\ny\ny\ny\ny\ny\n(Press Ctrl+C to stop)\n"
        case "yes n":
            return "n\nn\nn\nn\nn\nn\nn\nn\nn\nn\n(Press Ctrl+C to stop)\n"
        case "yes | rm -r folder":
            return "" // 静默成功
        case "expect":
            return "Usage: expect [options] [file]\n"
        case "expect -c 'spawn ssh user@server; expect password; send pass\\r'":
            return "spawn ssh user@server\npassword: \n"
        case "mktemp":
            return "/tmp/tmp.1234567890\n"
        case "mktemp -d":
            return "/tmp/tmp.1234567890.d\n"
        case "mktemp -t myprefix":
            return "/tmp/myprefix.1234567890\n"
        case "flock":
            return "Usage: flock [options] <file|directory> <command> [args]\n"
        case "flock -n /tmp/lockfile command":
            return "" // 静默成功
        case "at":
            return "Usage: at [-V] [-q queue] [-f file] [-mldbv] TIME\n"
        case "at now":
            return "warning: commands will be executed using /bin/sh\nat> \n"
        case "at now + 5 minutes":
            return "warning: commands will be executed using /bin/sh\nat> \n"
        case "atq":
            return "1\t2026-04-23 10:05\t\(username)\n"
        case "atrm 1":
            return "" // 静默成功
        case "batch":
            return "warning: commands will be executed using /bin/sh\nat> \n"
        case "cron":
            return "cron: can't lock /var/run/crond.pid, otherpid may be 1234: Resource temporarily unavailable\n"
        case "atexit":
            return "atexit: No function registered.\n"
        default:
            return nil
        }
    }

    // MARK: - Text Processing Commands

    private static func handleTextProcessingCommands(_ command: String) -> String? {
        // sed 命令
        if command.hasPrefix("sed ") {
            return handleSedCommand(command)
        }

        // awk 命令
        if command.hasPrefix("awk ") {
            return handleAwkCommand(command)
        }

        // 其他文本处理
        switch command {
        case "cut":
            return "Usage: cut OPTION... [FILE]...\n"
        case "cut -d: -f1 /etc/passwd":
            return "root\ndaemon\nbin\nsys\nsync\ngames\n\(command.contains("passwd") ? "user\n" : "")\n"
        case "cut -d' ' -f1-3 file.txt":
            return "line1 word1 word2\nline2 word1 word2\n"
        case "cut -c1-10 file.txt":
            return "first line\nsecond li\nthird lin\n"
        case "tr":
            return "Usage: tr [OPTION]... SET1 [SET2]\n"
        case "tr 'a-z' 'A-Z'":
            return "(Press Ctrl+D to end input)\n"
        case "tr -d 'a-z'":
            return "(Press Ctrl+D to end input, will delete lowercase letters)\n"
        case "tr -s ' '":
            return "(Press Ctrl+D to end input, will squeeze spaces)\n"
        case "rev":
            return "(Press Ctrl+D to end input, will reverse lines)\n"
        case "rev file.txt":
            return "enil tsrif\nenil dnoces\nenil driht\n"
        case "shuf":
            return "Usage: shuf [OPTION]... [FILE]\n"
        case "shuf file.txt":
            return "line 3\nline 1\nline 2\n"
        case "shuf -n 3 file.txt":
            return "line 2\nline 1\nline 5\n"
        case "shuf -e a b c d":
            return "c\na\nd\nb\n"
        case "fmt":
            return "Usage: fmt [-WIDTH] [OPTION]... [FILE]...\n"
        case "fmt -w 50 file.txt":
            return "This is a formatted line with max width 50 chars.\n"
        case "fold":
            return "Usage: fold [OPTION]... [FILE]...\n"
        case "fold -w 20 file.txt":
            return "This line is fold\ned at 20 chars\n"
        case "paste":
            return "Usage: paste [OPTION]... [FILE]...\n"
        case "paste file1.txt file2.txt":
            return "line1\tline1\nline2\tline2\n"
        case "paste -d',' file1.txt file2.txt":
            return "line1,line1\nline2,line2\n"
        case "join":
            return "Usage: join [OPTION]... FILE1 FILE2\n"
        case "join file1.txt file2.txt":
            return "key1 value1 value1\nkey2 value2 value2\n"
        case "split":
            return "Usage: split [OPTION]... [INPUT [PREFIX]]\n"
        case "split -l 100 file.txt":
            return "" // 静默成功，创建 xaa, xab 等文件
        case "split -b 10M largefile.bin":
            return "" // 静默成功
        case "csplit":
            return "Usage: csplit [OPTION]... FILE PATTERN...\n"
        case "expand":
            return "Usage: expand [OPTION]... [FILE]...\n"
        case "unexpand":
            return "Usage: unexpand [OPTION]... [FILE]...\n"
        case "nl":
            return "Usage: nl [OPTION]... [FILE]...\n"
        case "nl file.txt":
            return "     1\tfirst line\n     2\tsecond line\n     3\tthird line\n"
        case "pr":
            return "Usage: pr [OPTION]... [FILE]...\n"
        case "pr -2 file.txt":
            return UtilityGenerator.generatePrOutput()
        default:
            return nil
        }
    }

    private static func handleSedCommand(_ command: String) -> String? {
        let args = command.dropFirst(4).trimmingCharacters(in: .whitespaces)

        switch args {
        case "", "--help":
            return UtilityGenerator.generateSedHelp()
        case "-n '1,5p' file.txt":
            return "line1\nline2\nline3\nline4\nline5\n"
        case "'s/old/new/' file.txt":
            return "This is new text\nAnother new line\n"
        case "'s/old/new/g' file.txt":
            return "This is new text with new content\nAnother new line with new data\n"
        case "-i 's/old/new/' file.txt":
            return "" // 静默成功，原地修改
        case "'1d' file.txt":
            return "line2\nline3\nline4\n"
        case "'/^$/d' file.txt":
            return "line1\nline2\nline3\n"
        case "'/pattern/d' file.txt":
            return "line1\nline3\nline5\n"
        case "-n '/pattern/p' file.txt":
            return "line2 with pattern\nline4 with pattern\n"
        case "'$a\\newline' file.txt":
            return "line1\nline2\nline3\nnewline\n"
        case "'5,10s/old/new/' file.txt":
            return "lines 5-10 replaced\n"
        case "'/^START/,/^END/s/old/new/' file.txt":
            return "Replaced within START to END block\n"
        case "-e 's/a/A/' -e 's/b/B/' file.txt":
            return "Modified line A with B\n"
        case "-f script.sed file.txt":
            return "Applied sed script\n"
        default:
            if args.hasPrefix("'s/") || args.hasPrefix("-e") {
                return "Modified output according to sed expression\n"
            }
            return nil
        }
    }

    private static func handleAwkCommand(_ command: String) -> String? {
        let args = command.dropFirst(4).trimmingCharacters(in: .whitespaces)

        switch args {
        case "", "--help":
            return UtilityGenerator.generateAwkHelp()
        case "'{print}' file.txt":
            return "line1\nline2\nline3\n"
        case "'{print $1}' file.txt":
            return "word1\nword2\nword3\n"
        case "'{print $1, $3}' file.txt":
            return "word1 word3\nword2 word6\nword3 word9\n"
        case "'{print NF}' file.txt":
            return "5\n5\n5\n"
        case "'{print NR}' file.txt":
            return "1\n2\n3\n"
        case "'{sum += $1} END {print sum}' file.txt":
            return "150\n"
        case "'{print $0}' /etc/passwd":
            return "root:x:0:0:root:/root:/bin/bash\ndaemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\n"
        case "-F: '{print $1}' /etc/passwd":
            return "root\ndaemon\nbin\nsys\nsync\ngames\nuser\n"
        case "-F: '{print $1, $3}' /etc/passwd":
            return "root 0\ndaemon 1\nbin 2\nsys 3\n"
        case "'$1 > 100 {print $0}' file.txt":
            return "150 word1 word2\n200 word3 word4\n"
        case "'/pattern/ {print $0}' file.txt":
            return "line with pattern matched\n"
        case "'NR > 5 {print $0}' file.txt":
            return "line6\nline7\nline8\n"
        case "'NF > 3 {print $0}' file.txt":
            return "line with more than 3 fields\n"
        case "'BEGIN {print \"Header\"} {print $0} END {print \"Footer\"}' file.txt":
            return "Header\nline1\nline2\nline3\nFooter\n"
        case "'{printf \"%-10s %5d\\n\", $1, $2}' file.txt":
            return "name          100\nname2         200\n"
        case "-f script.awk file.txt":
            return "Applied awk script\n"
        default:
            if args.hasPrefix("'{") || args.hasPrefix("-F") {
                return "Processed according to awk script\n"
            }
            return nil
        }
    }

    // MARK: - Encoding Commands

    private static func handleEncodingCommands(_ command: String) -> String? {
        switch command {
        case "base64":
            return "Usage: base64 [OPTION]... [FILE]\n"
        case "base64 file.txt":
            return "VGhpcyBpcyB0aGUgYmFzZTY0IGVuY29kZWQgb3V0cHV0Cg==\n"
        case "base64 -d encoded.txt":
            return "This is the decoded output\n"
        case "base64 -w 0 file.txt":
            return "VGhpcyBpcyB0aGUgYmFzZTY0IGVuY29kZWQgb3V0cHV0Cg==\n"
        case "echo 'test' | base64":
            return "dGVzdAo=\n"
        case "md5sum":
            return "Usage: md5sum [OPTION]... [FILE]...\n"
        case "md5sum file.txt":
            return "d41d8cd98f00b204e9800998ecf8427e  file.txt\n"
        case "md5sum -c checksum.md5":
            return "file.txt: OK\n"
        case "md5sum file1.txt file2.txt":
            return "abc123def456  file1.txt\n789012ghi345  file2.txt\n"
        case "sha256sum":
            return "Usage: sha256sum [OPTION]... [FILE]...\n"
        case "sha256sum file.txt":
            return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  file.txt\n"
        case "sha256sum -c checksum.sha256":
            return "file.txt: OK\n"
        case "sha1sum":
            return "Usage: sha1sum [OPTION]... [FILE]...\n"
        case "sha1sum file.txt":
            return "da39a3ee5e6b4b0d3255bfef95601890afd80709  file.txt\n"
        case "sha512sum":
            return "Usage: sha512sum [OPTION]... [FILE]...\n"
        case "sha512sum file.txt":
            return "cf83e1357eefb8bd...\n"
        case "cksum":
            return "Usage: cksum [FILE]...\n"
        case "cksum file.txt":
            return "1234567890 100 file.txt\n"
        case "sum":
            return "Usage: sum [FILE]...\n"
        case "sum file.txt":
            return "12345 100\n"
        case "b2sum":
            return "Usage: b2sum [OPTION]... [FILE]...\n"
        case "b2sum file.txt":
            return "blake2b hash output...\n"
        case "xxd":
            return "Usage: xxd [options] [infile [outfile]]\n"
        case "xxd file.txt":
            return UtilityGenerator.generateXxdOutput()
        case "xxd -r hex.txt":
            return "This is the reversed binary\n"
        case "xxd -l 16 file.txt":
            return "00000000: 5468 6973 2069 7320 7465 7374 0a0a  This is test..\n"
        case "od":
            return "Usage: od [OPTION]... [FILE]...\n"
        case "od -c file.txt":
            return UtilityGenerator.generateOdOutput()
        case "od -x file.txt":
            return "000000 5468 6973 2069 7320 7465 7374 0a\n"
        case "hexdump":
            return "Usage: hexdump [OPTION]... FILE\n"
        case "hexdump -C file.txt":
            return UtilityGenerator.generateHexdumpOutput()
        case "strings":
            return "Usage: strings [OPTION]... [FILE]...\n"
        case "strings file.txt":
            return "This is a string\nAnother string here\n"
        case "strings -n 8 file.txt":
            return "This is a string\nAnother string here\n"
        default:
            return nil
        }
    }
}

/// 实用工具生成器
enum UtilityGenerator {

    // MARK: - Compression

    static func generateTarHelp() -> String {
        return """
        Usage: tar [OPTION...] [FILE]...
        GNU 'tar' saves many files together into a single tape or disk archive.

        Main operation mode:
          -c, --create             create a new archive
          -x, --extract            extract files from an archive
          -t, --list               list the contents of an archive
          -r, --append             append files to the end of an archive
          -u, --update             only append files that are newer than copy in archive

        Compression options:
          -z, --gzip               filter the archive through gzip
          -j, --bzip2              filter the archive through bzip2
          -J, --xz                 filter the archive through xz
          --lzip                   filter the archive through lzip

        Archive format selection:
          -v, --verbose            verbosely list files processed
          -f, --file=ARCHIVE       use archive file or device ARCHIVE

        """
    }

    static func generateTarCreate() -> String {
        return """
        file1
        file2
        file1
        file2

        """
    }

    static func generateTarGzipCreate() -> String {
        return """
        file1
        file2
        file1
        file2

        """
    }

    static func generateTarGzipExtract() -> String {
        return """
        file1
        file2
        Extracted 'file1'
        Extracted 'file2'

        """
    }

    static func generateTarList() -> String {
        return """
        file1
        file2

        """
    }

    static func generateTarGzipList() -> String {
        return """
        file1
        file2

        """
    }

    static func generateGzipHelp() -> String {
        return """
        Usage: gzip [OPTION]... [FILE]...
        Compress or uncompress FILEs (by default, compress FILEs).

        Options:
          -c    write to standard output, keep original files unchanged
          -d    decompress
          -f    force compression or decompression
          -h    give this help
          -k    keep (don't delete) input files during compression or decompression
          -l    list compressed file contents
          -n    no file name or time stamp saved
          -q    quiet suppress all warnings
          -r    recursive
          -S    use suffix .SUF on compressed files
          -t    test compressed file integrity
          -v    verbose
          -V    display version number
          -1..9 compression strength

        """
    }

    static func generateZipCreate() -> String {
        return """
        adding: folder/ (stored 0%)
        adding: folder/file1.txt (deflated 50%)
        adding: folder/file2.txt (deflated 45%)
        adding: folder/subfolder/ (stored 0%)
        adding: folder/subfolder/file3.txt (deflated 40%)

        """
    }

    static func generateZipCreateFiles() -> String {
        return """
        adding: file1.txt (deflated 50%)
        adding: file2.txt (deflated 45%)

        """
    }

    static func generateUnzip() -> String {
        return """
        Archive:  archive.zip
          inflating: file1.txt
          inflating: file2.txt

        """
    }

    static func generateUnzipList() -> String {
        return """
        Archive:  archive.zip
          Length      Date    Time    Name
              100  2026-04-22 10:00   file1.txt
              200  2026-04-22 10:00   file2.txt
              300                     2 files

        """
    }

    static func generate7zCreate() -> String {
        return """
        
        7-Zip [64] 17.05 : Copyright (c) 1999-2021 Igor Pavlov
        Creating archive: archive.7z
        
        Everything is Ok
        Files: 2
        Size: 100
        Compressed: 50

        """
    }

    static func generate7zExtract() -> String {
        return """
        
        7-Zip [64] 17.05 : Copyright (c) 1999-2021 Igor Pavlov
        
        Everything is Ok
        Files: 2
        Size: 100

        """
    }

    static func generate7zList() -> String {
        return """
        7-Zip [64] 17.05 : Copyright (c) 1999-2021 Igor Pavlov
        
        Listing archive: archive.7z
        
        --
        Path = archive.7z
        Type = 7z
        Physical Size = 50
        
           Date      Time    Attr         Size   Compressed  Name
        2026-04-22 10:00:00 .....          100           50  file1.txt
        2026-04-22 10:00:00 .....          200              file2.txt

        """
    }

    // MARK: - SSH

    static func generateSSHKeygenOutput(path: String, keyType: String) -> String {
        let keySize = keyType == "rsa" ? "4096" : "256"
        return """
        Generating public/private \(keyType) key pair.
        Your identification has been saved in \(path)
        Your public key has been saved in \(path).pub
        The key fingerprint is:
        SHA256:abc123def456ghi789 user@server
        The key's randomart image is:
        +---[\(keyType) \(keySize)]----+
        |       .o.      |
        |      o o o     |
        |     . = . .    |
        |    . o + .     |
        |     . S o      |
        |    . . .       |
        |   . . .        |
        |  . . .         |
        | . . .          |
        +----[SHA256]-----+

        """
    }

    static func generateSSHCopyID(username: String, server: String) -> String {
        return """
        /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "~/.ssh/id_rsa.pub"
        /usr/bin/ssh-copy-id: INFO: Attempting to log in with the new key(s)
        /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed
        \(username)@\(server)'s password: 

        Number of key(s) added: 1

        Now try logging into the machine with: 'ssh \(username)@\(server)'
        and check to make sure that only the key(s) you wanted were added.

        """
    }

    static func generateSCPHelp() -> String {
        return """
        usage: scp [-346BCpqrTv] [-c cipher] [-F ssh_config] [-i identity_file]
                   [-J destination] [-l limit] [-o ssh_option] [-P port]
                   [-S program] source ... target

        -3      Copies between two remote hosts are transferred through the local host.
        -4      Use IPv4 addresses only.
        -6      Use IPv6 addresses only.
        -B      Batch mode (don't ask for passwords).
        -C      Compression enable.
        -p      Preserve file attributes.
        -q      Quiet mode.
        -r      Recursively copy directories.
        -T      Disable strict filename checking.
        -v      Verbose mode.

        """
    }

    static func generateSCPUpload() -> String {
        return """
        file.txt                                      100%  100KB   50.0KB/s   00:02

        """
    }

    static func generateSCPDownload() -> String {
        return """
        file.txt                                      100%  100KB   50.0KB/s   00:02

        """
    }

    static func generateSCPUploadFolder() -> String {
        return """
        folder/                                        100%  500KB   25.0KB/s   00:20
        folder/file1.txt                               100%  100KB   50.0KB/s   00:02
        folder/file2.txt                               100%  200KB   50.0KB/s   00:04

        """
    }

    static func generateSCPUploadPort() -> String {
        return """
        file.txt                                      100%  100KB   50.0KB/s   00:02

        """
    }

    static func generateSFTPConnect() -> String {
        return """
        Connected to server.
        sftp> 

        """
    }

    static func generateRsyncHelp() -> String {
        return """
        Usage: rsync [OPTION]... SRC [SRC]... DEST
        Rsync is a fast and extraordinarily versatile file copying tool.

        Options:
          -v, --verbose             increase verbosity
          -q, --quiet               suppress non-error messages
          -a, --archive             archive mode; equals -rlptgoD
          -r, --recursive           recurse into directories
          -R, --relative            use relative path names
          -b, --backup              make backups
          -u, --update              skip files that are newer on the receiver
          -l, --links               copy symlinks as symlinks
          -L, --copy-links          transform symlink into referent file/dir
          -p, --perms               preserve permissions
          -t, --times               preserve modification times
          -g, --group               preserve group
          -o, --owner               preserve owner (super-user only)
          -D, --devices             preserve device files (super-user only)
          -z, --compress            compress file data during the transfer
          -P                        same as --partial --progress
          --progress                show progress during transfer
          --delete                  delete extraneous files from dest dirs

        """
    }

    static func generateRsyncLocal() -> String {
        return """
        sending incremental file list
        source/
        source/file1.txt
        source/file2.txt
        
        sent 1,234 bytes  received 35 bytes  2,538.00 bytes/sec
        total size is 100,000  speedup is 40.00

        """
    }

    static func generateRsyncRemote() -> String {
        return """
        sending incremental file list
        source/
        source/file1.txt
        source/file2.txt
        
        sent 1,234 bytes  received 35 bytes  256.70 bytes/sec
        total size is 100,000  speedup is 400.00

        """
    }

    static func generateRsyncRemoteDownload() -> String {
        return """
        receiving incremental file list
        source/
        source/file1.txt
        source/file2.txt
        
        sent 35 bytes  received 1,234 bytes  256.70 bytes/sec
        total size is 100,000  speedup is 400.00

        """
    }

    static func generateRsyncProgress() -> String {
        return """
        sending incremental file list
        source/file1.txt
              100   100%    50.00kB/s    0:00:02 (xfr#1, to-chk=0/2)
        source/file2.txt
              200   100%    50.00kB/s    0:00:04 (xfr#2, to-chk=0/2)
        
        sent 1,234 bytes  received 35 bytes  2,538.00 bytes/sec
        total size is 300  speedup is 0.24

        """
    }

    // MARK: - System Utility

    static func generateLsofHelp() -> String {
        return """
        usage: lsof [-?abhlnNoPRsStUvV] [+|-c c] [+|-d s] [+D D] [+|-E]
             [+|-f[gG]] [-F [f]] [-g [s]] [-i [i]] [+|-L [l]] [+|-M]
             [-o [o]] [-p s] [+|-r [t]] [-s [p:s]] [-S [t]]
             [-T [t]] [-u s] [+|-w] [-x [fl]] [--] [names]

        -b       avoid kernel blocks
        -c       select processes by command name
        -d       select by file descriptor
        -i       select IPv[46] files
        -l       list UID numbers
        -n       no host name resolution
        -N       select NFS files
        -o       list file offset
        -p       select by PID
        -P       no port name resolution
        -r       repeat listing
        -s       list file size
        -t       terse output (PIDs only)
        -u       select by user
        -U       select Unix domain socket files

        """
    }

    static func generateLsofNetwork() -> String {
        return """
        COMMAND     PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
        sshd       1234 root    3u  IPv4    12345      0t0  TCP *:22 (LISTEN)
        nginx      12347 root    6u  IPv4    12346      0t0  TCP *:80 (LISTEN)
        nginx      12347 root    7u  IPv4    12347      0t0  TCP *:443 (LISTEN)
        docker     12350 root    4u  IPv6    12348      0t0  TCP *:2376 (LISTEN)

        """
    }

    static func generateLsofPort(port: String) -> String {
        return """
        COMMAND     PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
        sshd       1234 root    3u  IPv4    12345      0t0  TCP *:\(port) (LISTEN)

        """
    }

    static func generateLsofTCP() -> String {
        return """
        COMMAND     PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
        sshd       1234 root    3u  IPv4    12345      0t0  TCP *:22 (LISTEN)
        nginx      12347 root    6u  IPv4    12346      0t0  TCP *:80 (LISTEN)

        """
    }

    static func generateLsofUDP() -> String {
        return """
        COMMAND     PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
        systemd    1    root   12u  IPv4    10000      0t0  UDP *:68
        ntpd       12360 root    4u  IPv4    12349      0t0  UDP *:123

        """
    }

    static func generateLsofPID(pid: String) -> String {
        return """
        COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        init      \(pid)  root  cwd    DIR   8,1      4096    2 /
        init      \(pid)  root  rtd    DIR   8,1      4096    2 /
        init      \(pid)  root  txt    REG   8,1     10000  123 /sbin/init

        """
    }

    static func generateLsofUser(user: String) -> String {
        return """
        COMMAND     PID \(user)   FD   TYPE DEVICE SIZE/OFF NODE NAME
        bash      12345 \(user)  cwd    DIR   8,1      4096  456 /home/\(user)
        bash      12345 \(user)  rtd    DIR   8,1      4096    2 /
        bash      12345 \(user)  txt    REG   8,1     15000  789 /bin/bash
        vim       12346 \(user)  cwd    DIR   8,1      4096  456 /home/\(user)

        """
    }

    static func generateLsofDirectory(dir: String) -> String {
        return """
        COMMAND     PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        syslog      100 root  cwd    DIR   8,1      4096   10 \(dir)/log
        nginx      12347 root  cwd    DIR   8,1      4096   20 \(dir)/www

        """
    }

    static func generateNcHelp() -> String {
        return """
        Ncat 7.80 ( https://nmap.org/ncat )
        Usage: ncat [options] [hostname] [port]

        Options taking a time assume seconds. Append 'ms' for milliseconds,
        's' for seconds, 'm' for minutes, or 'h' for hours (e.g. 500ms).
          -4                         Use IPv4 only
          -6                         Use IPv6 only
          -U, --unixsock             Use Unix domain sockets
          -u, --udp                  Use UDP instead of TCP
          -l, --listen               Listen for connections instead of connecting
          -k, --keep-open            Keep listening after connection closes
          -z                         Port scan only
          -v, --verbose              Be verbose
          --version                  Show version
          -c, --sh-exec <command>    Execute a shell command
          -e, --exec <command>       Execute a command

        """
    }

    static func generateNcPortScan(host: String, port: String) -> String {
        return """
        Connection to \(host) \(port) port [tcp/*] succeeded!

        """
    }

    static func generateNcPortRange(host: String) -> String {
        return """
        Connection to \(host) 22 port [tcp/*] succeeded!
        Connection to \(host) 80 port [tcp/*] succeeded!
        Connection to \(host) 443 port [tcp/*] succeeded!

        """
    }

    static func generateScreenList() -> String {
        return """
        There is a screen on:
            12345.session1    (Detached)
        There is a screen on:
            12346.session2    (Detached)
        2 Sockets in /run/screen.

        """
    }

    static func generateTmuxList() -> String {
        return """
        session1: 1 windows (created \(Date().formatted(date: .abbreviated, time: .shortened)))
        session2: 2 windows (created \(Date().formatted(date: .abbreviated, time: .shortened)))

        """
    }

    static func generateTimeOutput(command: String) -> String {
        return """
        \(command) output here
        
        real    0.52
        user    0.10
        sys     0.05

        """
    }

    static func generateDdHelp() -> String {
        return """
        Usage: dd [OPERAND]...
          or:  dd OPTION
        Copy a file, converting and formatting according to the operands.

          bs=BYTES        read and write up to BYTES bytes at a time
          cbs=BYTES       convert BYTES bytes at a time
          conv=CONVS      convert the file as per the comma separated symbol list
          count=N         copy only N input blocks
          ibs=BYTES       read up to BYTES bytes at a time (default: 512)
          if=FILE         read from FILE instead of stdin
          obs=BYTES       write BYTES bytes at a time (default: 512)
          of=FILE         write to FILE instead of stdout
          seek=N          skip N obs-sized output blocks at start of output
          skip=N          skip N ibs-sized input blocks at start of input
          status=LEVEL    The LEVEL of information to print to stderr

        """
    }

    static func generateDdOutput(size: String) -> String {
        return """
        10+0 records in
        10+0 records out
        10485760 bytes (\(size)) copied, 0.5 s, 20.0 MB/s

        """
    }

    static func generateDdProgress() -> String {
        return """
        1024+0 records in
        1024+0 records out
        4294967296 bytes (4.3 GB) copied, 100.5 s, 42.7 MB/s

        """
    }

    // MARK: - Text Processing

    static func generateSedHelp() -> String {
        return """
        Usage: sed [OPTION]... {script-only-if-other-script} [input-file]

          -n, --quiet, --silent
                 suppress automatic printing of pattern space
          -e script, --expression=script
                 add the script to the commands to be executed
          -f script-file, --file=script-file
                 add the contents of script-file to the commands
          --follow-symlinks
                 follow symlinks when processing in place
          -i[SUFFIX], --in-place[=SUFFIX]
                 edit files in place (makes backup if SUFFIX supplied)
          -l N, --line-length=N
                 specify the desired line-wrap length for the `l' command
          --posix
                 disable all GNU extensions
          -b, --binary
                 open files in binary mode
          -E, -r, --regexp-extended
                 use extended regular expressions
          -s, --separate
                 consider files as separate rather than continuous

        """
    }

    static func generateAwkHelp() -> String {
        return """
        Usage: awk [POSIX or GNU style options] -f progfile [--] file ...
        Usage: awk [POSIX or GNU style options] [--] 'program' file ...

        POSIX options:          GNU long options:
          -f progfile           --file=progfile
          -F fs                 --field-separator=fs
          -v var=val            --assign=var=val
          -m[fr] val
          -O                    --optimize
          -W compat             --compat
          -W copyleft           --copyleft
          -W copyright          --copyright
          -W dump-variables[=file]      --dump-variables[=file]
          -W exec=file          --exec=file
          -W help               --help
          -W lint[=fatal]       --lint[=fatal]
          -W lint-old           --lint-old
          -W non-decimal-data   --non-decimal-data
          -W posix              --posix
          -W profile[=file]     --profile[=file]
          -W traditional        --traditional
          -W usage              --usage
          -W version            --version

        """
    }

    static func generatePrOutput() -> String {
        return """
        \(Date().formatted(date: .abbreviated, time: .shortened))                    Page 1
        
        line1                     line2
        line3                     line4
        line5                     line6

        """
    }

    // MARK: - Encoding

    static func generateXxdOutput() -> String {
        return """
        00000000: 5468 6973 2069 7320 7465 7374 2066 696c  This is test fil
        00000010: 6520 636f 6e74 656e 740a                 e content.

        """
    }

    static func generateOdOutput() -> String {
        return """
        0000000   T   h   i   s       i   s       t   e   s   t  \\n
        0000012

        """
    }

    static func generateHexdumpOutput() -> String {
        return """
        00000000  54 68 69 73 20 69 73 20  74 65 73 74 0a           |This is test.|
        0000000d

        """
    }
}