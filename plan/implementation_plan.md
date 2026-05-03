# Nexus Shell 真实 SSH 功能实施计划

> 创建日期: 2026-05-03
> 项目类型: 生产环境 SSH 客户端
> 预计工期: 14 个工作日

---

## 决策摘要

| 问题 | 选择 | 说明 |
|------|------|------|
| SSH 库 | NMSSH | 成熟稳定，支持 SSH + SFTP |
| 文件传输存储 | Documents 目录 | 用户可通过 Files App 访问 |
| PTY 支持 | 后期迭代 | 先实现简单命令执行，PTY 后续迭代 |
| 重连策略 | 默认配置+可配置 | 超时 10s、最大重试 3 次、间隔 2s |
| 模拟模式 | 保留 | 网络不可达时 fallback |

---

## 项目结构变更

```
当前 mock 实现                              目标真实实现
┌─────────────────────┐                  ┌─────────────────────┐
│  SSHClientManager   │                  │  SSHClientManager   │
│  └─ SSHConnection   │    改造        │  └─ RealSSHConnection│ (NMSSH)
│     (模拟输出)       │ ────────────> │     (真实 SSH)       │
├─────────────────────┤                  ├─────────────────────┤
│ CommandSimulator    │    保留        │ CommandSimulator    │ (fallback)
│  └─ 10+ Commands   │    fallback   │  └─ 保持模拟        │
├─────────────────────┤                  ├─────────────────────┤
│  ServerSession      │    增强        │  ServerSession      │
│  (简单状态)         │ ────────────> │  (支持 PTY + 重连)  │
├─────────────────────┤                  ├─────────────────────┤
│  (无文件传输)       │    新增        │  SFTPManager        │ (新增)
│                    │ ────────────> │  └─ 文件浏览器 UI   │
└─────────────────────┘                  └─────────────────────┘
```

---

## 每日任务详情

### Phase 1: 依赖与基础架构 (Day 1-2)

#### Day 1 (2026-05-04)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 1.1.1 | 创建 Podfile，添加 NMSSH 依赖 | 新建 `Podfile` | ⬜ |
| 1.1.2 | 运行 `pod install` | 修改 `.xcworkspace` | ⬜ |
| 1.1.3 | 验证 NMSSH 导入成功 | - | ⬜ |

**Podfile 内容:**
```ruby
platform :ios, '15.0'
use_frameworks!

target 'nexus_shell' do
  pod 'NMSSH', '~> 2.3'
end
```

#### Day 2 (2026-05-05)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 1.2.1 | 创建 SSHConfig 模型 | 新建 `Services/SSHConfig.swift` | ⬜ |
| 1.2.2 | 创建 RealSSHConnection 接口定义 | 新建 `Services/RealSSHConnection.swift` | ⬜ |
| 1.2.3 | 改造 SSHClientManager 工厂方法 | 修改 `Services/SSHClientManager.swift` | ⬜ |

**SSHConfig 模型:**
```swift
struct SSHConfig: Codable {
    var connectionTimeout: TimeInterval = 10.0
    var commandTimeout: TimeInterval = 30.0
    var autoReconnect: Bool = true
    var maxReconnectAttempts: Int = 3
    var reconnectDelay: TimeInterval = 2.0
    var keepAliveInterval: TimeInterval = 60.0
}
```

---

### Phase 2: 真实 SSH 连接 (Day 3-5)

#### Day 3 (2026-05-06)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 2.1.1 | 实现 RealSSHConnection.init() 初始化 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.1.2 | 实现 connect() 连接方法 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.1.3 | 实现密码认证 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.1.4 | 实现私钥认证 | `Services/RealSSHConnection.swift` | ⬜ |

#### Day 4 (2026-05-07)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 2.2.1 | 实现 execute() 单命令执行 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.2.2 | 实现命令超时处理 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.2.3 | 实现 disconnect() 断开连接 | `Services/RealSSHConnection.swift` | ⬜ |

#### Day 5 (2026-05-08)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 2.3.1 | 实现 startShell() PTY 初始化 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.3.2 | 实现输出流实时读取 | `Services/RealSSHConnection.swift` | ⬜ |
| 2.3.3 | 实现 resizeTerminal() 终端 resize | `Services/RealSSHConnection.swift` | ⬜ |
| 2.3.4 | 添加连接超时机制 | `Services/RealSSHConnection.swift` | ⬜ |

**RealSSHConnection 核心接口:**
```swift
actor RealSSHConnection {
    // 连接管理
    func connect() async throws
    func disconnect()
    func isConnected() -> Bool

    // 命令执行
    func execute(command: String) async throws -> String

    // PTY/Shell
    func startShell(outputHandler: @escaping (String) -> Void) async throws
    func sendInput(_ input: String)
    func resizeTerminal(width: Int, height: Int)

    // 配置
    var config: SSHConfig { get }
}
```

---

### Phase 3: SFTP 文件传输 (Day 6-8)

