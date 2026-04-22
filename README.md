# Nexus Shell

<div align="center">
  <img src="nexus_shell/Assets.xcassets/AppIcon.appiconset/icon.png" alt="Nexus Shell Logo" width="120" height="120">
  
  <h3>一款现代化的 iOS SSH 客户端</h3>
  
  <p>远程服务器管理与终端模拟，尽在指尖</p>
  
  <p>
    <img src="https://img.shields.io/badge/Platform-iOS%2026.4-blue.svg" alt="Platform">
    <img src="https://img.shields.io/badge/Language-Swift-orange.svg" alt="Language">
    <img src="https://img.shields.io/badge/Framework-SwiftUI-green.svg" alt="Framework">
  </p>
</div>

---

## 📱 功能特性

### 服务器管理
- **多服务器支持** - 添加、编辑、删除多个 SSH 服务器配置
- **文件夹分组** - 按公司、项目或用途组织服务器，支持自定义颜色和图标
- **状态监控** - 实时显示服务器在线状态、CPU 和内存使用率
- **安全认证** - 支持密码认证和 SSH 私钥认证，凭据安全存储于 Keychain

### 终端模拟
- **完整终端体验** - 支持标准 Linux 命令模拟输出
- **命令历史** - 保存执行的命令历史记录
- **快捷工具栏** - ESC、TAB、方向键等常用按键一键输入
- **会话保持** - 切换视图后保持连接状态，无需重复登录

### 实时监控
- **仪表盘概览** - 一览所有服务器状态，在线/警告/离线统计
- **资源图表** - CPU 使用趋势可视化
- **自动刷新** - 可配置的自动刷新间隔（3-30秒）

### 日志记录
- **活动日志** - 记录所有连接、命令执行等操作
- **日志搜索** - 快速搜索定位特定日志
- **自动清理** - 7天自动清理策略，节省存储空间

### 设置与偏好
- **外观主题** - 深色/浅色/跟随系统三种模式
- **多语言支持** - 中文、英文双语界面
- **触感反馈** - 可配置的触觉反馈增强交互体验

---

## 🛠 支持的 Linux 命令

### 文件系统
`ls`, `ls -l`, `ls -la`, `cd`, `pwd`, `cat`, `touch`, `mkdir`, `rm`, `cp`, `mv`, `find`, `which`

### 系统信息
`uname`, `hostname`, `uptime`, `date`, `whoami`, `id`, `w`, `who`, `last`, `lscpu`, `lsblk`, `lsmem`

### 资源监控
`free`, `df`, `du`, `top`, `htop`, `vmstat`, `iostat`, `pidstat`

### 进程管理
`ps`, `ps aux`, `kill`, `killall`, `pgrep`, `pkill`, `pstree`

### 网络
`ifconfig`, `ip addr`, `ip route`, `netstat`, `ss`, `ping`, `traceroute`, `nslookup`, `dig`, `nmap`

### 容器
`docker ps`, `docker images`, `docker logs`, `docker exec`, `docker stats`, `docker compose`

### 服务管理
`systemctl`, `service`, `journalctl`, `crontab`

### 用户管理
`passwd`, `useradd`, `userdel`, `usermod`, `groups`, `lastlog`, `chage`

### 包管理
`apt/apt-get`, `dpkg`, `yum`, `dnf`, `snap`, `pip`, `npm`

### 压缩工具
`tar`, `gzip/gunzip`, `zip/unzip`, `bzip2/bunzip2`, `xz/unxz`, `7z`

### SSH/传输
`ssh-keygen`, `ssh-copy-id`, `scp`, `sftp`, `rsync`

### 系统工具
`lsof`, `nc (netcat)`, `screen`, `tmux`, `nohup`, `watch`, `time`, `dd`, `yes`, `expect`

### 文本处理
`sed`, `awk`, `cut`, `tr`, `rev`, `shuf`, `fmt`, `fold`, `paste`, `join`, `split`, `nl`, `grep`

### 编码校验
`base64`, `md5sum`, `sha256sum`, `sha1sum`, `cksum`, `xxd`, `hexdump`, `od`, `strings`

---

## 📦 项目结构

