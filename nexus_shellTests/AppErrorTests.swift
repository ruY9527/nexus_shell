//
//  AppErrorTests.swift
//  nexus_shellTests
//
//  Created by baoyang on 2026/05/06.
//

import XCTest
@testable import nexus_shell

final class AppErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testDatabaseErrors() {
        let error = AppError.databaseFailed("Connection lost")
        XCTAssertEqual(error.errorDescription, "Database failed: Connection lost")
        XCTAssertEqual(error.category, "Database")
        XCTAssertEqual(error.errorCode, 1001)
    }

    func testDatabaseNotFound() {
        let error = AppError.databaseNotFound
        XCTAssertEqual(error.errorDescription, "Database record not found")
        XCTAssertEqual(error.category, "Database")
    }

    func testKeychainErrors() {
        let error = AppError.keychainNotFound
        XCTAssertEqual(error.errorDescription, "Credentials not found in Keychain")
        XCTAssertEqual(error.category, "Keychain")
        XCTAssertEqual(error.errorCode, 2004)
    }

    func testSSHConnectionErrors() {
        let error = AppError.sshConnectionFailed("Host unreachable")
        XCTAssertEqual(error.errorDescription, "SSH connection failed: Host unreachable")
        XCTAssertEqual(error.category, "SSH")
        XCTAssertEqual(error.errorCode, 3001)
    }

    func testSSHAuthenticationErrors() {
        let error = AppError.sshAuthenticationFailed("Invalid credentials")
        XCTAssertEqual(error.errorDescription, "SSH authentication failed: Invalid credentials")
        XCTAssertEqual(error.category, "SSH")
    }

    func testSSHTimeout() {
        let error = AppError.sshTimeout
        XCTAssertEqual(error.errorDescription, "SSH connection timeout")
        XCTAssertEqual(error.category, "SSH")
    }

    func testSFTPFileNotFound() {
        let error = AppError.sftpFileNotFound("/path/to/file.txt")
        XCTAssertEqual(error.errorDescription, "SFTP file not found: /path/to/file.txt")
        XCTAssertEqual(error.category, "SFTP")
    }

    func testValidationErrors() {
        let error = AppError.invalidInput("Port must be between 1 and 65535")
        XCTAssertEqual(error.errorDescription, "Invalid input: Port must be between 1 and 65535")
        XCTAssertEqual(error.category, "Validation")
    }

    func testMissingRequiredField() {
        let error = AppError.missingRequiredField("password")
        XCTAssertEqual(error.errorDescription, "Missing required field: password")
        XCTAssertEqual(error.category, "Validation")
    }

    func testNetworkErrors() {
        let error = AppError.networkUnreachable
        XCTAssertEqual(error.errorDescription, "Network unreachable")
        XCTAssertEqual(error.category, "Network")
        XCTAssertEqual(error.errorCode, 6001)
    }

    func testUnknownError() {
        let error = AppError.unknown("Something went wrong")
        XCTAssertEqual(error.errorDescription, "Unknown error: Something went wrong")
        XCTAssertEqual(error.category, "General")
    }

    func testNotImplementedError() {
        let error = AppError.notImplemented
        XCTAssertEqual(error.errorDescription, "Feature not implemented")
        XCTAssertEqual(error.category, "General")
    }

    // MARK: - Recovery Suggestion Tests

    func testRecoverySuggestionForSSHConnection() {
        let error = AppError.sshConnectionFailed("timeout")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("server"))
    }

    func testRecoverySuggestionForKeychain() {
        let error = AppError.keychainNotFound
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("credentials"))
    }

    func testRecoverySuggestionForValidation() {
        let error = AppError.invalidInput("test")
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("input"))
    }

    // MARK: - Error Code Tests

    func testErrorCodesAreUnique() {
        let errors: [AppError] = [
            .databaseFailed("test"),
            .databaseNotFound,
            .databaseOperationFailed("test"),
            .keychainSaveFailed("test"),
            .keychainRetrieveFailed("test"),
            .keychainDeleteFailed("test"),
            .keychainNotFound,
            .sshConnectionFailed("test"),
            .sshAuthenticationFailed("test"),
            .sshCommandFailed("test"),
            .sshDisconnected,
            .sshTimeout,
            .sshReachabilityFailed("test"),
            .sftpConnectionFailed("test"),
            .sftpOperationFailed("test"),
            .sftpFileNotFound("test"),
            .sftpPermissionDenied("test"),
            .validationFailed("test"),
            .invalidInput("test"),
            .missingRequiredField("test"),
            .networkUnreachable,
            .networkTimeout,
            .networkFailed("test"),
            .fileNotFound("test"),
            .fileOperationFailed("test"),
            .directoryCreationFailed("test"),
            .unknown("test"),
            .notImplemented,
            .cancelled
        ]

        let codes = errors.map { $0.errorCode }
        let uniqueCodes = Set(codes)
        XCTAssertEqual(codes.count, uniqueCodes.count, "Error codes should be unique")
    }

    // MARK: - Category Tests

    func testAllErrorsHaveValidCategory() {
        let error = AppError.databaseFailed("test")
        XCTAssertFalse(error.category.isEmpty)

        let error2 = AppError.sshConnectionFailed("test")
        XCTAssertFalse(error2.category.isEmpty)

        let error3 = AppError.validationFailed("test")
        XCTAssertFalse(error3.category.isEmpty)
    }
}

