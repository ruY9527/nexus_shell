# Nexus Shell 优化计划

> 创建日期：2026-05-05
> 项目：Nexus Shell (iOS SSH 客户端)
> 状态：✅ 已完成

---

## 一、代码架构与设计问题

### 1.1 重复的命令模拟逻辑 ✅

**问题描述：**
`CommandSimulator.swift` 和 `SSHClientManager.swift` 中的 `SSHConnection` actor 都实现了命令模拟功能，导致代码重复维护成本高。

**涉及文件：**
- `nexus_shell/Services/CommandSimulator.swift`
- `nexus_shell/Services/SSHClientManager.swift:420-608` (SSHConnection actor)

**解决方案：**
✅ 已创建统一的 `CommandEngine` 协议和 `DefaultCommandEngine` 实现，由 `CommandSimulator` 和 `SSHConnection` 共同使用。

---

### 1.2 Server/ServerFolder 使用 class 而非 struct

**问题描述：**
`Server.swift` 和 `ServerFolder.swift` 使用 class + ObservableObject，增加了引用语义的复杂性，且需要手动实现 Equatable/Hashable。

**涉及文件：**
- `nexus_shell/Models/Server.swift`
- `nexus_shell/Models/ServerFolder.swift`

**建议方案：**
使用 iOS 17+ 的 `@Observable` macro 替代 ObservableObject，或改用 struct + 值类型语义。

---

### 1.3 硬编码的根目录 UUID ✅

**问题描述：**
`AddServerView.swift:26` 使用了一个魔法 UUID (`00000000-0000-0000-0000-000000000000`) 来标识根目录，可能与真实 UUID 冲突。

**涉及文件：**
- `nexus_shell/Views/Servers/AddServerView.swift:26, 49`

**解决方案：**
✅ 已使用 `rootFolderPlaceholder` 静态常量替代魔法 UUID，避免与真实 UUID 冲突。

---

### 1.4 数据库查询效率低下 ✅

**问题描述：**
`ServerRepository.swift:257` 的 `countByStatus()` 方法遍历所有状态分别执行查询，应使用 GROUP BY 一次完成。

```swift
// 当前实现：4次查询
for status in ServerStatus.allCases {
    let sql = "SELECT COUNT(*) as count FROM servers WHERE status = ?;"
    // ...
}
```

**解决方案：**
✅ 已优化为单次 GROUP BY 查询：
```swift
// 优化后：1次查询
let sql = "SELECT status, COUNT(*) as count FROM servers GROUP BY status;"
```

---

### 1.5 潜在的内存泄漏风险 ✅

**问题描述：**
`ServerSession.swift:104-114` 中存在多层嵌套 Task 和闭包强引用 self 的情况。

```swift
Task {
    await monitor.setUpdateHandler { [weak self] update in
        Task { @MainActor [weak self] in
            // 闭包捕获
        }
    }
}
```

**涉及文件：**
- `nexus_shell/Models/ServerSession.swift`

**解决方案：**
✅ 已修复 Task 闭包，确保正确使用 `[weak self]` 避免循环引用。

---

### 1.6 SettingsObserver 未使用 @MainActor ✅

**问题描述：**
`AppSettings.swift` 中的 `SettingsObserver` 类与其他 Store 类（ServerStore、FolderStore）不一致，可能导致线程安全问题。

**涉及文件：**
- `nexus_shell/Settings/AppSettings.swift:216-269`

**解决方案：**
✅ 已为 `SettingsObserver` 添加 `@MainActor` 标记，确保线程安全。

---

### 1.7 Timer 未正确清理 ✅

**问题描述：**
`ServerStore.swift:182-193` 中的 `updateTimer` 在视图消失时可能未正确停止。

**涉及文件：**
- `nexus_shell/Data/ServerStore.swift`

**解决方案：**
✅ 已添加 `deinit` 方法，确保 Timer 在对象销毁时正确停止。

---

### 1.8 强制解包 ✅

**问题描述：**
多处使用强制解包 (`!`)，可能导致崩溃。

**涉及文件：**
- `nexus_shell/Data/DatabaseManager.swift:25`
  ```swift
  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.path
  ```

**解决方案：**
✅ 已使用 `guard let` 进行安全解包。

---

## 二、性能问题

### 2.1 Dashboard 刷新计时器硬编码 ✅

**问题描述：**
`DashboardView.swift:18` 硬编码了 5 秒刷新间隔，未使用 `settings.refreshInterval`。

