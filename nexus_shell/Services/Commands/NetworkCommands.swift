//
//  NetworkCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 网络命令模拟
enum NetworkCommands {
    
    static func execute(_ command: String, host: String) -> String? {
        switch command {
        case "ifconfig":
            return NetworkGenerator.generateIfconfig(host: host)
        case "ip addr":
            return NetworkGenerator.generateIPAddr(host: host)
        case "ip a":
            return NetworkGenerator.generateIPAddr(host: host)
        case "ip address":
            return NetworkGenerator.generateIPAddr(host: host)
        case "ip route":
            return NetworkGenerator.generateIPRoute()
        case "ip r":
            return NetworkGenerator.generateIPRoute()
        case "ip link":
            return NetworkGenerator.generateIPLink()
        case "ip link show":
            return NetworkGenerator.generateIPLink()
        case "route":
            return NetworkGenerator.generateRoute()
        case "route -n":
            return NetworkGenerator.generateRouteNumeric()
        case "netstat":
            return NetworkGenerator.generateNetstat()
        case "netstat -tuln":
            return NetworkGenerator.generateNetstatPorts()
        case "netstat -an":
            return NetworkGenerator.generateNetstatAll()
        case "netstat -s":
            return NetworkGenerator.generateNetstatStats()
        case "ss":
            return NetworkGenerator.generateSS()
        case "ss -tuln":
            return NetworkGenerator.generateSSPorts()
        case "ss -an":
            return NetworkGenerator.generateSSAll()
        case "ss -s":
            return NetworkGenerator.generateSSSummary()
        case "arp":
            return NetworkGenerator.generateARP()
        case "arp -a":
            return NetworkGenerator.generateARPAll()
        case "arp -n":
            return NetworkGenerator.generateARPNumeric()
        case "ping -c 4 localhost":
            return NetworkGenerator.generatePingLocal()
        case "ping -c 4 127.0.0.1":
            return NetworkGenerator.generatePingLocal()
        case "ping -c 4 8.8.8.8":
            return NetworkGenerator.generatePingGoogleDNS()
        case "ping -c 4 google.com":
            return NetworkGenerator.generatePingGoogle()
        case "ping localhost":
            return "PING localhost (127.0.0.1) 56(84) bytes of data.\n(Press Ctrl+C to stop)\n"
        case "traceroute localhost":
            return NetworkGenerator.generateTracerouteLocal()
        case "traceroute 8.8.8.8":
            return NetworkGenerator.generateTracerouteDNS()
        case "traceroute google.com":
            return NetworkGenerator.generateTracerouteGoogle()
        case "tracepath 8.8.8.8":
            return NetworkGenerator.generateTracepathDNS()
        case "nslookup localhost":
            return NetworkGenerator.generateNSLookupLocal()
        case "nslookup google.com":
            return NetworkGenerator.generateNSLookupGoogle()
        case "nslookup 8.8.8.8":
            return NetworkGenerator.generateNSLookupIP()
        case "dig localhost":
            return NetworkGenerator.generateDigLocal()
        case "dig google.com":
            return NetworkGenerator.generateDigGoogle()
        case "dig @8.8.8.8 google.com":
            return NetworkGenerator.generateDigGoogleDNS()
        case "host localhost":
            return "localhost has address 127.0.0.1\n"
        case "host google.com":
            return NetworkGenerator.generateHostGoogle()
        case "hostname -I":
            return "192.168.1.100 10.0.0.1\n"
        case "curl --version":
            return "curl 7.81.0 (x86_64-pc-linux-gnu) libcurl/7.81.0 OpenSSL/3.0.2 zlib/1.2.11 brotli/1.0.9\n"
        case "wget --version":
            return "GNU Wget 1.21 built on linux-gnu.\n"
        case "curl http://localhost":
            return "HTTP/1.1 200 OK\nContent-Type: text/html\n\n<!DOCTYPE html><html><body>Welcome!</body></html>\n"
        case "curl -I http://localhost":
            return "HTTP/1.1 200 OK\nServer: nginx/1.18.0\nContent-Type: text/html\nConnection: keep-alive\n"
        case "nmap localhost":
            return NetworkGenerator.generateNmapLocal()
        case "nmap -sV localhost":
            return NetworkGenerator.generateNmapVersion()
        case "tcpdump -i eth0":
            return "tcpdump: listening on eth0, link-type EN10MB, snapshot length 262144 bytes\n(Press Ctrl+C to stop)\n"
        case "tcpdump -i eth0 -c 5":
            return NetworkGenerator.generateTCPDump()
        case "iptables -L":
            return NetworkGenerator.generateIPTables()
        case "iptables -L -n":
            return NetworkGenerator.generateIPTablesNumeric()
        case "iptables -S":
            return NetworkGenerator.generateIPTablesRules()
        case "ufw status":
            return NetworkGenerator.generateUFWStatus()
        case "ufw status verbose":
            return NetworkGenerator.generateUFWVerbose()
        case "ufw app list":
            return NetworkGenerator.generateUFWApps()
        case "iwconfig":
            return "lo        no wireless extensions.\neth0      no wireless extensions.\n"
        case "iwlist scan":
            return "lo        Interface doesn't support scanning.\neth0      Interface doesn't support scanning.\n"
        case "nmcli device status":
            return NetworkGenerator.generateNMCLIDevices()
        case "nmcli connection show":
            return NetworkGenerator.generateNMCLIConnections()
        default:
            return nil
        }
    }
}

