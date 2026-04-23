//
//  DataController.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 数据控制器
/// 职责简化为初始化数据库和示例数据
class DataController {
    /// 初始化数据库
    static func initialize() {
        // 初始化数据库管理器（会自动创建表）
        let database = DatabaseManager.shared
        let arguments = ProcessInfo.processInfo.arguments
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isUITesting = arguments.contains("--ui-testing")
        let shouldResetData = arguments.contains("--ui-testing-reset-data")

        if shouldResetData {
            database.resetAllData()
            AppSettings.shared.resetAllSettings()
        }
        
        // 检查并添加示例数据。自动化测试默认不注入示例数据，除非 UI 测试显式要求。
        Task { @MainActor in
            if shouldResetData {
                ServerStore.shared.selectRootFolder()
                FolderStore.shared.loadFolders()
                LogStore.shared.clearFilters()
            }

            if arguments.contains("--ui-testing-disable-sample-data") {
                return
            }

            if isUITesting && arguments.contains("--ui-testing-seed-data") {
                ServerStore.shared.checkAndAddSampleData()
                return
            }

            if !isRunningTests {
                ServerStore.shared.checkAndAddSampleData()
            }
        }
    }
}
