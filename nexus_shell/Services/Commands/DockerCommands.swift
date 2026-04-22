//
//  DockerCommands.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// Docker 命令模拟
enum DockerCommands {
    
    static func execute(_ command: String) -> String? {
        switch command {
        case "docker":
            return DockerGenerator.generateHelp()
        case "docker --version":
            return "Docker version 24.0.5, build 24.0.5-0ubuntu1~22.04.1\n"
        case "docker version":
            return DockerGenerator.generateVersion()
        case "docker info":
            return DockerGenerator.generateInfo()
        case "docker ps":
            return DockerGenerator.generatePS()
        case "docker ps -a":
            return DockerGenerator.generatePSAll()
        case "docker ps -q":
            return "a1b2c3d4e5f6\nb2c3d4e5f6a7\n"
        case "docker ps --format '{{.Names}}'":
            return "web-server\napi-server\n"
        case "docker images":
            return DockerGenerator.generateImages()
        case "docker images -a":
            return DockerGenerator.generateImagesAll()
        case "docker images -q":
            return "def0a1b2c3d4\nabc1b2c3d4e5\n"
        case "docker images --format '{{.Repository}}:{{.Tag}}'":
            return "nginx:latest\nredis:latest\n"
        case "docker logs":
            return "Usage:  docker logs [OPTIONS] CONTAINER\n"
        case "docker logs web-server":
            return DockerGenerator.generateLogsWebServer()
        case "docker logs api-server":
            return DockerGenerator.generateLogsAPIServer()
        case "docker logs --tail 20 web-server":
            return DockerGenerator.generateLogsWebServer()
        case "docker exec":
            return "Usage:  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]\n"
        case "docker exec -it web-server bash":
            return "root@web-server:/# \n"
        case "docker exec web-server ls":
            return DockerGenerator.generateLS()
        case "docker stats":
            return DockerGenerator.generateStats()
        case "docker stats --no-stream":
            return DockerGenerator.generateStats()
        case "docker stats web-server":
            return DockerGenerator.generateStatsSingle()
        case "docker network ls":
            return DockerGenerator.generateNetworkLS()
        case "docker network create my-network":
            return "a1b2c3d4e5f6\n"
        case "docker volume ls":
            return DockerGenerator.generateVolumeLS()
        case "docker volume create my-volume":
            return "a1b2c3d4e5f6\n"
        case "docker compose":
            return "Usage:  docker compose [OPTIONS] COMMAND\n"
        case "docker compose ps":
            return DockerGenerator.generateComposePS()
        case "docker compose logs":
            return DockerGenerator.generateComposeLogs()
        case "docker compose up":
            return "Creating network \"my-project_default\" with the default driver\nCreating my-project_web_1 ... done\nCreating my-project_api_1 ... done\n"
        case "docker compose down":
            return "Stopping my-project_web_1 ... done\nRemoving my-project_web_1 ... done\nRemoving network my-project_default\n"
        case "docker build":
            return "Usage:  docker build [OPTIONS] PATH | URL | -\n"
        case "docker pull nginx":
            return DockerGenerator.generatePullNginx()
        case "docker pull redis":
            return DockerGenerator.generatePullRedis()
        case "docker push my-image":
            return DockerGenerator.generatePush()
        case "docker stop":
            return "Usage:  docker stop [OPTIONS] CONTAINER [CONTAINER...]\n"
        case "docker stop web-server":
            return "web-server\n"
        case "docker start":
            return "Usage:  docker start [OPTIONS] CONTAINER [CONTAINER...]\n"
        case "docker start web-server":
            return "web-server\n"
        case "docker rm":
            return "Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]\n"
        case "docker rm web-server":
            return "web-server\n"
        case "docker rmi":
            return "Usage:  docker rmi [OPTIONS] IMAGE [IMAGE...]\n"
        case "docker rmi nginx":
            return "Untagged: nginx:latest\nDeleted: sha256:def0a1b2c3d4\n"
        case "docker inspect":
            return "Usage:  docker inspect [OPTIONS] NAME|ID [NAME|ID...]\n"
        case "docker inspect web-server":
            return DockerGenerator.generateInspect()
        case "docker cp":
            return "Usage:  docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-\n"
        case "docker top web-server":
            return DockerGenerator.generateTop()
        case "docker port web-server":
            return "80/tcp -> 0.0.0.0:8080\n443/tcp -> 0.0.0.0:8443\n"
        case "docker history nginx":
            return DockerGenerator.generateHistory()
        case "docker save nginx":
            return "Saved image to file: nginx.tar\n"
        case "docker load":
            return "Loaded image: nginx:latest\n"
        case "docker search nginx":
            return DockerGenerator.generateSearchNginx()
        case "docker system df":
            return DockerGenerator.generateSystemDF()
        case "docker system prune":
            return "WARNING! This will remove:\n  - all stopped containers\n  - all networks not used by at least one container\n  - all dangling images\n  - all dangling build cache\nTotal reclaimed space: 5GB\n"
        case "docker container ls":
            return DockerGenerator.generatePS()
        case "docker container stats":
            return DockerGenerator.generateStats()
        case "docker image ls":
            return DockerGenerator.generateImages()
        default:
            return nil
        }
    }
}

