//
//  AppLogger.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  统一日志框架，使用 os.log 替代 print
//

import Foundation
import os.log

/// 应用日志分类
enum LogCategory: String {
    case ssh = "SSH"
    case command = "Command"
    case database = "Database"
    case ui = "UI"
    case network = "Network"
    case keychain = "Keychain"
    case sftp = "SFTP"
}

/// 应用日志级别
enum AppLogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// 统一日志管理器
/// 使用 os.log 框架，支持分类和日志级别
final class AppLogger {
    static let shared = AppLogger()

    private let subsystem = "com.nexus.shell"

    private var loggers: [LogCategory: Logger] = [:]
    private var isEnabled: Bool = true

    private init() {
        for category in [LogCategory.ssh, .command, .database, .ui, .network, .keychain, .sftp] {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    // MARK: - Configuration

    /// 设置日志是否启用
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Logging Methods

    /// 调试日志 - 仅在调试时输出
    func debug(_ message: String, category: LogCategory = .ui, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        #if DEBUG
        let logger = loggers[category] ?? defaultLogger
        let location = "\(fileName(file)):\(line) \(function)"
        logger.debug("[\(category.rawValue)] \(message) - \(location)")
        #endif
    }

    /// 信息日志
    func info(_ message: String, category: LogCategory = .ui, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let logger = loggers[category] ?? defaultLogger
        logger.info("[\(category.rawValue)] \(message)")
    }

    /// 警告日志
    func warning(_ message: String, category: LogCategory = .ui, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let logger = loggers[category] ?? defaultLogger
        logger.warning("[\(category.rawValue)] ⚠️ \(message)")
    }

    /// 错误日志
    func error(_ message: String, category: LogCategory = .ui, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled else { return }
        let logger = loggers[category] ?? defaultLogger
        logger.error("[\(category.rawValue)] ❌ \(message)")
    }

    /// 错误日志（带 Error 对象）
    func error(_ err: Error, category: LogCategory = .ui, file: String = #file, function: String = #function, line: Int = #line) {
        self.error(err.localizedDescription, category: category, file: file, function: function, line: line)
    }

    // MARK: - Convenience Methods

    /// SSH 相关日志
    static func ssh(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.ssh] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.ssh.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    /// 数据库相关日志
    static func database(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.database] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.database.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    /// 命令执行相关日志
    static func command(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.command] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.command.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    /// 网络相关日志
    static func network(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.network] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.network.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    /// Keychain 相关日志
    static func keychain(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.keychain] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.keychain.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    /// SFTP 相关日志
    static func sftp(_ message: String, level: AppLogLevel = .info) {
        let logger = shared.loggers[.sftp] ?? shared.defaultLogger
        let logMessage = "[\(LogCategory.sftp.rawValue)] \(message)"

        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(logMessage)")
            #endif
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }

    // MARK: - Private Helpers

    private var defaultLogger: Logger {
        Logger(subsystem: subsystem, category: "General")
    }

    private func fileName(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        return components.last ?? path
    }
}

// MARK: - Global Logger Functions

/// 全局日志函数，方便调用
func Log(_ message: String, category: LogCategory = .ui, level: AppLogLevel = .info) {
    switch level {
    case .debug:
        AppLogger.shared.debug(message, category: category)
    case .info:
        AppLogger.shared.info(message, category: category)
    case .warning:
        AppLogger.shared.warning(message, category: category)
    case .error:
        AppLogger.shared.error(message, category: category)
    }
}
