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
        _ = DatabaseManager.shared
        
        // 检查并添加示例数据
        Task { @MainActor in
            ServerStore.shared.checkAndAddSampleData()
        }
    }
}