//
//  ConnectionDetailView.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI
import Combine

/// 连接详情视图
/// 展示实时连接状态、延迟、带宽等信息
struct ConnectionDetailView: View {
    @ObservedObject var server: Server
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRefreshing = false
    @State private var connectionLatency: Double = 0
    @State private var connectionUptime: String = "0s"
    @State private var lastPingTime: Date?
    @State private var pingHistory: [PingRecord] = []
    @State private var showingFullHistory = false
    
    private let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    // 连接状态大卡片
                    ConnectionStatusCard(
                        server: server,
                        latency: connectionLatency,
                        uptime: connectionUptime
                    )
                    
                    // 实时指标网格
                    RealTimeMetricsGrid(
                        server: server,
                        latency: connectionLatency
                    )
                    
                    // 连接信息详情
                    ConnectionInfoCard(server: server)
                    
                    // Ping 响应历史图表
                    PingHistoryCard(
                        pingHistory: pingHistory,
                        showingFullHistory: showingFullHistory,
                        onToggleHistory: { showingFullHistory.toggle() }
                    )
                    
                    // 连接历史记录
                    ConnectionHistorySection(server: server)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
            .navigationTitle(String(localized: "Connection Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        refreshConnectionInfo()
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
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }
            }
            .onReceive(refreshTimer) { _ in
                if server.status == .online {
                    simulatePing()
                }
            }
            .onAppear {
                loadConnectionData()
            }
        }
        .background(AppColors.background)
    }
    
    // MARK: - Actions
    
    private func refreshConnectionInfo() {
        isRefreshing = true
        
        // 模拟刷新数据
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            
            await MainActor.run {
                simulatePing()
                isRefreshing = false
            }
        }
    }
    
    private func loadConnectionData() {
        // 初始化模拟数据
        connectionLatency = server.status == .online ? 45.5 : 0
        connectionUptime = calculateUptime()
        
        // 生成模拟 ping 历史
        if server.status == .online {
            let now = Date()
            for i in 0..<20 {
                pingHistory.append(PingRecord(
                    timestamp: now.addingTimeInterval(-Double(i) * 3),
                    latency: 40 + Double.random(in: -10...20)
                ))
            }
        }
    }
    
    private func simulatePing() {
        if server.status == .online {
            let newLatency = 40 + Double.random(in: -10...25)
            connectionLatency = newLatency
            
            pingHistory.insert(PingRecord(
                timestamp: Date(),
                latency: newLatency
            ), at: 0)
            
            // 保持历史记录数量
            if pingHistory.count > 50 {
                pingHistory.removeLast()
            }
            
            lastPingTime = Date()
            connectionUptime = calculateUptime()
        }
    }
    
    private func calculateUptime() -> String {
        // 模拟计算运行时间
        if server.status == .online {
            let hours = Int.random(in: 0...72)
            if hours >= 24 {
                let days = hours / 24
                return "\(days)d \(hours % 24)h"
            } else if hours >= 1 {
                return "\(hours)h"
            } else {
                return "\(Int.random(in: 1...59))m"
            }
        }
        return "0s"
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    @ObservedObject var server: Server
    let latency: Double
    let uptime: String
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 状态圆环
            ZStack {
                // 外圈动画
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation && server.status == .online ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // 内圈
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                // 状态图标
                Image(systemName: statusIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(statusColor)
            }
            
            // 状态文字
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(String(localized: String.LocalizationValue(server.status.localizedKey)))
                    .font(AppTypography.heading1)
                    .foregroundStyle(statusColor)
                
                Text(server.displayAddress)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                
                // 连接时长
                if server.status == .online {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.accent)
                        
                        Text("Uptime: \(uptime)")
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.accent)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(AppColors.accent.opacity(0.15))
                    .cornerRadius(DesignSystem.Radius.sm)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .stroke(server.status == .online ? AppColors.online.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .onAppear {
            pulseAnimation = server.status == .online
        }
        .onChange(of: server.status) { _, newStatus in
            pulseAnimation = newStatus == .online
        }
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
        case .online: return "link.circle.fill"
        case .offline: return "link.circle.slash"
        case .warning: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Real Time Metrics Grid

struct RealTimeMetricsGrid: View {
    @ObservedObject var server: Server
    let latency: Double
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignSystem.Spacing.md) {
            // 延迟
            MetricCard(
                title: String(localized: "Latency"),
                value: server.status == .online ? "\(String(format: "%.1f", latency))ms" : "--",
                unit: "ms",
                icon: "waveform.path",
                color: latencyColor(latency),
                trend: latency < 50 ? .up : .down
            )
            
            // CPU
            MetricCard(
                title: String(localized: "CPU Usage"),
                value: server.cpuUsage != nil ? "\(Int(server.cpuUsage!))%" : "--",
                unit: "%",
                icon: "cpu",
                color: server.cpuUsage != nil ? usageColor(server.cpuUsage!) : AppColors.secondaryText,
                trend: nil
            )
            
            // Memory
            MetricCard(
                title: String(localized: "Memory Usage"),
                value: server.memoryUsage != nil ? "\(Int(server.memoryUsage!))%" : "--",
                unit: "%",
                icon: "memorychip",
                color: server.memoryUsage != nil ? usageColor(server.memoryUsage!) : AppColors.secondaryText,
                trend: nil
            )
            
            // 连接质量
            MetricCard(
                title: String(localized: "Quality"),
                value: server.status == .online ? qualityText(latency) : "--",
                unit: "",
                icon: "signal",
                color: qualityColor(latency),
                trend: nil
            )
        }
    }
    
    private func latencyColor(_ latency: Double) -> Color {
        if latency < 50 { return AppColors.online }
        if latency < 100 { return AppColors.warning }
        return AppColors.offline
    }
    
    private func usageColor(_ value: Double) -> Color {
        if value < 50 { return AppColors.online }
        if value < 80 { return AppColors.warning }
        return AppColors.offline
    }
    
    private func qualityText(_ latency: Double) -> String {
        if latency < 30 { return String(localized: "Excellent") }
        if latency < 50 { return String(localized: "Good") }
        if latency < 100 { return String(localized: "Fair") }
        return String(localized: "Poor")
    }
    
    private func qualityColor(_ latency: Double) -> Color {
        if latency < 30 { return AppColors.online }
        if latency < 50 { return AppColors.accent }
        if latency < 100 { return AppColors.warning }
        return AppColors.offline
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    enum TrendDirection {
        case up
        case down
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            
            // 标题
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
            
            // 值
            HStack(spacing: 2) {
                Text(value)
                    .font(AppTypography.heading3)
                    .foregroundStyle(color)
                
                if !unit.isEmpty && value != "--" {
                    Text(unit)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                // 趋势箭头
                if let trend = trend {
                    Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundStyle(trend == .up ? AppColors.online : AppColors.warning)
                }
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

// MARK: - Connection Info Card

struct ConnectionInfoCard: View {
    @ObservedObject var server: Server
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.accent)
                
                Text(String(localized: "Connection Info"))
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
            }
            
            // 信息列表
            VStack(spacing: DesignSystem.Spacing.sm) {
                ConnectionInfoRow(
                    label: String(localized: "Host"),
                    value: server.host,
                    icon: "server.rack"
                )
                
                ConnectionInfoRow(
                    label: String(localized: "Port"),
                    value: String(server.port),
                    icon: "network"
                )
                
                ConnectionInfoRow(
                    label: String(localized: "Username"),
                    value: server.username,
                    icon: "person"
                )
                
                ConnectionInfoRow(
                    label: String(localized: "Authentication"),
                    value: server.authMethod == .password 
                        ? String(localized: "Password") 
                        : String(localized: "Private Key"),
                    icon: server.authMethod == .password ? "key" : "key.horizontal"
                )
                
                if let lastConnected = server.lastConnectedAt {
                    ConnectionInfoRow(
                        label: String(localized: "Last Connected"),
                        value: lastConnected.formatted(date: .abbreviated, time: .shortened),
                        icon: "clock"
                    )
                }
                
                ConnectionInfoRow(
                    label: String(localized: "Created"),
                    value: server.createdAt.formatted(date: .abbreviated, time: .shortened),
                    icon: "calendar"
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }
}

struct ConnectionInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 24)
            
            Text(label)
                .font(AppTypography.label)
                .foregroundStyle(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.primaryText)
        }
    }
}

