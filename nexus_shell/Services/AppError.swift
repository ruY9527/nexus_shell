//
//  AppError.swift
//  nexus_shell
//
//  Created by baoyang on 2026/05/06.
//  统一错误处理框架
//

import Foundation

/// 应用错误类型
enum AppError: Error, LocalizedError {
    // MARK: - Database Errors
    case databaseFailed(String)
    case databaseNotFound
    case databaseOperationFailed(String)

    // MARK: - Keychain Errors
    case keychainSaveFailed(String)
    case keychainRetrieveFailed(String)
    case keychainDeleteFailed(String)
    case keychainNotFound

    // MARK: - SSH Errors
    case sshConnectionFailed(String)
    case sshAuthenticationFailed(String)
    case sshCommandFailed(String)
    case sshDisconnected
    case sshTimeout
    case sshReachabilityFailed(String)

    // MARK: - SFTP Errors
    case sftpConnectionFailed(String)
    case sftpOperationFailed(String)
    case sftpFileNotFound(String)
    case sftpPermissionDenied(String)

    // MARK: - Validation Errors
    case validationFailed(String)
    case invalidInput(String)
    case missingRequiredField(String)

    // MARK: - Network Errors
    case networkUnreachable
    case networkTimeout
    case networkFailed(String)

    // MARK: - File System Errors
    case fileNotFound(String)
    case fileOperationFailed(String)
    case directoryCreationFailed(String)

    // MARK: - General Errors
    case unknown(String)
    case notImplemented
    case cancelled

    // MARK: - Error Description

    var errorDescription: String? {
        switch self {
        // Database
        case .databaseFailed(let message):
            return "Database failed: \(message)"
        case .databaseNotFound:
            return "Database record not found"
        case .databaseOperationFailed(let message):
            return "Database operation failed: \(message)"

        // Keychain
        case .keychainSaveFailed(let message):
            return "Failed to save to Keychain: \(message)"
        case .keychainRetrieveFailed(let message):
            return "Failed to retrieve from Keychain: \(message)"
        case .keychainDeleteFailed(let message):
            return "Failed to delete from Keychain: \(message)"
        case .keychainNotFound:
            return "Credentials not found in Keychain"

        // SSH
        case .sshConnectionFailed(let message):
            return "SSH connection failed: \(message)"
        case .sshAuthenticationFailed(let message):
            return "SSH authentication failed: \(message)"
        case .sshCommandFailed(let message):
            return "SSH command failed: \(message)"
        case .sshDisconnected:
            return "SSH connection disconnected"
        case .sshTimeout:
            return "SSH connection timeout"
        case .sshReachabilityFailed(let message):
            return "Server unreachable: \(message)"

        // SFTP
        case .sftpConnectionFailed(let message):
            return "SFTP connection failed: \(message)"
        case .sftpOperationFailed(let message):
            return "SFTP operation failed: \(message)"
        case .sftpFileNotFound(let path):
            return "SFTP file not found: \(path)"
        case .sftpPermissionDenied(let path):
            return "SFTP permission denied: \(path)"

        // Validation
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"

        // Network
        case .networkUnreachable:
            return "Network unreachable"
        case .networkTimeout:
            return "Network timeout"
        case .networkFailed(let message):
            return "Network failed: \(message)"

        // File System
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"

        // General
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .notImplemented:
            return "Feature not implemented"
        case .cancelled:
            return "Operation cancelled"
        }
    }

    // MARK: - Error Code

