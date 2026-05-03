//
//  SSHConfig.swift
//  nexus_shell
//
//  Created by opencode on 2026-05-03.
//

import Foundation
#if canImport(NMSSH)
import NMSSH
#endif

/// SSH 连接配置
struct SSHConfig: Codable, Equatable, Sendable {
    /// 连接超时时间（秒）
    var connectionTimeout: TimeInterval = 10.0

    /// 命令执行超时时间（秒）
    var commandTimeout: TimeInterval = 30.0

    /// 是否启用自动重连
    var autoReconnect: Bool = true

    /// 最大重连尝试次数
    var maxReconnectAttempts: Int = 3

    /// 重连间隔时间（秒）
    var reconnectDelay: TimeInterval = 2.0

    /// Keep-Alive 间隔时间（秒）
    var keepAliveInterval: TimeInterval = 60.0

    /// 是否验证主机密钥
    var verifyHostKey: Bool = true

    /// 终端类型（用于 PTY）
    var terminalType: TerminalType = .xterm256Color

    /// 默认配置
    static let `default` = SSHConfig()

    /// 高可靠性配置（更长超时）
    static let highReliability = SSHConfig(
        connectionTimeout: 30.0,
        commandTimeout: 60.0,
        autoReconnect: true,
        maxReconnectAttempts: 5,
        reconnectDelay: 3.0
    )

    /// 快速连接配置（短超时）
    static let fast = SSHConfig(
        connectionTimeout: 5.0,
        commandTimeout: 15.0,
        autoReconnect: false
    )
}

/// 终端类型枚举
enum TerminalType: String, Codable, CaseIterable, Sendable {
    case vanilla = "vanilla"
    case vt100 = "vt100"
    case vt102 = "vt102"
    case vt220 = "vt220"
    case ansi = "ansi"
    case xterm = "xterm"
    case xterm256Color = "xterm-256color"
    case linux = "linux"
    case screen = "screen"
    case screen256Color = "screen-256color"
    case tmux = "tmux"
    case rxvt = "rxvt"

    #if canImport(NMSSH)
    var nmsshPtyType: NMSSHChannelPtyTerminal {
        switch self {
        case .vanilla: return .vanilla
        case .vt100: return .VT100
        case .vt102: return .VT102
        case .vt220: return .VT220
        case .ansi: return .ansi
        case .xterm, .xterm256Color: return .xterm
        default: return .xterm
        }
    }
    #endif
}

/// SSH 认证方式配置
struct SSHAuthConfig: Codable, Equatable, Sendable {
    let method: AuthMethod
    let username: String
    let password: String?
    let privateKey: String?
    let passphrase: String?

    static func password(username: String, password: String) -> SSHAuthConfig {
        SSHAuthConfig(
            method: .password,
            username: username,
            password: password,
            privateKey: nil,
            passphrase: nil
        )
    }

    static func privateKey(username: String, privateKey: String, passphrase: String?) -> SSHAuthConfig {
        SSHAuthConfig(
            method: .privateKey,
            username: username,
            password: nil,
            privateKey: privateKey,
            passphrase: passphrase
        )
    }
}
