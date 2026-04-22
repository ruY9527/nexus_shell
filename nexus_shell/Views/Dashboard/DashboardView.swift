//
//  DashboardView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI
import Combine

/// 仪表盘视图 - 实时监控服务器状态
struct DashboardView: View {
    @StateObject private var serverStore = ServerStore.shared
    @State private var cpuHistory: [(Date, Double)] = []
    @State private var isRefreshing = false
    
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private var settings: AppSettings {
        AppSettings.shared
    }
    
    // 使用所有服务器（不区分文件夹）
    var allServers: [Server] {
        serverStore.allServers
    }
    
    var onlineServers: [Server] {
        allServers.filter { $0.status == .online }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    // 统计概览
                    DashboardStatsOverview(servers: serverStore.servers)
                    
                    // CPU 使用率图表（仅显示在线服务器）
                    if !onlineServers.isEmpty && settings.autoRefreshEnabled {
                        CPUChartSection(servers: onlineServers)
                    }
                    
                    // 服务器状态卡片列表
                    ForEach(allServers) { server in
                        ServerStatusCard(server: server)
                    }
                    
                    if serverStore.servers.isEmpty {
                        EmptyStateView(onAdd: {})
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
            }
            .navigationTitle(String(localized: "Dashboard"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        refreshAllServers()
                    } label: {
                        if isRefreshing {
                            ProgressView()
                                .tint(AppColors.accent)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
            }
            .onReceive(refreshTimer) { _ in
                if settings.autoRefreshEnabled {
                    refreshAllServers()
                }
            }
        }
    }
    
    private func refreshAllServers() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        serverStore.refreshAllServers()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }
}

// MARK: - Dashboard Components

/// 统计概览组件
struct DashboardStatsOverview: View {
    let servers: [Server]
    
    @State private var animatedOnline = 0
    @State private var animatedWarning = 0
    @State private var animatedOffline = 0
    
    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }
    
    var warningCount: Int {
        servers.filter { $0.status == .warning }.count
    }
    
    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }
    
    var totalCpuUsage: Double {
        let onlineServers = servers.filter { $0.status == .online || $0.status == .warning }
        let cpuValues = onlineServers.compactMap { $0.cpuUsage }
        return cpuValues.isEmpty ? 0 : cpuValues.reduce(0, +) / Double(cpuValues.count)
    }
    
    var totalMemoryUsage: Double {
        let onlineServers = servers.filter { $0.status == .online || $0.status == .warning }
        let memValues = onlineServers.compactMap { $0.memoryUsage }
        return memValues.isEmpty ? 0 : memValues.reduce(0, +) / Double(memValues.count)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 状态统计
            HStack(spacing: DesignSystem.Spacing.md) {
                AnimatedStatCard(
                    title: String(localized: "Online"),
                    value: animatedOnline,
                    color: AppColors.online,
                    icon: "checkmark.circle.fill"
                )
                
                AnimatedStatCard(
                    title: String(localized: "Warning"),
                    value: animatedWarning,
                    color: AppColors.warning,
                    icon: "exclamationmark.triangle.fill"
                )
                
                AnimatedStatCard(
                    title: String(localized: "Offline"),
                    value: animatedOffline,
                    color: AppColors.offline,
                    icon: "xmark.circle.fill"
                )
            }
            
            // 总体使用率
            if !servers.isEmpty {
                HStack(spacing: DesignSystem.Spacing.md) {
                    TotalUsageCard(
                        title: String(localized: "CPU Usage"),
                        value: totalCpuUsage,
                        color: usageColor(totalCpuUsage)
                    )
                    
                    TotalUsageCard(
                        title: String(localized: "Memory Usage"),
                        value: totalMemoryUsage,
                        color: usageColor(totalMemoryUsage)
                    )
                }
            }
        }
        .onAppear {
            animateStats()
        }
        .onChange(of: servers) { _, _ in
            animateStats()
        }
    }
    
    private func animateStats() {
        withAnimation(.easeInOut(duration: 0.5)) {
            animatedOnline = onlineCount
            animatedWarning = warningCount
            animatedOffline = offlineCount
        }
    }
    
    private func usageColor(_ value: Double) -> Color {
        if value < 50 { return AppColors.online }
        if value < 80 { return AppColors.warning }
        return AppColors.offline
    }
}