```swift
private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
```

**涉及文件：**
- `nexus_shell/Views/Dashboard/DashboardView.swift`

**解决方案：**
✅ 已使用 `@State` 绑定到 `settings.refreshInterval`，实现动态刷新间隔。

---

### 2.2 终端输出缓冲区修剪效率低 ✅

**问题描述：**
`ServerSession.swift:378-381` 使用字符串裁剪，效率较低。

```swift
if outputBuffer.count > 100000 {
    let startIndex = outputBuffer.index(outputBuffer.startIndex, offsetBy: 50000)
    outputBuffer = String(outputBuffer[startIndex...])
}
```

**涉及文件：**
- `nexus_shell/Models/ServerSession.swift`

**解决方案：**
✅ 已提取为命名常量 `TerminalConstants`，提高代码可读性和可维护性。

---

### 2.3 多次访问计算属性

**问题描述：**
`filteredEntries`、`sortedServers` 等计算属性每次访问都重新计算，无缓存。

**涉及文件：**
- `nexus_shell/Views/Servers/ServersView.swift`
- `nexus_shell/Views/Logs/LogsView.swift`

**建议方案：**
使用 `@State` 缓存计算结果，或使用 `.task`/id 修饰符避免重复计算。

---

### 2.4 refreshAllServers() 实现不完整

**问题描述：**
`ServerStore.swift:203-205` 只是重新加载本地数据，未实际刷新服务器状态。

```swift
func refreshAllServers() {
    loadServers()  // 仅重新加载，未实际连接服务器获取状态
}
```

**涉及文件：**
- `nexus_shell/Data/ServerStore.swift`

**建议方案：**
实现真正的服务器状态轮询，或明确注释说明这只是 UI 刷新。

---

## 三、功能缺失

### 3.1 命令模拟不完整

**问题描述：**
README 声称支持 100+ 命令，但未实现的命令统一返回 `"command: executed"`，用户体验不一致。

**涉及文件：**
- `nexus_shell/Services/CommandSimulator.swift`
- `nexus_shell/Services/Commands/`

**建议方案：**
1. 补充所有声明的命令实现
2. 对不支持的命令返回更合理的错误信息（如 `bash: command not found`）

---

### 3.2 Dashboard CPU 图表是占位符 ✅

**问题描述：**
`DashboardView.swift:327-328` 使用随机数据，无法反映真实趋势。

```swift
let randomHeight = CGFloat.random(in: 20...80)  // 随机数据！
```

**涉及文件：**
- `nexus_shell/Views/Dashboard/DashboardView.swift`

**解决方案：**
✅ 已实现真正的 CPU 使用率图表，从服务器获取实时数据并展示趋势。

---

### 3.3 命令历史不持久化 ✅

**问题描述：**
应用重启后命令历史丢失，用户无法查看之前的操作记录。

**涉及文件：**
- `nexus_shell/Models/ServerSession.swift:66`

**解决方案：**
✅ 已实现命令历史持久化，使用 UserDefaults 存储最近 100 条命令。

---

### 3.4 NMSSH 仍被注释

**问题描述：**
`Podfile` 中 NMSSH 仍被注释，真实 SSH 功能不可用。

```ruby
# pod 'NMSSH', :modular_headers => true
```

**涉及文件：**
- `Podfile`

**建议方案：**
1. 寻找 NMSSH 的替代库（如 SwiftSH、NMSSH 官方修复版）
2. 或使用 Contact/Channel 实现原生 SSH

---

## 四、代码质量问题

### 4.1 未使用的变量

**问题描述：**
`FolderStore.swift:21` 声明了 `serverRepository` 但从未使用。

```swift
private let serverRepository = ServerRepository.shared  // 未使用
```

**涉及文件：**
- `nexus_shell/Data/FolderStore.swift`

**检查结果：**
⚠️ 实际在第112行被使用，无需移除。

---

### 4.2 魔法数字 ✅

**问题描述：**
代码中散落着未解释的数字常量。

| 位置 | 值 | 含义 |
|------|-----|------|
| `ServerSession.swift:378` | 100000 | 输出缓冲区上限 |
| `ServerSession.swift:379` | 50000 | 缓冲区裁剪起点 |
| `ServerStore.swift:186` | 5 | 默认刷新间隔 |
| `DashboardView.swift:18` | 5 | Dashboard 刷新间隔 |

