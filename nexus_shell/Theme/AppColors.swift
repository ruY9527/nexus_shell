//
//  AppColors.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 动态配色方案 - 支持深色和浅色模式
struct AppColors {
    // MARK: - Primary Colors
    
    /// 主背景色
    static var background: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.04, green: 0.055, blue: 0.1, alpha: 1) // 0A0E1A
            default:
                return UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1) // F5F5F7
            }
        })
    }
    
    /// 次级背景色
    static var secondaryBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1) // 111827
            default:
                return UIColor.white
            }
        })
    }
    
    /// 卡片背景色
    static var cardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.1, green: 0.14, blue: 0.2, alpha: 1) // 1A2332
            default:
                return UIColor.white
            }
        })
    }
    
    /// 主强调色 - 电光蓝
    static var accent: Color {
        Color(hex: "00D4FF")
    }
    
    /// 次级强调色 - 霓虹紫
    static var secondaryAccent: Color {
        Color(hex: "8B5CF6")
    }
    
    // MARK: - Status Colors
    
    /// 在线状态 - 翠绿
    static var online: Color {
        Color(hex: "10B981")
    }
    
    /// 离线状态 - 警示红
    static var offline: Color {
        Color(hex: "EF4444")
    }
    
    /// 警告状态 - 琥珀橙
    static var warning: Color {
        Color(hex: "F59E0B")
    }
    
    /// 未知状态 - 银灰
    static var unknown: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1) // 6B7280
            default:
                return UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1) // 9CA3AF
            }
        })
    }
    
    // MARK: - Text Colors
    
    /// 主文字色
    static var primaryText: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.976, green: 0.98, blue: 0.984, alpha: 1) // F9FAFB
            default:
                return UIColor(red: 0.12, green: 0.16, blue: 0.22, alpha: 1) // 1F2937
            }
        })
    }
    
    /// 次级文字色
    static var secondaryText: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1) // 9CA3AF
            default:
                return UIColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1) // 6B7280
            }
        })
    }
    
    /// 禁用文字色
    static var disabledText: Color {
        Color(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.29, green: 0.33, blue: 0.39, alpha: 1) // 4B5563
            default:
                return UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1) // D1D5DB
            }
        })
    }
    
    // MARK: - Gradient Colors
    
    /// 主渐变
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00D4FF"), Color(hex: "8B5CF6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 背景渐变
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 0.04, green: 0.055, blue: 0.1, alpha: 1)
                    default:
                        return UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
                    }
                }),
                Color(uiColor: UIColor { traitCollection in
                    switch traitCollection.userInterfaceStyle {
                    case .dark:
                        return UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1)
                    default:
                        return UIColor(red: 0.9, green: 0.9, blue: 0.91, alpha: 1)
                    }
                })
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 卡片发光渐变
    static func cardGlow(status: ServerStatus) -> some ShapeStyle {
        let color: Color
        switch status {
        case .online: color = online
        case .offline: color = offline
        case .warning: color = warning
        case .unknown: color = unknown
        }
        return LinearGradient(
            colors: [color.opacity(0.3), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        // 清理 hex 字符串：移除 # 前缀和空白字符
        let cleanedHex = hex
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        var int: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&int)
        
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        
        switch cleanedHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // 默认返回黑色
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}