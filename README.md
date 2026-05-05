# Nexus Shell

<div align="center">
  <img src="nexus_shell/Assets.xcassets/AppIcon.appiconset/icon.png" alt="Nexus Shell Logo" width="120" height="120">

  <h3>一款现代化的 iOS SSH 客户端</h3>

  <p>远程服务器管理与终端模拟，尽在指尖</p>

  <p>
    <img src="https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg" alt="Platform">
    <img src="https://img.shields.io/badge/Language-Swift-orange.svg" alt="Language">
    <img src="https://img.shields.io/badge/Framework-SwiftUI-green.svg" alt="Framework">
  </p>
</div>

---

## 功能特性

### 服务器管理
- **多服务器支持** - 添加、编辑、删除多个 SSH 服务器配置
- **文件夹分组** - 按公司、项目或用途组织服务器，支持自定义颜色和图标
- **状态监控** - 实时显示服务器在线状态、CPU 和内存使用率
- **安全认证** - 支持密码认证和 SSH 私钥认证，凭据安全存储于 Keychain
- **连接测试** - 添加服务器前可测试连接是否可达

### 终端模拟
- **完整终端体验** - 支持 100+ 标准 Linux 命令模拟输出
- **命令历史** - 保存执行的命令历史记录，支持上下键翻阅
- **快捷工具栏** - ESC、TAB、方向键等常用按键一键输入
- **会话保持** - 切换视图后保持连接状态，无需重复登录
- **快速命令** - 内置 hostname、uname、uptime 等常用命令快捷按钮

### SSH 连接
- **双模式连接** - 支持模拟模式和真实 SSH 连接（需 NMSSH 库）
- **自动重连** - 连接断开后自动尝试重连，可配置重连次数和间隔
- **连接配置** - 可配置连接超时、命令超时、Keep-Alive 间隔等参数
- **连接质量** - 实时显示延迟和连接质量指示器

### 实时监控
- **仪表盘概览** - 一览所有服务器状态，在线/警告/离线统计
- **资源图表** - CPU 使用趋势可视化
- **自动刷新** - 可配置的自动刷新间隔（3-30秒）

### 日志记录
- **活动日志** - 记录所有连接、命令执行等操作
- **日志搜索** - 快速搜索定位特定日志
- **日志筛选** - 按级别（Info/Warning/Error）筛选日志
- **自动清理** - 7天自动清理策略，节省存储空间

### 设置与偏好
- **外观主题** - 深色/浅色/跟随系统三种模式
- **多语言支持** - 中文、英文双语界面
- **触感反馈** - 可配置的触觉反馈增强交互体验
- **SSH 配置** - 可调整连接超时、重连策略等高级参数
- **终端字体** - 可自定义终端字体大小

---

## 支持的 Linux 命令

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

## 项目结构