/// 网络生成器
enum NetworkGenerator {
    
    static func generateIfconfig(host: String) -> String {
        return """
        eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
                inet 192.168.1.100  netmask 255.255.255.0  broadcast 192.168.1.255
                inet6 fe80::a00:27ff:fe5e:1e1a  prefixlen 64  scopeid 0x20<link>
                ether 00:0c:29:5e:1e:1a  txqueuelen 1000  (Ethernet)
                RX packets 10000  bytes 5000000 (5.0 MB)
                RX errors 0  dropped 0  overruns 0  frame 0
                TX packets 5000  bytes 2500000 (2.5 MB)
                TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        
        lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
                inet 127.0.0.1  netmask 255.0.0.0
                inet6 ::1  prefixlen 128  scopeid 0x10<host>
                loop  txqueuelen 1000  (Local Loopback)
                RX packets 100  bytes 5000 (5.0 KB)
                RX errors 0  dropped 0  overruns 0  frame 0
                TX packets 100  bytes 5000 (5.0 KB)
                TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        
        """
    }
    
    static func generateIPAddr(host: String) -> String {
        return """
        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
            inet 127.0.0.1/8 scope host lo
               valid_lft forever preferred_lft forever
            inet6 ::1/128 scope host lo
               valid_lft forever preferred_lft forever
        2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
            link/ether 00:0c:29:5e:1e:1a brd ff:ff:ff:ff:ff:ff
            inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0
               valid_lft 86399sec preferred_lft 86399sec
            inet6 fe80::a00:27ff:fe5e:1e1a/64 scope link
               valid_lft forever preferred_lft forever
        
        """
    }
    
    static func generateIPRoute() -> String {
        return """
        default via 192.168.1.1 dev eth0 proto dhcp metric 100
        192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100 metric 100
        10.0.0.0/8 dev eth0 proto kernel scope link src 10.0.0.1 metric 100
        
        """
    }
    
    static func generateIPLink() -> String {
        return """
        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
            link/ether 00:0c:29:5e:1e:1a brd ff:ff:ff:ff:ff:ff
        
        """
    }
    
    static func generateRoute() -> String {
        return """
        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        default         gateway         0.0.0.0         UG    100    0        0 eth0
        192.168.1.0     *               255.255.255.0   U     100    0        0 eth0
        
        """
    }
    
