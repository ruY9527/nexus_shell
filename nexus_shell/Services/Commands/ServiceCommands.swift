//
//  ServiceCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 服务管理命令模拟
enum ServiceCommands {
    
    static func execute(_ command: String) -> String? {
        switch command {
        case "systemctl":
            return "Usage: systemctl [OPTIONS...] {COMMAND} ...\n"
        case "systemctl --version":
            return "systemd 249 (249.11-0ubuntu3.12)\n"
        case "systemctl status":
            return ServiceGenerator.generateStatus()
        case "systemctl list-units":
            return ServiceGenerator.generateListUnits()
        case "systemctl list-units --type=service":
            return ServiceGenerator.generateListServices()
        case "systemctl list-unit-files":
            return ServiceGenerator.generateListUnitFiles()
        case "systemctl list-timers":
            return ServiceGenerator.generateListTimers()
        case "systemctl list-sockets":
            return ServiceGenerator.generateListSockets()
        case "systemctl list-jobs":
            return "JOB  UNIT                     TYPE  STATE\nNo jobs running.\n"
        case "systemctl status sshd":
            return ServiceGenerator.generateSSHStatus()
        case "systemctl status ssh":
            return ServiceGenerator.generateSSHStatus()
        case "systemctl status nginx":
            return ServiceGenerator.generateNginxStatus()
        case "systemctl status docker":
            return ServiceGenerator.generateDockerStatus()
        case "systemctl status mysql":
            return ServiceGenerator.generateMySQLStatus()
        case "systemctl status redis":
            return ServiceGenerator.generateRedisStatus()
        case "systemctl status apache2":
            return ServiceGenerator.generateApacheStatus()
        case "systemctl status cron":
            return ServiceGenerator.generateCronStatus()
        case "systemctl start":
            return "Usage: systemctl start UNIT...\n"
        case "systemctl stop":
            return "Usage: systemctl stop UNIT...\n"
        case "systemctl restart":
            return "Usage: systemctl restart UNIT...\n"
        case "systemctl reload":
            return "Usage: systemctl reload UNIT...\n"
        case "systemctl enable":
            return "Usage: systemctl enable UNIT...\n"
        case "systemctl disable":
            return "Usage: systemctl disable UNIT...\n"
        case "systemctl is-active sshd":
            return "active\n"
        case "systemctl is-active nginx":
            return "active\n"
        case "systemctl is-enabled sshd":
            return "enabled\n"
        case "systemctl is-enabled nginx":
            return "enabled\n"
        case "systemctl is-running sshd":
            return "running\n"
        case "systemctl show sshd":
            return ServiceGenerator.generateShowSSH()
        case "systemctl daemon-reload":
            return "" // 静默成功
        case "systemctl reset-failed":
            return "" // 靜默成功
        case "systemctl isolate graphical.target":
            return "" // 靜默成功
        case "systemctl get-default":
            return "graphical.target\n"
        case "systemctl set-default multi-user.target":
            return "Created symlink /etc/systemd/system/default.target → /lib/systemd/system/multi-user.target.\n"
        case "systemctl cat sshd":
            return ServiceGenerator.generateCatSSH()
        case "systemctl edit sshd":
            return "Editing unit file for sshd.service\n"
        case "service":
            return "Usage: service < option > | --status-all | [ service_name [ command | --full-restart ] ]\n"
        case "service --status-all":
            return ServiceGenerator.generateServiceStatusAll()
        case "service ssh status":
            return ServiceGenerator.generateSSHStatus()
        case "service nginx status":
            return ServiceGenerator.generateNginxStatus()
        case "service apache2 status":
            return ServiceGenerator.generateApacheStatus()
        case "service mysql status":
            return ServiceGenerator.generateMySQLStatus()
        case "service docker status":
            return ServiceGenerator.generateDockerStatus()
        case "journalctl":
            return "Usage: journalctl [OPTIONS...] [MATCHES...]\n"
        case "journalctl --version":
            return "systemd 249 (249.11-0ubuntu3.12)\n"
        case "journalctl -u ssh":
            return LogGenerator.generateSSHLogs()
        case "journalctl -u sshd":
            return LogGenerator.generateSSHLogs()
        case "journalctl -u nginx":
            return LogGenerator.generateNginxLogs()
        case "journalctl -u docker":
            return LogGenerator.generateDockerLogs()
        case "journalctl -f":
            return "-- Logs begin at \(Date().formatted(date: .abbreviated, time: .shortened)). --\n(Press Ctrl+C to stop)\n"
        case "journalctl -n 20":
            return LogGenerator.generateRecentLogs()
        case "journalctl -b":
            return LogGenerator.generateBootLogs()
        case "journalctl -p err":
            return LogGenerator.generateErrorLogs()
        case "journalctl --disk-usage":
            return "Archived and active journals take up 100.0M in the file system.\n"
        case "journalctl --verify":
            return "PASS: /var/log/journal/system.journal\n"
        case "journalctl --rotate":
            return "" // 靜默成功
        case "journalctl --vacuum-time=7d":
            return "Vacuuming done, freed 50M of archived journals.\n"
        case "journalctl --vacuum-size=500M":
            return "Vacuuming done, freed 0B of archived journals.\n"
        case "crontab -l":
            return ServiceGenerator.generateCrontab()
        case "crontab -e":
            return "no crontab for root - using an empty one\n"
        case "crontab -r":
            return "" // 靜默成功
        case "chkconfig":
            return "Usage: chkconfig [--list] [--add] [--del] [--level <levels>] <name>\n"
        case "chkconfig --list":
            return ServiceGenerator.generateChkconfigList()
        case "init":
            return "Usage: init [0 | 1 | 2 | 3 | 4 | 5 | 6 | S | s | Q | q | a | b | c]\n"
        case "runlevel":
            return "N 5\n"
        case "telinit 5":
            return "" // 靜默成功
        case "shutdown":
            return "Usage: shutdown [OPTIONS...] [TIME] [WALL...]\n"
        case "shutdown -h now":
            return "System is going down for halt NOW!\n"
        case "shutdown -r now":
            return "System is going down for reboot NOW!\n"
        case "reboot":
            return "System is going down for reboot NOW!\n"
        case "poweroff":
            return "System is going down for power off NOW!\n"
        case "halt":
            return "System is going down for halt NOW!\n"
        default:
            return nil
        }
    }
}

