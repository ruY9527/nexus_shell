//
//  LogEntry.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import SwiftUI

/// 日志级别
enum LogLevel: String, Codable, CaseIterable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    
    var color: Color {
        switch self {
        case .debug: return AppColors.secondaryText
        case .info: return AppColors.accent
        case .warning: return AppColors.warning
        case .error: return AppColors.offline
        }
    }
    
    var icon: String {
        switch self {
        case .debug: return "ladybug"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var localizedKey: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

/// 日志条目模型
struct LogEntry: Identifiable, Equatable, Hashable {
    var id: UUID
    var serverId: UUID
    var timestamp: Date
    var level: LogLevel
    var message: String
    
    init(
        id: UUID = UUID(),
        serverId: UUID,
        timestamp: Date = Date(),
        level: LogLevel,
        message: String
    ) {
        self.id = id
        self.serverId = serverId
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
    
    static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 从数据库行创建 LogEntry
    static func fromDatabaseRow(_ row: [String: Any]) -> LogEntry? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let serverIdString = row["server_id"] as? String,
              let serverId = UUID(uuidString: serverIdString),
              let timestampValue = row["timestamp"] as? Double,
              let levelString = row["level"] as? String,
              let level = LogLevel(rawValue: levelString),
              let message = row["message"] as? String else {
            return nil
        }
        
        return LogEntry(
            id: id,
            serverId: serverId,
            timestamp: Date(timeIntervalSince1970: timestampValue),
            level: level,
            message: message
        )
    }
}

// MARK: - LogEventType

/// 日志事件类型
enum LogEventType: String, Codable, CaseIterable, Sendable {
    case connectionEstablished = "Connection Established"
    case connectionClosed = "Connection Closed"
    case authenticationSuccess = "Authentication Success"
    case authenticationFailed = "Authentication Failed"
    case commandExecuted = "Command Executed"
    case errorOccurred = "Error Occurred"
    case statusChanged = "Status Changed"
    case fileTransfer = "File Transfer"
    
    var icon: String {
        switch self {
        case .connectionEstablished: return "link.circle.fill"
        case .connectionClosed: return "link.circle.slash"
        case .authenticationSuccess: return "checkmark.shield.fill"
        case .authenticationFailed: return "xmark.shield.fill"
        case .commandExecuted: return "terminal"
        case .errorOccurred: return "xmark.octagon.fill"
        case .statusChanged: return "arrow.right.circle"
        case .fileTransfer: return "arrow.down.circle.fill"
        }
    }
    
    var defaultLevel: LogLevel {
        switch self {
        case .connectionEstablished, .authenticationSuccess, .statusChanged:
            return .info
        case .connectionClosed, .commandExecuted, .fileTransfer:
            return .info
        case .authenticationFailed, .errorOccurred:
            return .error
        }
    }
}