#### Day 6 (2026-05-09)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 3.1.1 | 创建 SFTPManager 类 | 新建 `Services/SFTPManager.swift` | ⬜ |
| 3.1.2 | 实现 connect/disconnect | `Services/SFTPManager.swift` | ⬜ |
| 3.1.3 | 实现 listDirectory() 文件列表 | `Services/SFTPManager.swift` | ⬜ |

#### Day 7 (2026-05-10)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 3.2.1 | 实现 downloadFile() 下载 | `Services/SFTPManager.swift` | ⬜ |
| 3.2.2 | 实现 uploadFile() 上传 | `Services/SFTPManager.swift` | ⬜ |
| 3.2.3 | 添加传输进度回调 | `Services/SFTPManager.swift` | ⬜ |

#### Day 8 (2026-05-11)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 3.3.1 | 创建 FileBrowserView 文件浏览器 | 新建 `Views/FileBrowser/FileBrowserView.swift` | ⬜ |
| 3.3.2 | 创建 FileTransferView 传输面板 | 新建 `Views/FileBrowser/FileTransferView.swift` | ⬜ |
| 3.3.3 | 集成到 TerminalView 工具栏 | 修改 `Views/Terminal/TerminalView.swift` | ⬜ |

**SFTPManager 核心接口:**
```swift
class SFTPManager {
    func connect(to session: RealSSHConnection) async throws
    func disconnect()

    func listDirectory(path: String) async throws -> [SFTPFile]
    func downloadFile(remotePath: String, localPath: String, progress: ((Double) -> Void)?) async throws
    func uploadFile(localPath: String, remotePath: String, progress: ((Double) -> Void)?) async throws
    func createDirectory(path: String) async throws
    func deleteFile(path: String) async throws
    func rename(from: String, to: String) async throws
}

struct SFTPFile {
    let name: String
    let path: String
    let size: UInt64
    let isDirectory: Bool
    let modifiedDate: Date
    let permissions: String
}
```

---

### Phase 4: 命令模拟 Fallback (Day 9)

#### Day 9 (2026-05-12)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 4.1.1 | 在 AppSettings 添加 SSH 模式选项 | 修改 `Settings/AppSettings.swift` | ⬜ |
| 4.1.2 | 实现 SSHClientManager 智能 fallback | 修改 `Services/SSHClientManager.swift` | ⬜ |
| 4.1.3 | 添加模拟模式开关 UI | 修改 `Views/Settings/SettingsView.swift` | ⬜ |
| 4.1.4 | 测试 fallback 切换 | - | ⬜ |

**AppSettings 新增:**
```swift
var sshMode: SSHModes {
    get { UserDefaults.standard.string(forKey: "ssh_mode").flatMap { SSHModes(rawValue: $0) } ?? .auto }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: "ssh_mode") }
}

enum SSHModes: String, CaseIterable {
    case real      // 真实 SSH
    case simulated // 模拟模式
    case auto      // 失败时自动切换
}
```

---

### Phase 5: 增强 ServerSession (Day 10-11)

#### Day 10 (2026-05-13)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 5.1.1 | 添加 SessionState.reconnecting | 修改 `Models/ServerSession.swift` | ⬜ |
| 5.1.2 | 实现自动重连逻辑 | 修改 `Models/ServerSession.swift` | ⬜ |
| 5.1.3 | 添加重连计数器 UI | 修改 `Views/Terminal/TerminalView.swift` | ⬜ |

#### Day 11 (2026-05-14)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 5.2.1 | 实现连接质量检测 (ping) | 修改 `Services/RealSSHConnection.swift` | ⬜ |
| 5.2.2 | 添加连接稳定性监控 | 修改 `Models/ServerSession.swift` | ⬜ |
| 5.2.3 | 测试重连机制 | - | ⬜ |

**SessionState 新增:**
```swift
enum SessionState {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case error(String)
}
```

---

### Phase 6: UI 增强 (Day 12-13)

#### Day 12 (2026-05-15)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 6.1.1 | 增强 ConnectionStatusBar 显示重连状态 | 修改 `Views/Terminal/TerminalView.swift` | ⬜ |
| 6.1.2 | 添加连接设置界面入口 | 修改 `Views/Servers/ServerDetailView.swift` | ⬜ |
| 6.1.3 | 添加服务器级连接配置 | 修改 `Views/Servers/ServerDetailView.swift` | ⬜ |

#### Day 13 (2026-05-16)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 6.2.1 | 添加文件传输历史到 LogsView | 修改 `Views/Logs/LogsView.swift` | ⬜ |
| 6.2.2 | 添加传输状态通知 | 修改 `Views/Terminal/TerminalView.swift` | ⬜ |
| 6.2.3 | UI 整体测试与修复 | - | ⬜ |

---

### Phase 7: 测试与优化 (Day 14-15)