/// 服务生成器
enum ServiceGenerator {
    
    static func generateStatus() -> String {
        return """
        System state: running
        Jobs: 0 queued
        Failed: 0 units
        Since: \(Date().formatted(date: .abbreviated, time: .shortened))
        
        """
    }
    
    static func generateListUnits() -> String {
        return """
          UNIT                      LOAD   ACTIVE SUB     DESCRIPTION
          ssh.service               loaded active running OpenBSD Secure Shell server
          nginx.service             loaded active running A high performance web server
          docker.service            loaded active running Docker Application Container Engine
          systemd-journald.service  loaded active running Journal Service
          systemd-logind.service    loaded active running Login Service
          cron.service              loaded active running Regular background program processing
        
        LOAD   = Reflects whether the unit definition was properly loaded.
        ACTIVE = The high-level unit activation state.
        SUB    = The low-level unit activation state.
        
        6 loaded units listed. Pass --all to see loaded but inactive units, too.
        
        """
    }
    
    static func generateListServices() -> String {
        return """
          UNIT                      LOAD   ACTIVE SUB     DESCRIPTION
          ssh.service               loaded active running OpenBSD Secure Shell server
          nginx.service             loaded active running A high performance web server
          docker.service            loaded active running Docker Application Container Engine
          cron.service              loaded active running Regular background program processing
          mysql.service             loaded active running MySQL Community Server
          redis.service             loaded active running Redis In-Memory Data Store
        
        """
    }
    
    static func generateListUnitFiles() -> String {
        return """
        UNIT FILE                  STATE   VENDOR PRESET
        ssh.service                enabled enabled
        nginx.service              enabled enabled
        docker.service             enabled enabled
        mysql.service              enabled enabled
        redis.service              disabled enabled
        cron.service               enabled enabled
        
        6 unit files listed.
        
        """
    }
    
    static func generateListTimers() -> String {
        return """
        NEXT                         LEFT          LAST                         PASSED       UNIT                         ACTIVATES
        Wed 2026-04-23 00:00:00 UTC  14h left      Tue 2026-04-22 00:00:00 UTC  10h ago      apt-daily.timer              apt-daily.service
        Wed 2026-04-23 06:00:00 UTC  20h left      Tue 2026-04-22 06:00:00 UTC  4h ago       apt-daily-upgrade.timer      apt-daily-upgrade.service
        
        """
    }
    
    static func generateListSockets() -> String {
        return """
        LISTEN                          UNIT                         ACTIVATES
        /run/dbus/system_bus_socket     dbus.socket                  dbus.service
        /run/systemd/journal/socket     systemd-journald.socket      systemd-journald.service
        [::]:22                         ssh.socket                   ssh.service
        
        """
    }
    
    static func generateSSHStatus() -> String {
        return """
        ● ssh.service - OpenBSD Secure Shell server
             Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
               Docs: man:sshd(8)
                   man:sshd_config(5)
           Main PID: 1234 (sshd)
              Tasks: 1 (limit: 19149)
             Memory: 5.0M
             CGroup: /system.slice/ssh.service
                     └─1234 /usr/sbin/sshd -D
        
        """
    }
    