    static func generateRouteNumeric() -> String {
        return """
        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        0.0.0.0         192.168.1.1     0.0.0.0         UG    100    0        0 eth0
        192.168.1.0     0.0.0.0         255.255.255.0   U     100    0        0 eth0
        
        """
    }
    
    static func generateNetstat() -> String {
        return """
        Active Internet connections (w/o servers)
        Proto Recv-Q Send-Q Local Address           Foreign Address         State
        tcp        0      0 server:ssh              192.168.1.1:54321      ESTABLISHED
        
        Active UNIX domain sockets (w/o servers)
        Proto RefCnt Flags       Type       State         I-Node   Path
        unix  3      [ ]         DGRAM                    12345    /run/systemd/notify
        
        """
    }
    
    static func generateNetstatPorts() -> String {
        return """
        Active Internet connections (only servers)
        Proto Recv-Q Send-Q Local Address           Foreign Address         State
        tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
        tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN
        tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN
        tcp6       0      0 :::22                   :::*                    LISTEN
        tcp6       0      0 :::80                   :::*                    LISTEN
        udp        0      0 0.0.0.0:68              0.0.0.0:*               
        udp        0      0 0.0.0.0:123             0.0.0.0:*               
        
        """
    }
    
    static func generateNetstatAll() -> String {
        return generateNetstatPorts() + generateNetstat()
    }
    
    static func generateNetstatStats() -> String {
        return """
        Ip:
            Forwarding: 1
            1000 total packets received
            0 forwarded
        
        Icmp:
            100 ICMP messages received
            50 input ICMP message failed
        
        Tcp:
            500 active connections openings
            100 passive connection openings
            0 failed connection attempts
        
        Udp:
            100 packets received
            0 packets to unknown port received
        
        """
    }
    
    static func generateNetstatFiltered(_ pattern: String) -> String {
        return generateNetstatPorts()
    }
    
    static func generateSS() -> String {
        return """
        Netid State  Recv-Q Send-Q  Local Address:Port    Peer Address:Port  Process
        tcp   ESTAB  0      0       192.168.1.100:ssh     192.168.1.1:54321
        
        """
    }
    
    static func generateSSPorts() -> String {
        return """
        Netid State  Recv-Q Send-Q  Local Address:Port    Peer Address:Port  Process
        tcp   LISTEN 0      128           0.0.0.0:22           0.0.0.0:*
        tcp   LISTEN 0      128           0.0.0.0:80           0.0.0.0:*
        tcp   LISTEN 0      128           0.0.0.0:443          0.0.0.0:*
        tcp   LISTEN 0      128              [::]:22              [::]:*
        
        """
    }
    
    static func generateSSAll() -> String {
        return generateSSPorts() + generateSS()
    }
    
    static func generateSSSummary() -> String {
        return """
        Total: 85 (kernel 0, TCP: 10, in_tcp: 5, in_tcp_listen: 5)
        TCP:   10 (estab 5, closed 0, orphaned 0, synrecv 0, timewait 0)
        UDP:   5 (estab 5, closed 0, orphaned 0)
        
        """
    }
    
    static func generateARP() -> String {
        return """
        Address                  HWtype  HWaddress           Flags Mask            Iface
        gateway                  ether   00:11:22:33:44:55   C                     eth0
        _gateway                 ether   00:11:22:33:44:55   C                     eth0
        
        """
    }
    
    static func generateARPAll() -> String {
        return """
        gateway (192.168.1.1) at 00:11:22:33:44:55 [ether] on eth0
        ? (192.168.1.10) at 00:11:22:33:44:56 [ether] on eth0
        
        """
    }
    
    static func generateARPNumeric() -> String {
        return """
        Address                  HWtype  HWaddress           Flags Mask            Iface
        192.168.1.1              ether   00:11:22:33:44:55   C                     eth0
        192.168.1.10             ether   00:11:22:33:44:56   C                     eth0
        
        """
    }
    