// MARK: - AppLogger Tests

final class AppLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppLogger.shared.setEnabled(true)
    }

    func testLoggerInitialization() {
        let logger = AppLogger.shared
        XCTAssertNotNil(logger)
    }

    func testLogCategorySSH() {
        AppLogger.ssh("Test message", level: .info)
    }

    func testLogCategoryDatabase() {
        AppLogger.database("Test message", level: .info)
    }

    func testLogCategoryCommand() {
        AppLogger.command("Test message", level: .info)
    }

    func testLogCategoryNetwork() {
        AppLogger.network("Test message", level: .info)
    }

    func testLogCategoryKeychain() {
        AppLogger.keychain("Test message", level: .info)
    }

    func testLogCategorySFTP() {
        AppLogger.sftp("Test message", level: .info)
    }

    func testWarningLevel() {
        AppLogger.ssh("Warning message", level: .warning)
    }

    func testErrorLevel() {
        AppLogger.ssh("Error message", level: .error)
    }

    func testDebugLevel() {
        AppLogger.ssh("Debug message", level: .debug)
    }
}

// MARK: - SSHConfig Tests

final class SSHConfigTests: XCTestCase {

    func testDefaultConfig() {
        let config = SSHConfig.default
        XCTAssertEqual(config.connectionTimeout, 30)
        XCTAssertEqual(config.commandTimeout, 60)
        XCTAssertEqual(config.autoReconnect, true)
        XCTAssertEqual(config.maxReconnectAttempts, 3)
        XCTAssertEqual(config.reconnectDelay, 2.0)
        XCTAssertEqual(config.keepAliveInterval, 30)
        XCTAssertEqual(config.terminalType, .xterm256Color)
    }

    func testCustomConfig() {
        var config = SSHConfig.default
        config.connectionTimeout = 60
        config.commandTimeout = 120
        config.autoReconnect = false
        config.maxReconnectAttempts = 5

        XCTAssertEqual(config.connectionTimeout, 60)
        XCTAssertEqual(config.commandTimeout, 120)
        XCTAssertEqual(config.autoReconnect, false)
        XCTAssertEqual(config.maxReconnectAttempts, 5)
    }

    func testConfigEquality() {
        let config1 = SSHConfig.default
        let config2 = SSHConfig.default
        XCTAssertEqual(config1.connectionTimeout, config2.connectionTimeout)
        XCTAssertEqual(config1.autoReconnect, config2.autoReconnect)
    }
}

// MARK: - Result Extension Tests

final class ResultExtensionTests: XCTestCase {

    func testSuccessResult() {
        let result: Result<String, AppError> = .success("test")
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(result.isFailure)
        XCTAssertNil(result.getError())
    }

    func testFailureResult() {
        let result: Result<String, AppError> = .failure(.databaseFailed("test"))
        XCTAssertFalse(result.isSuccess)
        XCTAssertTrue(result.isFailure)
        XCTAssertNotNil(result.getError())
    }
}