```
nexus_shell/
├── nexus_shell/
│   ├── nexus_shellApp.swift           # 应用入口
│   ├── Models/                        # 数据模型
│   │   ├── Server.swift               # 服务器模型
│   │   ├── ServerFolder.swift         # 文件夹模型
│   │   ├── ServerSession.swift        # SSH 会话管理（连接生命周期、重连、命令执行）
│   │   └── LogEntry.swift             # 日志模型
│   ├── Views/                         # SwiftUI 视图
│   │   ├── MainTabView.swift          # 主标签导航
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift    # 仪表盘（服务器状态概览、资源图表）
│   │   ├── Servers/
│   │   │   ├── ServersView.swift      # 服务器列表（文件夹分组、搜索、排序）
│   │   │   ├── ServerDetailView.swift # 服务器详情（编辑、连接测试）
│   │   │   ├── ConnectionDetailView.swift # 连接详情
│   │   │   ├── AddServerView.swift    # 添加服务器
│   │   │   └── AddFolderView.swift    # 添加文件夹
│   │   ├── Terminal/
│   │   │   └── TerminalView.swift     # 终端界面（命令输入、输出显示、快捷按钮）
│   │   ├── Logs/
│   │   │   └── LogsView.swift         # 日志查看（搜索、筛选）
│   │   ├── Settings/
│   │   │   └── SettingsView.swift     # 设置界面
│   │   ├── Enhanced/
│   │   │   └── ReconnectingStatusView.swift # 重连状态、连接质量指示器
│   │   └── FileBrowser/
│   │       └── FileBrowserView.swift  # SFTP 文件浏览器（需 NMSSH）
│   ├── Services/                      # 服务层
│   │   ├── SSHClientManager.swift     # SSH 连接管理（模拟/真实双模式）
│   │   ├── CommandSimulator.swift     # 命令模拟引擎
│   │   ├── RealSSHConnection.swift    # 真实 SSH 连接（基于 NMSSH，条件编译）
│   │   ├── SFTPManager.swift          # SFTP 文件传输管理（条件编译）
│   │   ├── SSHConfig.swift            # SSH 连接配置模型
│   │   ├── KeychainHelper.swift       # Keychain 安全存储
│   │   └── Commands/                  # 命令分类实现
│   │       ├── FileCommands.swift     # 文件系统命令
│   │       ├── SystemCommands.swift   # 系统信息命令
│   │       ├── ResourceCommands.swift # 资源监控命令
│   │       ├── ProcessCommands.swift  # 进程管理命令
│   │       ├── NetworkCommands.swift  # 网络命令
│   │       ├── DockerCommands.swift   # Docker 命令
│   │       ├── ServiceCommands.swift  # 服务管理命令
│   │       ├── UserCommands.swift     # 用户管理命令
│   │       ├── PackageCommands.swift  # 包管理命令
│   │       ├── LogCommands.swift      # 日志命令
│   │       └── UtilityCommands.swift  # 实用工具命令
│   ├── Data/                          # 数据层
│   │   ├── DatabaseManager.swift      # SQLite 数据库（建表、迁移、重置）
│   │   ├── DataController.swift       # 数据初始化控制器
│   │   ├── ServerRepository.swift     # 服务器数据仓储
│   │   ├── FolderRepository.swift     # 文件夹数据仓储
│   │   ├── LogRepository.swift        # 日志数据仓储
│   │   ├── ServerStore.swift          # 服务器状态管理（Combine）
│   │   ├── FolderStore.swift          # 文件夹状态管理
│   │   └── LogStore.swift             # 日志状态管理
│   ├── Settings/                      # 应用设置
│   │   └── AppSettings.swift          # 用户偏好设置管理
│   ├── Theme/                         # 主题配置
│   │   ├── AppColors.swift            # 颜色定义
│   │   ├── AppTypography.swift        # 字体样式
│   │   └── DesignSystem.swift         # 设计规范（间距、圆角、动画）
│   └── Assets.xcassets/               # 资源文件
├── nexus_shellTests/                  # 单元测试
├── nexus_shellUITests/                # UI 测试
└── nexus_shell.xcodeproj/             # Xcode 项目
```

---

## 技术栈

| 技术 | 说明 |
|------|------|
| **Swift** | 主要开发语言 |
| **SwiftUI** | 声明式 UI 框架 |
| **SQLite** | 本地数据库存储（服务器配置、日志） |
| **Keychain** | 凭据安全存储（密码、私钥） |
| **Combine** | 响应式编程（状态管理、数据绑定） |
| **NMSSH** | 可选的真实 SSH/SFTP 连接库（条件编译） |

---

## 系统要求

- iOS 15.0 或更高版本
- Xcode 15.0 或更高版本
- macOS 14.0 或更高版本（用于开发）

---

## 安装与运行

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
2. 点击 `Product > Run` 或按 `Cmd+R`

### 命令行编译
```bash
xcodebuild -project nexus_shell.xcodeproj \
  -scheme nexus_shell \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

---

## 使用指南

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

## 安全性

- 所有密码和私钥存储于 iOS **Keychain**，应用卸载后自动清除
- SSH 连接支持模拟模式（本地命令模拟）和真实 SSH 模式（需 NMSSH 库）
- 本地 SQLite 数据库存储服务器配置
- 真实 SSH 连接通过 `#if canImport(NMSSH)` 条件编译，未安装时自动降级为模拟模式

---

## 国际化

支持语言：
- 中文（简体）
- English

语言切换：进入 **Settings > Appearance > Language**

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2026.04.22 | 初始版本发布 |
| 1.1.0 | 2026.05.03 | 移除默认示例数据，优化 SSH 连接架构，新增连接配置和重连机制 |
| 1.1.1 | 2026.05.06 | 修复 GitHub 仓库地址，添加作者信息 |

---

## 许可证

本项目采用 MIT 许可证。

---

## 作者

**baoyang**

- GitHub: [@ruY9527](https://github.com/ruY9527)

---

## 贡献

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
