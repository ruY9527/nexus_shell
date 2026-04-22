//
//  AppTypography.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import SwiftUI

/// 应用字体系统
struct AppTypography {
    // MARK: - Display Styles
    
    /// 大标题 - 用于仪表盘主要数值
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    
    /// 中标题
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    
    /// 小标题
    static let displaySmall = Font.system(size: 28, weight: .semibold, design: .rounded)
    
    // MARK: - Heading Styles
    
    /// 一级标题 - 页面标题
    static let heading1 = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    /// 二级标题 - 卡片标题
    static let heading2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    /// 三级标题 - 区块标题
    static let heading3 = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // MARK: - Body Styles
    
    /// 正文 - 常规文本
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// 正文小号
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    /// 正文次要
    static let bodySecondary = Font.system(size: 14, weight: .regular, design: .default)
    
    // MARK: - Label Styles
    
    /// 标签 - 按钮文字
    static let label = Font.system(size: 14, weight: .medium, design: .rounded)
    
    /// 小标签 - 辅助文字
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .rounded)
    
    /// 大写标签 - 状态指示
    static let labelUppercase = Font.system(size: 11, weight: .semibold, design: .rounded)
    
    // MARK: - Terminal Styles
    
    /// 终端等宽字体
    static let terminal = Font.system(size: 14, weight: .regular, design: .monospaced)
    
    /// 终端小号
    static let terminalSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    
    /// 代码字体
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
}