#### Day 14 (2026-05-17)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 7.1.1 | 单元测试 RealSSHConnection | 新建 `nexus_shellTests/RealSSHConnectionTests.swift` | ⬜ |
| 7.1.2 | 单元测试 SFTPManager | 新建 `nexus_shellTests/SFTPManagerTests.swift` | ⬜ |
| 7.1.3 | UI 测试连接流程 | 新建 `nexus_shellUITests/SSHConnectionTests.swift` | ⬜ |

#### Day 15 (2026-05-18)

| 任务 | 描述 | 文件变更 | 状态 |
|------|------|----------|------|
| 7.2.1 | 性能优化：大文件传输 | `Services/SFTPManager.swift` | ⬜ |
| 7.2.2 | 内存管理：输出 buffer 限制 | `Services/RealSSHConnection.swift` | ⬜ |
| 7.2.3 | Bug 修复与代码审查 | - | ⬜ |
| 7.2.4 | 项目清理与文档更新 | - | ⬜ |

---

## 文件变更清单

### 新建文件 (8 个)

```
nexus_shell/
├── Services/
│   ├── SSHConfig.swift              # Phase 1 - SSH 配置模型
│   └── RealSSHConnection.swift     # Phase 2 - 真实 SSH 连接
│   └── SFTPManager.swift            # Phase 3 - SFTP 文件传输
├── Views/
│   └── FileBrowser/
│       ├── FileBrowserView.swift    # Phase 3 - 文件浏览器
│       └── FileTransferView.swift   # Phase 3 - 传输面板
└── Tests/
    ├── RealSSHConnectionTests.swift  # Phase 7 - 单元测试
    └── SFTPManagerTests.swift       # Phase 7 - 单元测试
```

### 修改文件 (12 个)

```
nexus_shell/
├── Services/
│   ├── SSHClientManager.swift       # Phase 1, 2, 4
│   └── CommandSimulator.swift       # Phase 4 (保留)
├── Models/
│   └── ServerSession.swift          # Phase 5, 6
├── Views/
│   ├── Terminal/
│   │   └── TerminalView.swift       # Phase 3, 6
│   ├── Servers/
│   │   └── ServerDetailView.swift   # Phase 6
│   └── Logs/
│       └── LogsView.swift           # Phase 6
├── Settings/
│   └── AppSettings.swift            # Phase 4
└── Data/
    └── ServerStore.swift            # Phase 4
```

---

## 时间线总览

```
Week 1:
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│ Day 1   │ Day 2   │ Day 3   │ Day 4   │ Day 5   │
│ Phase 1 │ Phase 1 │ Phase 2 │ Phase 2 │ Phase 2 │
│ 依赖    │ 基础    │ 连接    │ 命令    │ PTY     │
└─────────┴─────────┴─────────┴─────────┴─────────┘

Week 2:
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│ Day 6   │ Day 7   │ Day 8   │ Day 9   │ Day 10  │
│ Phase 3 │ Phase 3 │ Phase 3 │ Phase 4 │ Phase 5 │
│ SFTP    │ 传输    │ UI      │Fallback │ 重连    │
└─────────┴─────────┴─────────┴─────────┴─────────┘

Week 3:
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│ Day 11  │ Day 12  │ Day 13  │ Day 14  │ Day 15  │
│ Phase 5 │ Phase 6 │ Phase 6 │ Phase 7 │ Phase 7 │
│ 重连    │ UI      │ UI      │ 测试    │ 优化    │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

---

## 里程碑

| 里程碑 | 日期 | 说明 |
|--------|------|------|
| M1: 基础连接 | Day 4 | 能建立真实 SSH 连接并执行命令 |
| M2: 文件传输 | Day 8 | 完成 SFTP 上传/下载功能 |
| M3: 完整功能 | Day 13 | 所有功能可用，UI 完善 |
| M4: 发布就绪 | Day 15 | 测试通过，可以发布 |

---

## 技术依赖

- **NMSSH** (~> 2.3): SSH + SFTP 功能
- **iOS 15.0+**: 部署目标
- **Xcode 15.0+**: 开发环境
- **Swift 5.9+**: 语言版本

---

## 风险与备选方案

| 风险 | 概率 | 影响 | 备选方案 |
|------|------|------|----------|
| NMSSH 与最新 iOS 不兼容 | 低 | 高 | 切换到 SwiftSH 或自研 |
| SFTP 大文件传输内存问题 | 中 | 中 | 分块传输 + 进度显示 |
| PTY 实现复杂超预期 | 中 | 中 | 延后到 Phase 2 迭代 |
| 自动重连导致频繁耗电 | 低 | 低 | 添加用户可控开关 |

---

## 下一步行动

1. **立即执行**: Day 1 - 添加 Podfile 并运行 pod install
2. **确认**: NMSSH 2.3.1 版本是否满足需求
3. **备选**: 如 NMSSH 有问题，考虑 SwiftSH (https://github.com/SwiftSH/SwiftSH)

---

*文档版本: 1.0*
*最后更新: 2026-05-03*