    static func generatePingLocal() -> String {
        return """
        PING localhost (127.0.0.1) 56(84) bytes of data.
        64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.021 ms
        64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.018 ms
        64 bytes from localhost (127.0.0.1): icmp_seq=3 ttl=64 time=0.015 ms
        64 bytes from localhost (127.0.0.1): icmp_seq=4 ttl=64 time=0.012 ms
        
        --- localhost ping statistics ---
        4 packets transmitted, 4 received, 0% packet loss, time 3068ms
        rtt min/avg/max/mdev = 0.012/0.016/0.021/0.003 ms
        
        """
    }
    
    static func generatePingGoogleDNS() -> String {
        return """
        PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
        64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=12.5 ms
        64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=11.8 ms
        64 bytes from 8.8.8.8: icmp_seq=3 ttl=117 time=13.2 ms
        64 bytes from 8.8.8.8: icmp_seq=4 ttl=117 time=12.1 ms
        
        --- 8.8.8.8 ping statistics ---
        4 packets transmitted, 4 received, 0% packet loss, time 3007ms
        rtt min/avg/max/mdev = 11.8/12.4/13.2/0.5 ms
        
        """
    }
    
    static func generatePingGoogle() -> String {
        return """
        PING google.com (142.250.185.46) 56(84) bytes of data.
        64 bytes from 142.250.185.46: icmp_seq=1 ttl=117 time=15.2 ms
        64 bytes from 142.250.185.46: icmp_seq=2 ttl=117 time=14.8 ms
        64 bytes from 142.250.185.46: icmp_seq=3 ttl=117 time=16.1 ms
        64 bytes from 142.250.185.46: icmp_seq=4 ttl=117 time=14.9 ms
        
        --- google.com ping statistics ---
        4 packets transmitted, 4 received, 0% packet loss, time 3012ms
        rtt min/avg/max/mdev = 14.8/15.2/16.1/0.5 ms
        
        """
    }
    
    static func generateTracerouteLocal() -> String {
        return "traceroute to localhost (127.0.0.1), 30 hops max, 60 byte packets\n 1  localhost (127.0.0.1)  0.021 ms  0.005 ms  0.003 ms\n"
    }
    
    static func generateTracerouteDNS() -> String {
        return """
        traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
         1  gateway (192.168.1.1)  0.521 ms  0.412 ms  0.325 ms
         2  10.0.0.1 (10.0.0.1)  1.234 ms  1.123 ms  1.012 ms
         3  8.8.8.8 (8.8.8.8)  12.5 ms  11.8 ms  13.2 ms
        
        """
    }
    
    static func generateTracerouteGoogle() -> String {
        return """
        traceroute to google.com (142.250.185.46), 30 hops max, 60 byte packets
         1  gateway (192.168.1.1)  0.521 ms  0.412 ms  0.325 ms
         2  10.0.0.1 (10.0.0.1)  1.234 ms  1.123 ms  1.012 ms
         3  142.250.185.46 (142.250.185.46)  15.2 ms  14.8 ms  16.1 ms
        
        """
    }
    
    static func generateTracepathDNS() -> String {
        return """
         1?: [LOCALHOST]                      pmtu 1500
         1:  gateway (192.168.1.1)                              0.521ms
         2:  10.0.0.1 (10.0.0.1)                                1.234ms
         3:  8.8.8.8 (8.8.8.8)                                  12.5ms
            Resume: pmtu 1500 hops 3 back 3
        
        """
    }
    
    static func generateNSLookupLocal() -> String {
        return """
        Server:         127.0.0.53
        Address:        127.0.0.53#53
        
        Non-authoritative answer:
        Name:   localhost
        Address: 127.0.0.1
        
        """
    }
    