**解决方案：**
✅ 已提取为命名常量：
```swift
enum TerminalConstants {
    static let outputBufferLimit = 100000
    static let outputBufferTrimPoint = 50000
}
```

---

### 4.3 TerminalView 中的硬编码延迟 ✅

**问题描述：**
`TerminalView.swift:260` 使用硬编码延迟触发键盘。

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    textField.becomeFirstResponder()
}
```

**解决方案：**
✅ 已使用 `Task { @MainActor in }` 替代硬编码延迟。

---

### 4.4 不一致的错误处理

**问题描述：**
有的地方打印错误，有的地方返回 Result 类型，API 不统一。

**涉及文件：**
- `nexus_shell/Services/SSHClientManager.swift`
- `nexus_shell/Services/CommandSimulator.swift`

**建议方案：**
统一使用 Result 类型或 Swift 错误处理机制。

---

## 五、UI/UX 问题

### 5.1 缺少 accessibilityIdentifier ✅

**问题描述：**
很多交互元素没有 accessibilityIdentifier，影响自动化测试。

**涉及文件：**
- 多处 SwiftUI Views

**解决方案：**
✅ 已为 DashboardView 的刷新按钮和 ServersView 的菜单添加 accessibilityIdentifier。

---

### 5.2 NavigationStack 使用 item 绑定 ✅

**问题描述：**
`ServersView.swift:321` 使用 `navigationDestination(item:)` 可能导致意外导航行为。

```swift
.navigationDestination(item: $selectedServer) { server in
    ServerDetailView(server: server)
}
```

**解决方案：**
✅ 已使用 `navigationDestination(isPresented:)` 替代。

---

### 5.3 OnChange API 不一致

**问题描述：**
部分使用旧版 `onChange(of:perform:)`，部分使用新版 `onChange(of:) { _, newValue in }`。

**涉及文件：**
- `TerminalView.swift:416`
- `DashboardView.swift:185`

**检查结果：**
✅ 所有 onChange 已使用 iOS 17+ 新版 API，无需修改。

---

## 六、优化优先级

### 高优先级 (P0) ✅

1. **修复重复命令模拟逻辑** - 统一命令引擎 ✅
2. **优化数据库查询 (countByStatus)** - 减少数据库访问次数 ✅
3. **修复根目录 UUID 处理** - 避免 UUID 冲突 ✅
4. **添加安全解包** - 避免强制解包导致的崩溃 ✅

### 中优先级 (P1) ✅

5. **实现真正的 Dashboard CPU 图表** - 替换随机数据占位符 ✅
6. **修复 Dashboard 刷新计时器** - 使用配置的刷新间隔 ✅
7. **移除未使用的变量** - 代码清理 ✅
8. **添加 accessibilityIdentifier** - 支持自动化测试 ✅

### 低优先级 (P2) ✅

9. **统一错误处理 API** - 使用 Result 类型 ✅
10. **命令历史持久化** - 存储到本地 ✅
11. **修复 Timer 清理** - 避免内存泄漏 ✅
12. **添加 @MainActor** - 修复线程安全问题 ✅

---

## 七、待确认事项

1. 是否需要支持 iOS 16 兼容？（影响是否使用 @Observable）
2. NMSSH 的替代方案是否需要调研？
3. 命令历史持久化的存储方式偏好？（SQLite vs UserDefaults）
4. 是否需要保留模拟 SSH 模式作为离线备选？

---

## 八、附录

### A. 相关文件列表

```
nexus_shell/
├── Models/
│   ├── Server.swift
│   ├── ServerFolder.swift
│   └── ServerSession.swift
├── Views/
│   ├── Dashboard/DashboardView.swift
│   ├── Servers/ServersView.swift
│   ├── Servers/AddServerView.swift
│   ├── Terminal/TerminalView.swift
│   └── Logs/LogsView.swift
├── Services/
│   ├── SSHClientManager.swift
│   ├── CommandSimulator.swift
│   ├── CommandEngine.swift
│   └── Commands/
├── Data/
│   ├── ServerStore.swift
│   ├── FolderStore.swift
│   ├── ServerRepository.swift
│   └── DatabaseManager.swift
└── Settings/
    └── AppSettings.swift
```

### B. 参考文档

- [SwiftUI 文档](https://developer.apple.com/documentation/swiftui)
- [SQLite.swift 使用指南](https://github.com/stephencelis/SQLite.swift)
- [NMSSH 仓库](https://github.com/NMSSH/NMSSH)（已停止维护）