/// Docker 生成器
enum DockerGenerator {
    
    static func generateHelp() -> String {
        return """
        Usage:  docker [OPTIONS] COMMAND
        
        A self-sufficient runtime for containers
        
        Common Commands:
          run         Run a container from an image
          exec        Run a command in a running container
          ps          List containers
          build       Build an image from a Dockerfile
          pull        Pull an image from a registry
          push        Push an image to a registry
          images      List images
          logs        View logs of a container
          stats       Display resource usage statistics
          stop        Stop one or more running containers
          start       Start one or more stopped containers
        
        Management Commands:
          container   Manage containers
          image       Manage images
          network     Manage networks
          volume      Manage volumes
          system      Manage Docker
        
        Run 'docker COMMAND --help' for more information on a command.
        
        """
    }
    
    static func generateVersion() -> String {
        return """
        Client:
         Version:           24.0.5
         API version:       1.43
         Go version:        go1.20.7
         Git commit:        24.0.5-0ubuntu1~22.04.1
         Built:             Wed Jul 26 12:00:00 2026
         OS/Arch:           linux/amd64
         Context:           default
        
        Server:
         Engine:
          Version:          24.0.5
          API version:      1.43 (minimum version 1.12)
          Go version:       go1.20.7
          Git commit:       24.0.5-0ubuntu1~22.04.1
          Built:            Wed Jul 26 12:00:00 2026
          OS/Arch:          linux/amd64
          Experimental:     false
        
        """
    }
    
    static func generateInfo() -> String {
        return """
        Client:
         Context:    default
         Debug Mode: false
        
        Server:
         Containers: 5
          Running: 2
          Paused: 0
          Stopped: 3
         Images: 10
         Server Version: 24.0.5
         Storage Driver: overlay2
         Backing Filesystem: extfs
         Supports d_type: true
         Logging Driver: json-file
         Cgroup Driver: cgroupfs
         Cgroup Version: 2
         Plugins:
          Volume: local
          Network: bridge host ipvlan macvlan null overlay
          Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
         Kernel Version: 5.15.0-generic
         Operating System: Ubuntu 22.04.3 LTS
         OSType: linux
         Architecture: x86_64
         CPUs: 4
         Total Memory: 2GiB
         Name: server
         ID: a1b2c3d4-e5f6-1234-5678-abcdef012345
        
        """
    }
    
    static func generatePS() -> String {
        return """
        CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS        PORTS                NAMES
        a1b2c3d4e5f6   nginx:latest   "/docker-entrypoint.…"   2 hours ago    Up 2 hours    0.0.0.0:80->80/tcp   web-server
        b2c3d4e5f6a7   redis:latest   "redis-server"           1 hour ago     Up 1 hour     6379/tcp             redis-cache
        
        """
    }
    
    static func generatePSAll() -> String {
        return """
        CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS                     PORTS                NAMES
        a1b2c3d4e5f6   nginx:latest   "/docker-entrypoint.…"   2 hours ago    Up 2 hours                 0.0.0.0:80->80/tcp   web-server
        b2c3d4e5f6a7   redis:latest   "redis-server"           1 hour ago     Up 1 hour                  6379/tcp             redis-cache
        c3d4e5f6a7b8   ubuntu:22.04   "bash"                   3 hours ago    Exited (0) 3 hours ago                          test-container
        
        """
    }
    
    static func generateImages() -> String {
        return """
        REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
        nginx        latest    def0a1b2c3d4   2 weeks ago    142MB
        redis        latest    abc1b2c3d4e5   3 weeks ago    117MB
        ubuntu       22.04     1234567890ab   1 month ago    77.8MB
        alpine       latest    34567890abcd   2 months ago   5.53MB
        
        """
    }
    
    static func generateImagesAll() -> String {
        return """
        REPOSITORY          TAG       IMAGE ID       CREATED        SIZE
        nginx               latest    def0a1b2c3d4   2 weeks ago    142MB
        redis               latest    abc1b2c3d4e5   3 weeks ago    117MB
        ubuntu              22.04     1234567890ab   1 month ago    77.8MB
        alpine              latest    34567890abcd   2 months ago   5.53MB
        <none>              <none>    567890abcdef   3 months ago   100MB
        
        """
    }
    
    static func generateLogsWebServer() -> String {
        return """
        2026-04-22 10:00:01 [info] Starting nginx server...
        2026-04-22 10:00:02 [info] Listening on port 80
        2026-04-22 10:05:01 [info] Request from 192.168.1.1
        2026-04-22 10:10:01 [info] Request from 192.168.1.2
        2026-04-22 10:15:01 [info] Request from 192.168.1.3
        
        """
    }
    
    static func generateLogsAPIServer() -> String {
        return """
        2026-04-22 10:00:01 [info] Starting API server...
        2026-04-22 10:00:02 [info] Database connected
        2026-04-22 10:05:01 [info] GET /api/users 200
        2026-04-22 10:10:01 [info] POST /api/users 201
        2026-04-22 10:15:01 [warn] Rate limit exceeded
        
        """
    }
    
