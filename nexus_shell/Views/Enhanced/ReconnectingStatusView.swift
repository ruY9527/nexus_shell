//
//  ReconnectingStatusView.swift
//  nexus_shell
//
//  Created by opencode on 2026-05-03.
//

import SwiftUI

/// 重连状态视图
struct ReconnectingStatusView: View {
    let attempt: Int
    let maxAttempts: Int
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 进度指示器
            ZStack {
                Circle()
                    .stroke(AppColors.secondaryText.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.warning, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)

                Text("\(attempt)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColors.warning)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Reconnecting...")
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)

                Text("Attempt \(attempt) of \(maxAttempts)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
    }

    private var progress: Double {
        Double(attempt) / Double(maxAttempts)
    }
}

/// 连接模式指示器
struct ConnectionModeIndicator: View {
    let mode: ServerSession.SSHConnectionMode

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(modeColor)
                .frame(width: 6, height: 6)

            Text(modeText)
                .font(AppTypography.labelSmall)
                .foregroundStyle(modeColor)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(modeColor.opacity(0.15))
        .cornerRadius(DesignSystem.Radius.sm)
    }

    private var modeText: String {
        switch mode {
        #if canImport(NMSSH)
        case .real:
            return "Real SSH"
        #endif
        case .simulated:
            return "Simulated"
        }
    }

    private var modeColor: Color {
        switch mode {
        #if canImport(NMSSH)
        case .real:
            return AppColors.online
        #endif
        case .simulated:
            return AppColors.warning
        }
    }
}

/// 增强的连接状态栏
struct EnhancedConnectionStatusBar: View {
    @ObservedObject var session: ServerSession

    var body: some View {
        VStack(spacing: 0) {
            // 主要状态栏
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("\(session.server.username)@\(session.server.host)")
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                if session.state == .connected {
                    ConnectionModeIndicator(mode: session.connectionMode)
                }

                Text(statusText)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // 重连进度条（当正在重连时显示）
            if case .reconnecting(let attempt, let maxAttempts) = session.state {
                ReconnectingProgressBar(attempt: attempt, maxAttempts: maxAttempts)
            }
        }
        .background(AppColors.secondaryBackground.opacity(0.8))
    }

    private var statusText: String {
        switch session.state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .reconnecting:
            return "Reconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var statusColor: Color {
        switch session.state {
        case .connected:
            return AppColors.online
        case .connecting, .reconnecting:
            return AppColors.warning
        case .disconnected, .error:
            return AppColors.offline
        }
    }
}

/// 重连进度条
struct ReconnectingProgressBar: View {
    let attempt: Int
    let maxAttempts: Int

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.secondaryText.opacity(0.2))
                        .frame(height: 2)

                    Rectangle()
                        .fill(AppColors.warning)
                        .frame(width: geometry.size.width * progress, height: 2)
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .frame(height: 2)

            HStack {
                Text("Reconnecting (\(attempt)/\(maxAttempts))")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }

    private var progress: Double {
        Double(attempt) / Double(maxAttempts)
    }
}

/// 连接质量指示器
struct ConnectionQualityIndicator: View {
    let latency: Int?
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isConnected, let latency = latency {
                Image(systemName: qualityIcon)
                    .font(.system(size: 10))
                    .foregroundStyle(qualityColor)

                Text("\(latency)ms")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppColors.secondaryText)
            } else {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.offline)
            }
        }
    }

    private var qualityIcon: String {
        guard let latency = latency else { return "wifi" }
        if latency < 100 { return "wifi" }
        if latency < 300 { return "wifi.exclamationmark" }
        return "wifi.slash"
    }

    private var qualityColor: Color {
        guard let latency = latency else { return AppColors.offline }
        if latency < 100 { return AppColors.online }
        if latency < 300 { return AppColors.warning }
        return AppColors.offline
    }
}

#Preview {
    VStack(spacing: 20) {
        ReconnectingStatusView(attempt: 2, maxAttempts: 5) {}
        #if canImport(NMSSH)
        ConnectionModeIndicator(mode: .real)
        #endif
        ConnectionModeIndicator(mode: .simulated)
        ReconnectingProgressBar(attempt: 3, maxAttempts: 5)
    }
    .padding()
    .background(AppColors.background)
}