```
nexus_shell/
├── nexus_shell/
│   ├── nexus_shellApp.swift      # 应用入口
│   ├── Models/                   # 数据模型
│   │   ├── Server.swift          # 服务器模型
│   │   ├── ServerFolder.swift    # 文件夹模型
│   │   ├── ServerSession.swift   # SSH会话模型
│   │   └── LogEntry.swift        # 日志模型
│   ├── Views/                    # SwiftUI 视图
│   │   ├── Dashboard/            # 仪表盘
│   │   ├── Servers/              # 服务器管理
│   │   ├── Terminal/             # 终端界面
│   │   ├── Logs/                 # 日志界面
│   │   ├── Settings/             # 设置界面
│   │   └── MainTabView.swift     # 主标签导航
│   ├── Services/                 # 服务层
│   │   ├── SSHClientManager.swift   # SSH 连接管理
│   │   ├── CommandSimulator.swift   # 命令模拟引擎
│   │   ├── Commands/               # 命令分类实现
│   │   └── KeychainHelper.swift    # 安全存储
│   ├── Data/                     # 数据层
│   │   ├── DatabaseManager.swift   # SQLite 数据库
│   │   ├── ServerRepository.swift  # 服务器仓储
│   │   ├── FolderRepository.swift  # 文件夹仓储
│   │   └── LogRepository.swift     # 日志仓储
│   ├── Settings/                 # 应用设置
│   │   └── AppSettings.swift     # 设置管理
│   ├── Theme/                    # 主题配置
│   │   ├── AppColors.swift       # 颜色定义
│   │   ├── AppTypography.swift   # 字体样式
│   │   └── DesignSystem.swift    # 设计规范
│   └── Assets.xcassets/          # 资源文件
├── nexus_shellTests/             # 单元测试
├── nexus_shellUITests/           # UI 测试
└── nexus_shell.xcodeproj/        # Xcode 项目
```

---

## 🔧 技术栈

| 技术 | 说明 |
|------|------|
| **Swift** | 主要开发语言 |
| **SwiftUI** | 现代化 UI 框架 |
| **SwiftData** | 数据持久化 |
| **SQLite** | 本地数据库存储 |
| **Keychain** | 凭据安全存储 |
| **Combine** | 响应式编程 |

---

## 📋 系统要求

- iOS 26.4 或更高版本
- Xcode 15.0 或更高版本
- macOS 14.0 或更高版本（用于开发）

---

## 🚀 安装与运行

### 克隆项目
```bash
git clone https://github.com/ruY9527/nexus_shell.git
cd nexus_shell
```

### 打开项目
```bash
open nexus_shell.xcodeproj
```

### 编译运行
在 Xcode 中：
1. 选择目标设备（iOS Simulator 或真机）
2. 点击 `Product > Run` 或按 `⌘R`

### 命令行编译
```bash
xcodebuild -project nexus_shell.xcodeproj \
  -scheme nexus_shell \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

---

## 📖 使用指南

### 添加服务器
1. 进入 **Servers** 标签页
2. 点击右上角 `+` 按钮
3. 选择 **New Server**
4. 填写服务器信息：
   - 名称：自定义显示名称
   - 主机：IP 地址或域名
   - 端口：SSH 端口（默认 22）
   - 用户名：登录用户名
   - 认证方式：密码或私钥
5. 点击 **Test Connection** 测试连接
6. 点击 **Save** 保存

### 创建文件夹
1. 进入 **Servers** 标签页
2. 点击右上角 `+` 按钮
3. 选择 **New Folder**
4. 设置文件夹名称、颜色和图标
5. 点击 **Create** 创建

### 连接服务器
1. 进入 **Terminal** 标签页
2. 点击右上角服务器图标
3. 选择要连接的服务器
4. 等待连接建立
5. 开始输入命令

### 查看仪表盘
1. 进入 **Dashboard** 标签页
2. 查看所有服务器状态概览
3. 监控 CPU/内存使用率
4. 点击刷新按钮手动刷新

---

## 🔐 安全性

- 所有密码和私钥存储于 iOS **Keychain**，应用卸载后自动清除
- SSH 连接仅用于命令模拟，不传输真实数据
- 本地 SQLite 数据库加密存储服务器配置

---

## 🌐 国际化

支持语言：
- 🇨🇳 中文（简体）
- 🇺🇸 English

语言切换：进入 **Settings > Appearance > Language**

---

## 📝 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2026.04.22 | 初始版本发布 |

---

## 📄 许可证

本项目采用 MIT 许可证。

---

## 👨‍💻 作者

**baoyang**

- GitHub: [@ruY9527](https://github.com/ruY9527)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

<div align="center">
  <p>Made with ❤️ by baoyang</p>
</div>