    static func generateLS() -> String {
        return "bin\nboot\ndev\netc\nhome\nlib\nmedia\nmnt\nopt\nproc\nroot\nrun\nsbin\nsrv\nsys\ntmp\nusr\nvar\n"
    }
    
    static func generateStats() -> String {
        return """
        CONTAINER ID   NAME          CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
        a1b2c3d4e5f6   web-server    2.5%      50MiB / 2GiB          2.5%      1.2MB / 500KB     0B / 0B     5
        b2c3d4e5f6a7   redis-cache   0.5%      20MiB / 2GiB          1.0%      100KB / 50KB      0B / 0B     1
        
        """
    }
    
    static func generateStatsSingle() -> String {
        return """
        CONTAINER ID   NAME          CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
        a1b2c3d4e5f6   web-server    2.5%      50MiB / 2GiB          2.5%      1.2MB / 500KB     0B / 0B     5
        
        """
    }
    
    static func generateNetworkLS() -> String {
        return """
        NETWORK ID     NAME      DRIVER    SCOPE
        a1b2c3d4e5f6   bridge    bridge    local
        b2c3d4e5f6a7   host      host      local
        c3d4e5f6a7b8   none      null      local
        
        """
    }
    
    static func generateVolumeLS() -> String {
        return """
        DRIVER    VOLUME NAME
        local     my-volume
        local     app-data
        
        """
    }
    
    static func generateComposePS() -> String {
        return """
        NAME                IMAGE          SERVICE   CREATED        STATUS        PORTS
        my-project_web_1    nginx:latest   web       2 hours ago    Up 2 hours    0.0.0.0:80->80/tcp
        my-project_api_1    python:3.9     api       2 hours ago    Up 2 hours    0.0.0.0:5000->5000/tcp
        
        """
    }
    
    static func generateComposeLogs() -> String {
        return generateLogsWebServer() + generateLogsAPIServer()
    }
    
    static func generatePullNginx() -> String {
        return """
        latest: Pulling from library/nginx
        Digest: sha256:def0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8
        Status: Downloaded newer image for nginx:latest
        docker.io/library/nginx:latest
        
        """
    }
    
    static func generatePullRedis() -> String {
        return """
        latest: Pulling from library/redis
        Digest: sha256:abc1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8
        Status: Downloaded newer image for redis:latest
        docker.io/library/redis:latest
        
        """
    }
    
    static func generatePush() -> String """
        The push refers to repository [docker.io/my-image]
        a1b2c3d4e5f6: Preparing
        a1b2c3d4e5f6: Pushing [>                                                 ] 0B/50MB
        a1b2c3d4e5f6: Pushed
        latest: digest: sha256:1234567890abcdef size: 1234
        
        """
    }
    
    static func generateInspect() -> String {
        return """
        [
            {
                "Id": "a1b2c3d4e5f6",
                "Created": "2026-04-22T10:00:00.000000000Z",
                "Path": "/docker-entrypoint.sh",
                "Args": ["nginx"],
                "State": {
                    "Status": "running",
                    "Running": true,
                    "Paused": false,
                    "Restarting": false,
                    "StartedAt": "2026-04-22T10:00:01.000000000Z"
                },
                "Image": "sha256:def0a1b2c3d4",
                "NetworkSettings": {
                    "Ports": {
                        "80/tcp": [{"HostIp": "0.0.0.0", "HostPort": "80"}]
                    }
                }
            }
        ]
        
        """
    }
    
    static func generateTop() -> String {
        return """
        UID    PID     PPID    C    STIME   TTY    TIME        CMD
        root   12347   1234    2    10:00   ?      00:00:10    nginx: worker process
        root   12348   12347   0    10:00   ?      00:00:00    nginx: master process
        
        """
    }
    
    static func generateHistory() -> String {
        return """
        IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
        def0a1b2c3d4   2 weeks ago    /bin/sh -c #(nop)  CMD ["nginx"]                0B        
        def0a1b2c3d4   2 weeks ago    /bin/sh -c #(nop)  EXPOSE 80/tcp               0B        
        def0a1b2c3d4   2 weeks ago    /bin/sh -c #(nop) COPY . /usr/share/nginx/html  25MB      
        
        """
    }
    
    static func generateSearchNginx() -> String {
        return """
        NAME                DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
        nginx               Official build of Nginx.                         15000     [OK]       
        bitnami/nginx       Bitnami nginx Docker Image                       100                  [OK]
        nginxinc/nginx      NGINX Docker Image by nginx inc.                 50                   [OK]
        
        """
    }
    
    static func generateSystemDF() -> String {
        return """
        TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
        Images          10        5         500MB     250MB (50%)
        Containers      5         2         100MB     80MB (80%)
        Local Volumes   2         2         200MB     0B (0%)
        Build Cache     50        0         1GB       1GB (100%)
        
        """
    }
}