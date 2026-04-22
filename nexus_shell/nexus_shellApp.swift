//
//  nexus_shellApp.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI
import Combine

@main
struct nexus_shellApp: App {
    @StateObject private var settingsObserver = SettingsObserver.shared
    @StateObject private var serverStore = ServerStore.shared
    
    init() {
        // 初始化数据库
        DataController.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(settingsObserver.colorScheme)
        }
    }
}