    static func generateNSLookupGoogle() -> String {
        return """
        Server:         8.8.8.8
        Address:        8.8.8.8#53
        
        Non-authoritative answer:
        Name:   google.com
        Address: 142.250.185.46
        Name:   google.com
        Address: 2607:f8b0:4004:800::200e
        
        """
    }
    
    static func generateNSLookupIP() -> String {
        return """
        Server:         8.8.8.8
        Address:        8.8.8.8#53
        
        Non-authoritative answer:
        8.8.8.8.in-addr.arpa      name = dns.google.
        
        """
    }
    
    static func generateDigLocal() -> String {
        return """
        ; <<>> DiG 9.18.1-1ubuntu1.1-Ubuntu <<>> localhost
        ;; global options: +cmd
        ;; Got answer:
        ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
        ;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
        
        ;; QUESTION SECTION:
        ;localhost.                     IN      A
        
        ;; ANSWER SECTION:
        localhost.              0       IN      A       127.0.0.1
        
        ;; Query time: 0 msec
        ;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
        ;; WHEN: \(Date().formatted(date: .abbreviated, time: .shortened))
        ;; MSG SIZE  rcvd: 46
        
        """
    }
    
    static func generateDigGoogle() -> String {
        return """
        ; <<>> DiG 9.18.1-1ubuntu1.1-Ubuntu <<>> google.com
        ;; global options: +cmd
        ;; Got answer:
        ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
        ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
        
        ;; QUESTION SECTION:
        ;google.com.                     IN      A
        
        ;; ANSWER SECTION:
        google.com.              299     IN      A       142.250.185.46
        
        ;; Query time: 12 msec
        ;; SERVER: 8.8.8.8#53(8.8.8.8) (UDP)
        ;; WHEN: \(Date().formatted(date: .abbreviated, time: .shortened))
        ;; MSG SIZE  rcvd: 56
        
        """
    }
    
    static func generateDigGoogleDNS() -> String {
        return generateDigGoogle()
    }
    
    static func generateHostGoogle() -> String {
        return "google.com has address 142.250.185.46\ngoogle.com has IPv6 address 2607:f8b0:4004:800::200e\ngoogle.com mail is handled by 10 smtp.google.com.\n"
    }
    
    static func generateNmapLocal() -> String {
        return """
        Starting Nmap 7.80 ( https://nmap.org ) at \(Date().formatted(date: .abbreviated, time: .shortened))
        Nmap scan report for localhost (127.0.0.1)
        Host is up (0.0000040s latency).
        Not shown: 997 closed ports
        PORT    STATE SERVICE
        22/tcp  open  ssh
        80/tcp  open  http
        443/tcp open  https
        
        Nmap done: 1 IP address (1 host up) scanned in 0.05 seconds
        
        """
    }
    
    static func generateNmapVersion() -> String {
        return """
        Starting Nmap 7.80 ( https://nmap.org ) at \(Date().formatted(date: .abbreviated, time: .shortened))
        Nmap scan report for localhost (127.0.0.1)
        Host is up (0.0000040s latency).
        
        PORT    STATE SERVICE     VERSION
        22/tcp  open  ssh         OpenSSH 8.2p1 Ubuntu 4ubuntu0.5
        80/tcp  open  http        nginx 1.18.0
        443/tcp open  ssl/http    nginx 1.18.0
        
        Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
        Nmap done: 1 IP address (1 host up) scanned in 6.12 seconds
        
        """
    }
    
    static func generateTCPDump() -> String {
        return """
        tcpdump: listening on eth0, link-type EN10MB, snapshot length 262144 bytes
        10:00:01.000000 IP 192.168.1.1.54321 > 192.168.1.100.22: Flags [S], seq 12345
        10:00:01.000100 IP 192.168.1.100.22 > 192.168.1.1.54321: Flags [S.], seq 54321
        10:00:01.000200 IP 192.168.1.1.54321 > 192.168.1.100.22: Flags [.], ack 1
        10:00:01.000300 IP 192.168.1.100.22 > 192.168.1.1.54321: Flags [P.], seq 1:100
        10:00:01.000400 IP 192.168.1.1.54321 > 192.168.1.100.22: Flags [.], ack 100
        5 packets captured
        5 packets received by filter
        0 packets dropped by kernel
        
        """
    }
    