/// 动画统计卡片
struct AnimatedStatCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            Text("\(value)")
                .font(AppTypography.displayMedium)
                .foregroundStyle(AppColors.primaryText)
                .contentTransition(.numericText())
            
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if value > 0 {
                isAnimating = true
            }
        }
    }
}

/// 总体使用率卡片
struct TotalUsageCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("\(Int(value))%")
                .font(AppTypography.heading2)
                .foregroundStyle(color)
            
            // 进度环
            ZStack {
                Circle()
                    .stroke(AppColors.secondaryBackground, lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: value)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// CPU 图表区域
struct CPUChartSection: View {
    let servers: [Server]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("CPU Usage Trend")
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
                
                Text("Last 5 min")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText)
            }
            
            // 简化的图表视图
            ChartPlaceholderView(servers: servers)
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }
}

/// 图表占位视图
struct ChartPlaceholderView: View {
    let servers: [Server]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<50, id: \.self) { index in
                let randomHeight = CGFloat.random(in: 20...80)
                Rectangle()
                    .fill(AppColors.accent.opacity(0.3 + Double(index) / 100))
                    .frame(width: 4, height: randomHeight)
                    .cornerRadius(1)
            }
        }
        .frame(height: 80)
        .background(AppColors.secondaryBackground.opacity(0.3))
        .cornerRadius(DesignSystem.Radius.sm)
    }
}

/// 空状态视图
struct EmptyStateView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText)
            
            Text(String(localized: "No servers added"))
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
            
            Text(String(localized: "Tap + to add your first server"))
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
        }
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Server Status Card

struct ServerStatusCard: View {
    @ObservedObject var server: Server
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 状态指示器
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(statusColor)
            }
            
            // 服务器信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(server.name)
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                Text(server.displayAddress)
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText)
                
                // 使用率指示
                if server.status == .online || server.status == .warning {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let cpu = server.cpuUsage {
                            MiniMetricBadge(value: cpu, type: .cpu)
                        }
                        if let memory = server.memoryUsage {
                            MiniMetricBadge(value: memory, type: .memory)
                        }
                    }
                }
                
                // 标签
                if !server.tags.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(server.tags, id: \.self) { tag in
                            TagView(text: tag, color: AppColors.accent)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 状态标签
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                StatusBadge(status: server.status)
                
                if let lastConnected = server.lastConnectedAt {
                    Text(lastConnected.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(statusColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch server.status {
        case .online: return AppColors.online
        case .offline: return AppColors.offline
        case .warning: return AppColors.warning
        case .unknown: return AppColors.unknown
        }
    }
    
    private var statusIcon: String {
        switch server.status {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// 小型指标徽章
struct MiniMetricBadge: View {
    let value: Double
    let type: MetricType
    
    enum MetricType {
        case cpu
        case memory
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: 10))
            
            Text("\(Int(value))%")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }
    
    private var iconName: String {
        switch type {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        }
    }
    
    private var color: Color {
        if value < 50 { return AppColors.online }
        if value < 80 { return AppColors.warning }
        return AppColors.offline
    }
}

/// 状态徽章
struct StatusBadge: View {
    let status: ServerStatus
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(String(localized: String.LocalizationValue(status.localizedKey)))
                .font(AppTypography.labelSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(color.opacity(0.15))
        .cornerRadius(DesignSystem.Radius.sm)
    }
    
    private var color: Color {
        switch status {
        case .online: return AppColors.online
        case .offline: return AppColors.offline
        case .warning: return AppColors.warning
        case .unknown: return AppColors.unknown
        }
    }
}

#Preview {
    DashboardView()
}