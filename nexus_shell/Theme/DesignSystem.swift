//
//  DesignSystem.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 设计系统常量
struct DesignSystem {
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Radius
    
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = .infinity
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let `default` = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Elevation (Shadows)
    
    struct Elevation {
        static let none = Color.clear
        
        static func low(_ color: Color = Color.black.opacity(0.1)) -> some View {
            VStack {}
                .shadow(color: color, radius: 4, x: 0, y: 2)
        }
        
        static func medium(_ color: Color = Color.black.opacity(0.15)) -> some View {
            VStack {}
                .shadow(color: color, radius: 8, x: 0, y: 4)
        }
        
        static func high(_ color: Color = Color.black.opacity(0.2)) -> some View {
            VStack {}
                .shadow(color: color, radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - View Modifiers

/// 卡片样式修饰符
struct CardStyle: ViewModifier {
    var status: ServerStatus = .unknown
    var isGlowing: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .cornerRadius(DesignSystem.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(
                        status == .unknown 
                            ? Color.white.opacity(0.1) 
                            : statusColor.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .if(isGlowing && status != .unknown) { view in
                view.shadow(color: statusColor.opacity(0.3), radius: 8, x: 0, y: 0)
            }
    }
    
    private var statusColor: Color {
        switch status {
        case .online: return AppColors.online
        case .offline: return AppColors.offline
        case .warning: return AppColors.warning
        case .unknown: return AppColors.unknown
        }
    }
}

extension View {
    func cardStyle(status: ServerStatus = .unknown, isGlowing: Bool = false) -> some View {
        modifier(CardStyle(status: status, isGlowing: isGlowing))
    }
}

// MARK: - Conditional Modifier Helper

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Card Style Demo")
            .font(AppTypography.heading1)
            .foregroundStyle(AppColors.primaryText)
        
        HStack(spacing: 16) {
            VStack {
                Text("Online")
                    .foregroundStyle(AppColors.primaryText)
                Text("✓")
                    .font(.title)
                    .foregroundStyle(AppColors.online)
            }
            .frame(width: 100, height: 80)
            .cardStyle(status: .online, isGlowing: true)
            
            VStack {
                Text("Offline")
                    .foregroundStyle(AppColors.primaryText)
                Text("✗")
                    .font(.title)
                    .foregroundStyle(AppColors.offline)
            }
            .frame(width: 100, height: 80)
            .cardStyle(status: .offline, isGlowing: true)
            
            VStack {
                Text("Warning")
                    .foregroundStyle(AppColors.primaryText)
                Text("!")
                    .font(.title)
                    .foregroundStyle(AppColors.warning)
            }
            .frame(width: 100, height: 80)
            .cardStyle(status: .warning, isGlowing: true)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}