    static func generateIPTables() -> String {
        return """
        Chain INPUT (policy ACCEPT)
        target     prot opt source               destination
        ACCEPT     all  --  anywhere             anywhere
        ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:ssh
        ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:http
        
        Chain FORWARD (policy ACCEPT)
        target     prot opt source               destination
        
        Chain OUTPUT (policy ACCEPT)
        target     prot opt source               destination
        
        """
    }
    
    static func generateIPTablesNumeric() -> String {
        return """
        Chain INPUT (policy ACCEPT)
        target     prot opt source               destination
        ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
        ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:22
        ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:80
        
        Chain FORWARD (policy ACCEPT)
        target     prot opt source               destination
        
        Chain OUTPUT (policy ACCEPT)
        target     prot opt source               destination
        
        """
    }
    
    static func generateIPTablesRules() -> String {
        return """
        -P INPUT ACCEPT
        -P FORWARD ACCEPT
        -P OUTPUT ACCEPT
        -A INPUT -j ACCEPT
        -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
        -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
        
        """
    }
    
    static func generateUFWStatus() -> String """
        Status: active
        
        To                         Action      From
        --                         ------      ----
        22/tcp                     ALLOW       Anywhere
        80/tcp                     ALLOW       Anywhere
        443/tcp                    ALLOW       Anywhere
        
        """
    }
    
    static func generateUFWVerbose() -> String {
        return """
        Status: active
        Logging: on (low)
        Default: deny (incoming), allow (outgoing), disabled (routed)
        New profiles: skip
        
        To                         Action      From
        --                         ------      ----
        22/tcp                     ALLOW IN    Anywhere
        80/tcp                     ALLOW IN    Anywhere
        443/tcp                    ALLOW IN    Anywhere
        22/tcp (v6)                ALLOW IN    Anywhere (v6)
        80/tcp (v6)                ALLOW IN    Anywhere (v6)
        
        """
    }
    
    static func generateUFWApps() -> String {
        return """
        Available applications:
          Apache
          Apache Full
          Apache Secure
          OpenSSH
          Nginx Full
          Nginx HTTP
          Nginx Secure
        
        """
    }
    
    static func generateHosts() -> String {
        return """
        127.0.0.1   localhost
        127.0.1.1   server
        
        # The following lines are desirable for IPv6 capable hosts
        ::1         localhost ip6-localhost ip6-loopback
        ff02::1     ip6-allnodes
        ff02::2     ip6-allrouters
        
        """
    }
    
    static func generateResolvConf() -> String {
        return """
        nameserver 8.8.8.8
        nameserver 8.8.4.4
        search local
        
        """
    }
    
    static func generateProcNetTCP() -> String {
        return """
          sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
           0: 0100007F:0016 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 12345 1 0000000000000000 100 0 0 10 0
        
        """
    }
    
    static func generateProcNetDev() -> String {
        return """
        Inter-|   Receive                                                |  Transmit
         face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
            lo:    5000     100    0    0    0     0          0         0     5000     100    0    0    0     0       0          0
          eth0: 5000000  10000    0    0    0     0          0         0  2500000   5000    0    0    0     0       0          0
        
        """
    }
    
    static func generateNMCLIDevices() -> String {
        return """
        DEVICE  TYPE      STATE         CONNECTION
        eth0    ethernet  connected     Wired connection 1
        lo      loopback  unmanaged     --
        
        """
    }
    
    static func generateNMCLIConnections() -> String {
        return """
        NAME                UUID                                  TYPE      DEVICE
        Wired connection 1  12345678-1234-1234-1234-123456789012  ethernet  eth0
        
        """
    }
}