    var errorCode: Int {
        switch self {
        case .databaseFailed: return 1001
        case .databaseNotFound: return 1002
        case .databaseOperationFailed: return 1003
        case .keychainSaveFailed: return 2001
        case .keychainRetrieveFailed: return 2002
        case .keychainDeleteFailed: return 2003
        case .keychainNotFound: return 2004
        case .sshConnectionFailed: return 3001
        case .sshAuthenticationFailed: return 3002
        case .sshCommandFailed: return 3003
        case .sshDisconnected: return 3004
        case .sshTimeout: return 3005
        case .sshReachabilityFailed: return 3006
        case .sftpConnectionFailed: return 4001
        case .sftpOperationFailed: return 4002
        case .sftpFileNotFound: return 4003
        case .sftpPermissionDenied: return 4004
        case .validationFailed: return 5001
        case .invalidInput: return 5002
        case .missingRequiredField: return 5003
        case .networkUnreachable: return 6001
        case .networkTimeout: return 6002
        case .networkFailed: return 6003
        case .fileNotFound: return 7001
        case .fileOperationFailed: return 7002
        case .directoryCreationFailed: return 7003
        case .unknown: return 9999
        case .notImplemented: return 9998
        case .cancelled: return 9997
        }
    }

    // MARK: - Category

    var category: String {
        switch self {
        case .databaseFailed, .databaseNotFound, .databaseOperationFailed:
            return "Database"
        case .keychainSaveFailed, .keychainRetrieveFailed, .keychainDeleteFailed, .keychainNotFound:
            return "Keychain"
        case .sshConnectionFailed, .sshAuthenticationFailed, .sshCommandFailed, .sshDisconnected, .sshTimeout, .sshReachabilityFailed:
            return "SSH"
        case .sftpConnectionFailed, .sftpOperationFailed, .sftpFileNotFound, .sftpPermissionDenied:
            return "SFTP"
        case .validationFailed, .invalidInput, .missingRequiredField:
            return "Validation"
        case .networkUnreachable, .networkTimeout, .networkFailed:
            return "Network"
        case .fileNotFound, .fileOperationFailed, .directoryCreationFailed:
            return "FileSystem"
        case .unknown, .notImplemented, .cancelled:
            return "General"
        }
    }

    // MARK: - Recovery Suggestion

    var recoverySuggestion: String? {
        switch self {
        case .databaseFailed, .databaseOperationFailed:
            return "Please try again later. If the problem persists, reset the app data."
        case .databaseNotFound:
            return "The requested data does not exist in the database."
        case .keychainSaveFailed, .keychainRetrieveFailed, .keychainDeleteFailed:
            return "Check if the app has the necessary Keychain permissions."
        case .keychainNotFound:
            return "Please re-enter your credentials in the server settings."
        case .sshConnectionFailed, .sshReachabilityFailed:
            return "Check if the server is running and the network is accessible."
        case .sshAuthenticationFailed:
            return "Verify your username and password or SSH key."
        case .sshCommandFailed:
            return "The command may not exist on the remote server."
        case .sshDisconnected:
            return "The connection was lost. Please reconnect."
        case .sshTimeout:
            return "The server took too long to respond. Try increasing the timeout."
        case .sftpConnectionFailed:
            return "Check SFTP server settings and network connectivity."
        case .sftpOperationFailed:
            return "The file operation failed. Check permissions."
        case .sftpFileNotFound:
            return "The file may have been deleted or moved."
        case .sftpPermissionDenied:
            return "You don't have permission to access this file."
        case .validationFailed, .invalidInput:
            return "Please check your input and try again."
        case .missingRequiredField:
            return "Please fill in all required fields."
        case .networkUnreachable:
            return "Check your internet connection."
        case .networkTimeout:
            return "The network is slow. Try again later."
        case .networkFailed:
            return "A network error occurred. Please try again."
        case .fileNotFound:
            return "The file may have been deleted or moved."
        case .fileOperationFailed:
            return "The file operation failed. Check permissions."
        case .directoryCreationFailed:
            return "Cannot create directory. Check storage space and permissions."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        case .notImplemented:
            return "This feature is not yet available."
        case .cancelled:
            return "The operation was cancelled."
        }
    }
}

// MARK: - Result Extension

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    var isFailure: Bool {
        !isSuccess
    }

    func getError() -> Error? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

// MARK: - Error Logging

extension Error {
    func log(category: LogCategory = .ui) {
        if let appError = self as? AppError {
            AppLogger.shared.error(appError.errorDescription ?? "Unknown error", category: category)
        } else {
            AppLogger.shared.error(self.localizedDescription, category: category)
        }
    }
}
