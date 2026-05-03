//
//  DataController.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 数据控制器
/// 职责：初始化数据库
class DataController {
    /// 初始化数据库
    static func initialize() {
        // 初始化数据库管理器（会自动创建表）
        let database = DatabaseManager.shared
        let arguments = ProcessInfo.processInfo.arguments
        let shouldResetData = arguments.contains("--ui-testing-reset-data")

        if shouldResetData {
            database.resetAllData()
            AppSettings.shared.resetAllSettings()
        }

        Task { @MainActor in
            if shouldResetData {
                ServerStore.shared.selectRootFolder()
                FolderStore.shared.loadFolders()
                LogStore.shared.clearFilters()
            }
        }
    }
}
