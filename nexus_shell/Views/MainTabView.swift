//
//  MainTabView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 主标签页视图
struct MainTabView: View {
    @State private var selectedTab: TabItem = .dashboard
    @State private var showingSettings = false

    var body: some View {
        // 内容区域 - 使用 safeAreaInset 确保内容不被 TabBar 覆盖
        TabContentView(selectedTab: selectedTab)
            .safeAreaInset(edge: .bottom) {
                // 自定义 TabBar 作为底部安全区域
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showingSettings: $showingSettings
                )
            }
            .background(AppColors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

/// 标签页类型
enum TabItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case servers = "Servers"
    case terminal = "Terminal"
    case logs = "Logs"

    var icon: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .servers: return "server.rack"
        case .terminal: return "terminal"
        case .logs: return "doc.text"
        }
    }
}

/// 标签页内容视图
struct TabContentView: View {
    let selectedTab: TabItem

    var body: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .servers:
                ServersView()
            case .terminal:
                TerminalView()
            case .logs:
                LogsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 自定义 TabBar
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showingSettings: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                )
                .accessibilityIdentifier("tab.\(tab.rawValue.lowercased())")
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                    if AppSettings.shared.hapticFeedbackEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }

            // 设置按钮
            TabBarItem(
                tab: nil,
                icon: "gearshape.fill",
                isSelected: showingSettings
            )
            .accessibilityIdentifier("tab.settings")
            .onTapGesture {
                showingSettings = true
                if AppSettings.shared.hapticFeedbackEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(
            AppColors.secondaryBackground
                .opacity(0.95)
                .blur(radius: 10)
        )
        .overlay(
            Rectangle()
                .fill(AppColors.accent.opacity(0.3))
                .frame(height: 1),
            alignment: .top
        )
    }
}

/// TabBar 单项
struct TabBarItem: View {
    let tab: TabItem?
    var icon: String? = nil
    let isSelected: Bool

    init(tab: TabItem, isSelected: Bool) {
        self.tab = tab
        self.icon = nil
        self.isSelected = isSelected
    }

    init(tab: TabItem?, icon: String, isSelected: Bool) {
        self.tab = tab
        self.icon = icon
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: displayIcon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.secondaryText)

            Text(displayTitle)
                .font(AppTypography.labelSmall)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                .fill(isSelected ? AppColors.accent.opacity(0.15) : Color.clear)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(displayTitle)
        .accessibilityAddTraits(.isButton)
    }

    private var displayIcon: String {
        if let icon = icon {
            return icon
        }
        return tab?.icon ?? "questionmark"
    }

    private var displayTitle: String {
        if icon != nil {
            return String(localized: "Settings")
        }
        return String(localized: String.LocalizationValue(tab?.rawValue ?? ""))
    }
}

#Preview {
    MainTabView()
}