    static func generateNginxStatus() -> String {
        return """
        ● nginx.service - A high performance web server and a reverse proxy server
             Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
               Docs: man:nginx(8)
           Process: 12345 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
           Process: 12346 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
           Main PID: 12347 (nginx)
              Tasks: 3 (limit: 19149)
             Memory: 5.2M
             CGroup: /system.slice/nginx.service
                     ├─12347 nginx: master process /usr/sbin/nginx
                     ├─12348 nginx: worker process
                     └─12349 nginx: worker process
        
        """
    }
    
    static func generateDockerStatus() -> String {
        return """
        ● docker.service - Docker Application Container Engine
             Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
               Docs: https://docs.docker.com
           Main PID: 12350 (dockerd)
              Tasks: 12
             Memory: 45.2M
             CGroup: /system.slice/docker.service
                     └─12350 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
        
        """
    }
    
    static func generateMySQLStatus() -> String {
        return """
        ● mysql.service - MySQL Community Server
             Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
           Process: 12351 ExecStartPre=/usr/share/mysql/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
           Main PID: 12352 (mysqld)
              Tasks: 38 (limit: 19149)
             Memory: 350.0M
             CGroup: /system.slice/mysql.service
                     └─12352 /usr/sbin/mysqld
        
        """
    }
    
    static func generateRedisStatus() -> String {
        return """
        ● redis.service - Redis In-Memory Data Store
             Loaded: loaded (/lib/systemd/system/redis.service; disabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 1h ago
           Main PID: 12353 (redis-server)
              Tasks: 4
             Memory: 8.0M
             CGroup: /system.slice/redis.service
                     └─12353 /usr/bin/redis-server 127.0.0.1:6379
        
        """
    }
    
    static func generateApacheStatus() -> String {
        return """
        ● apache2.service - The Apache HTTP Server
             Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
           Process: 12354 ExecStop=/usr/sbin/apachectl stop (code=exited, status=0/SUCCESS)
           Process: 12355 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
           Main PID: 12356 (apache2)
              Tasks: 5
             Memory: 15.0M
             CGroup: /system.slice/apache2.service
                     ├─12356 /usr/sbin/apache2 -k start
                     ├─12357 /usr/sbin/apache2 -k start
                     └─12358 /usr/sbin/apache2 -k start
        
        """
    }
    
    static func generateCronStatus() -> String {
        return """
        ● cron.service - Regular background program processing daemon
             Loaded: loaded (/lib/systemd/system/cron.service; enabled; vendor preset: enabled)
             Active: active (running) since \(Date().formatted(date: .abbreviated, time: .shortened)); 2h ago
               Docs: man:cron(8)
           Main PID: 12359 (cron)
              Tasks: 1
             Memory: 1.5M
             CGroup: /system.slice/cron.service
                     └─12359 /usr/sbin/cron -f
        
        """
    }
    
    static func generateShowSSH() -> String {
        return """
        Type=service
        Name=ssh.service
        MainPID=1234
        ExecMainStatus=0
        ExecMainCode=0
        ActiveState=active
        SubState=running
        UnitFileState=enabled
        LoadState=loaded
        
        """
    }
    
    static func generateCatSSH() -> String {
        return """
        # /lib/systemd/system/ssh.service
        [Unit]
        Description=OpenBSD Secure Shell server
        Documentation=man:sshd(8) man:sshd_config(5)
        After=network.target auditd.service
        ConditionPathExists=/etc/ssh/sshd_not_to_be_run
        
        [Service]
        EnvironmentFile=-/etc/default/ssh
        ExecStart=/usr/sbin/sshd -D $SSHD_OPTS
        ExecReload=/usr/sbin/sshd -t
        KillMode=process
        Restart=on-failure
        
        [Install]
        WantedBy=multi-user.target
        
        """
    }
    
    static func generateServiceStatusAll() -> String {
        return """
        [ + ]  acpid
        [ + ]  apache2
        [ + ]  cron
        [ + ]  docker
        [ + ]  mysql
        [ + ]  nginx
        [ + ]  redis
        [ + ]  ssh
        [ - ]  bluetooth
        
        """
    }
    
    static func generateCrontab() -> String {
        return """
        # m h  dom mon dow   command
        0 5 * * 1   tar -zcf /var/backups/home.tgz /home/
        0 0 * * *   /usr/local/bin/backup.sh
        @reboot     /usr/local/bin/startup.sh
        
        """
    }
    
    static func generateChkconfigList() -> String {
        return """
        sshd            0:off   1:off   2:on    3:on    4:on    5:on    6:off
        nginx           0:off   1:off   2:on    3:on    4:on    5:on    6:off
        mysql           0:off   1:off   2:on    3:on    4:on    5:on    6:off
        docker          0:off   1:off   2:on    3:on    4:on    5:on    6:off
        
        """
    }
}