// MARK: - Ping History Card

struct PingHistoryCard: View {
    let pingHistory: [PingRecord]
    let showingFullHistory: Bool
    let onToggleHistory: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppColors.accent)
                
                Text(String(localized: "Ping Response"))
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
                
                if pingHistory.count > 10 {
                    Button {
                        onToggleHistory()
                    } label: {
                        Text(showingFullHistory ? "Recent" : "Full")
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
            
            // 图表区域
            if pingHistory.isEmpty {
                Text(String(localized: "No ping data available"))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(height: 80)
            } else {
                PingChartView(records: showingFullHistory ? pingHistory : pingHistory.prefix(10).toArray())
            }
            
            // 统计信息
            if !pingHistory.isEmpty {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    PingStatView(
                        label: String(localized: "Min"),
                        value: pingHistory.map { $0.latency }.min() ?? 0,
                        color: AppColors.online
                    )
                    
                    PingStatView(
                        label: String(localized: "Avg"),
                        value: pingHistory.map { $0.latency }.reduce(0, +) / Double(pingHistory.count),
                        color: AppColors.accent
                    )
                    
                    PingStatView(
                        label: String(localized: "Max"),
                        value: pingHistory.map { $0.latency }.max() ?? 0,
                        color: AppColors.warning
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }
}

/// Ping 响应记录
struct PingRecord: Identifiable {
    let id = UUID()
    let timestamp: Date
    let latency: Double
}

/// Ping 图表视图
struct PingChartView: View {
    let records: [PingRecord]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(records) { record in
                let height = min(record.latency / 120 * 60, 60)
                
                Rectangle()
                    .fill(latencyGradient(record.latency))
                    .frame(width: 8, height: max(height, 4))
                    .cornerRadius(2)
            }
        }
        .frame(height: 80)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func latencyGradient(_ latency: Double) -> LinearGradient {
        if latency < 50 {
            return LinearGradient(
                colors: [AppColors.online, AppColors.online.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if latency < 100 {
            return LinearGradient(
                colors: [AppColors.warning, AppColors.warning.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [AppColors.offline, AppColors.offline.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Ping 统计视图
struct PingStatView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText)
            
            Text("\(String(format: "%.1f", value))ms")
                .font(AppTypography.heading3)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Connection History Section

struct ConnectionHistorySection: View {
    @ObservedObject var server: Server
    
    // 模拟连接历史
    var connectionHistory: [ConnectionEvent] {
        let now = Date()
        return [
            ConnectionEvent(
                timestamp: now.addingTimeInterval(-3600),
                type: .connected,
                duration: "1h 23m"
            ),
            ConnectionEvent(
                timestamp: now.addingTimeInterval(-7200),
                type: .disconnected,
                reason: "User terminated"
            ),
            ConnectionEvent(
                timestamp: now.addingTimeInterval(-86400),
                type: .connected,
                duration: "45m"
            ),
            ConnectionEvent(
                timestamp: now.addingTimeInterval(-172800),
                type: .reconnected,
                duration: "2h 10m"
            ),
        ]
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(AppColors.secondaryAccent)
                
                Text(String(localized: "Connection History"))
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.primaryText)
                
                Spacer()
            }
            
            // 历史列表
            ForEach(connectionHistory) { event in
                ConnectionEventRow(event: event)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }
}

/// 连接事件
struct ConnectionEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: EventType
    var duration: String? = nil
    var reason: String? = nil
    
    enum EventType {
        case connected
        case disconnected
        case reconnected
        case failed
        
        var icon: String {
            switch self {
            case .connected: return "link.circle.fill"
            case .disconnected: return "link.circle.slash"
            case .reconnected: return "arrow.clockwise"
            case .failed: return "xmark.octagon.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .connected: return AppColors.online
            case .disconnected: return AppColors.secondaryText
            case .reconnected: return AppColors.accent
            case .failed: return AppColors.offline
            }
        }
        
        var text: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .reconnected: return "Reconnected"
            case .failed: return "Failed"
            }
        }
    }
}

struct ConnectionEventRow: View {
    let event: ConnectionEvent
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 时间线指示
            VStack(spacing: 0) {
                Circle()
                    .fill(event.type.color)
                    .frame(width: 10, height: 10)
                
                Rectangle()
                    .fill(AppColors.secondaryText.opacity(0.3))
                    .frame(width: 2, height: 30)
            }
            
            // 图标
            Image(systemName: event.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(event.type.color)
                .frame(width: 24)
            
            // 信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(String(localized: String.LocalizationValue(event.type.text)))
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                
                if let duration = event.duration {
                    Text("Duration: \(duration)")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
                
                if let reason = event.reason {
                    Text("Reason: \(reason)")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                }
            }
            
            Spacer()
            
            // 时间戳
            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(AppTypography.labelSmall)
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Array Extension

extension ArraySlice {
    func toArray() -> [Element] {
        return Array(self)
    }
}

#Preview {
    ConnectionDetailView(server: Server(
        name: "Production Server",
        host: "192.168.1.100",
        port: 22,
        username: "admin"
    ))
}
