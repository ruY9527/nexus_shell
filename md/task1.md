
# 项目目的
旨在利用 SwiftUI 的极致流畅感与 SwiftNIO 的高性能网络处理，打造 iOS 端最强的 SSH 管理神器。

# 技术底座 (The Stack)
UI Framework: SwiftUI (采用原生组合式布局，确保流畅的高刷动画)
SSH Core: SwiftSSH 或 NMSSH (基于 libssh2)，追求低延迟与高安全性
Terminal Engine: SwiftTerm (高性能终端模拟器组件，支持 XTerm 颜色与字形)
Storage: SwiftData (iOS 17+ 专用，本地加密存储服务器敏感信息)
Network Performance: SwiftNIO (处理异步数据流，确保在大批量数据返回时不卡顿)
Localization: String Catalogs (原生支持中英文实时切换)

# 核心功能模块 (Core Modules)
1. 仪表盘 (Global Instances)
- 实时监控: 轮询服务器 top 或 uptime 数据，通过简单的数值解析实现 CPU/RAM 的进度条展示。
- 状态感知: 采用三态视觉（Online/Offline/Warning），对应图中 PRD-CORE-01 的设计。
2. 极致终端 (The Terminal)
- 性能优化: 利用 Metal 渲染文字，确保在查看超大日志文件时依然保持 120Hz 刷新。
- 虚拟键盘: 顶部自定义工具栏，快速输入 ESC, TAB, CTRL, 方向键 以及自定义常用命令。
3. 连接管理 (Node Identity)
- 本地加密: 服务器密码与私钥存放在 Keychain 中，数据库仅存储非敏感信息。
- 快速测试: 在保存前进行连接预检，实时反馈 System Ready 状态。

# 任务清单 (The Roadmap)
Phase 1: 骨架搭建 (Scaffolding)
- [ ] 初始化 Xcode 项目，配置多语言支持 (en/zh)。
- [ ] 定义 Server 模型与 SwiftData 容器。
- [ ] 实现基础的侧滑导航与 TabBar（Dashboard, Servers, Terminal, Logs）。
Phase 2: SSH 引擎集成 (The Engine)
- [ ] 集成 SSH 客户端库，实现基于密码和 RSA/Ed25519 密钥的认证。
- [ ] 封装 TerminalSession 管理类，支持后台连接保持（Background Fetch）。
Phase 3: UI 润色 (Vibe Polish)
- [ ] 实现图中深蓝科技感的自研设计系统（Design System）。
- [ ] 编写 CPU 占用率的折线图组件（使用 Swift Charts）。

# 性能与交互优化 (Optimization)
Haptic Feedback: 在点击“Test Connection”或终端报错时，触发不同强度的震动反馈。
Biometric Lock: 支持 FaceID 解锁 App，保护服务器连接列表。
Zero-Lag Output: 采用双缓冲技术处理 SSH 数据流，避免在输出长 log 时 UI 假死。
Smart Search: 仪表盘支持按 IP、别名或标签进行模糊搜索。
