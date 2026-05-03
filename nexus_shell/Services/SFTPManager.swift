//
//  SFTPManager.swift
//  nexus_shell
//
//  Created by opencode on 2026-05-03.
//

import Foundation
#if canImport(NMSSH)
import NMSSH

/// SFTP 文件信息
struct SFTPFile: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let path: String
    let size: UInt64
    let isDirectory: Bool
    let isSymbolicLink: Bool
    let modifiedDate: Date
    let permissions: String

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: UInt64,
        isDirectory: Bool,
        isSymbolicLink: Bool = false,
        modifiedDate: Date,
        permissions: String
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.isSymbolicLink = isSymbolicLink
        self.modifiedDate = modifiedDate
        self.permissions = permissions
    }

    var readableSize: String {
        if isDirectory { return "-" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var shortPermissions: String {
        String(permissions.prefix(3))
    }
}

/// SFTP 传输进度
struct FTPProgress: Sendable {
    let bytesTransferred: UInt64
    let totalBytes: UInt64
    let fileName: String
    let isUpload: Bool

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }

    var percentComplete: Int {
        Int(progress * 100)
    }
}

/// SFTP 管理器错误
enum SFTPError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case operationFailed(String)
    case fileNotFound(String)
    case transferCancelled

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "SFTP not connected"
        case .connectionFailed(let msg):
            return "SFTP connection failed: \(msg)"
        case .operationFailed(let msg):
            return "SFTP operation failed: \(msg)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .transferCancelled:
            return "Transfer cancelled"
        }
    }
}

/// SFTP 管理器
class SFTPManager: @unchecked Sendable {

    private var session: NMSSHSession?
    private var sftp: NMSFTP?
    private let queue = DispatchQueue(label: "com.nexus_shell.sftp", qos: .userInitiated)

    private(set) var isConnected: Bool = false
    private var currentPath: String = "/home/"

    private var isCancelled: Bool = false

    init() {}

    deinit {
        disconnect()
    }

    // MARK: - Connection

    func connect(to sshConnection: RealSSHConnection) async throws {
        guard let session = await sshConnection.getNMSSHSession() else {
            throw SFTPError.connectionFailed("SSH session not available")
        }
        try connect(session: session, path: "/home/")
    }

    func connect(session: NMSSHSession, path: String = "/home/") throws {
        guard session.isConnected else {
            throw SFTPError.notConnected
        }

        self.session = session
        self.currentPath = path

        let sftp = NMSFTP(session: session)
        sftp.connect()

        guard sftp.isConnected else {
            throw SFTPError.connectionFailed("Failed to create SFTP session")
        }

        self.sftp = sftp
        self.isConnected = true
    }

    func disconnect() {
        sftp?.disconnect()
        sftp = nil
        session = nil
        isConnected = false
    }

    // MARK: - Directory Operations

    func listDirectory(path: String? = nil) async throws -> [SFTPFile] {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        let targetPath = path ?? currentPath

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard let contents = sftp.contentsOfDirectory(atPath: targetPath) as? [NMSFTPFile] else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to list directory"))
                    return
                }

                let files = contents.map { nmsftpFile -> SFTPFile in
                    let name = nmsftpFile.filename
                    let fullPath = targetPath.hasSuffix("/") ? targetPath + name : targetPath + "/" + name
                    let fileSize = nmsftpFile.fileSize?.uint64Value ?? 0

                    return SFTPFile(
                        name: name,
                        path: fullPath,
                        size: fileSize,
                        isDirectory: nmsftpFile.isDirectory,
                        modifiedDate: nmsftpFile.modificationDate ?? Date(),
                        permissions: nmsftpFile.permissions ?? "----------"
                    )
                }

                continuation.resume(returning: files)
            }
        }
    }

    func getCurrentPath() -> String {
        return currentPath
    }

    func changeDirectory(_ path: String) {
        if path.hasPrefix("/") {
            currentPath = path
        } else if path == ".." {
            let components = currentPath.split(separator: "/")
            if components.count > 1 {
                currentPath = "/" + components.dropLast().joined(separator: "/")
                if currentPath.isEmpty { currentPath = "/" }
            }
        } else if path == "~" {
            currentPath = "/home"
        } else {
            currentPath = currentPath.hasSuffix("/") ? currentPath + path : currentPath + "/" + path
        }

        if currentPath != "/" && currentPath.hasSuffix("/") {
            currentPath = String(currentPath.dropLast())
        }
    }

    // MARK: - File Operations

    func downloadFile(remotePath: String, localPath: String, progress: ((FTPProgress) -> Void)? = nil) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        self.isCancelled = false

        let fileSize = try await getFileSize(path: remotePath)
        let fileName = (remotePath as NSString).lastPathComponent

        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                guard !self.isCancelled else {
                    continuation.resume(throwing: SFTPError.transferCancelled)
                    return
                }

                let localURL = URL(fileURLWithPath: localPath)
                let localDirectory = localURL.deletingLastPathComponent()

                do {
                    try FileManager.default.createDirectory(at: localDirectory, withIntermediateDirectories: true)
                } catch {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to create local directory: \(error.localizedDescription)"))
                    return
                }

                let progressBlock: (UInt, UInt) -> Bool = { got, _ in
                    let progressInfo = FTPProgress(
                        bytesTransferred: UInt64(got),
                        totalBytes: fileSize,
                        fileName: fileName,
                        isUpload: false
                    )
                    DispatchQueue.main.async {
                        progress?(progressInfo)
                    }
                    return !self.isCancelled
                }

                guard let data = sftp.contents(atPath: remotePath, progress: progressBlock) else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to download file"))
                    return
                }

                do {
                    try data.write(to: URL(fileURLWithPath: localPath))
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to save file: \(error.localizedDescription)"))
                }
            }
        }
    }

    func uploadFile(localPath: String, remotePath: String, progress: ((FTPProgress) -> Void)? = nil) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        self.isCancelled = false

        guard FileManager.default.fileExists(atPath: localPath) else {
            throw SFTPError.fileNotFound(localPath)
        }

        let fileName = (localPath as NSString).lastPathComponent

        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                guard !self.isCancelled else {
                    continuation.resume(throwing: SFTPError.transferCancelled)
                    return
                }

                let progressBlock: (UInt) -> Bool = { sent in
                    let progressInfo = FTPProgress(
                        bytesTransferred: UInt64(sent),
                        totalBytes: UInt64(sent),
                        fileName: fileName,
                        isUpload: true
                    )
                    DispatchQueue.main.async {
                        progress?(progressInfo)
                    }
                    return !self.isCancelled
                }

                let success = sftp.writeFile(atPath: localPath, toFileAtPath: remotePath, progress: progressBlock)

                if self.isCancelled {
                    continuation.resume(throwing: SFTPError.transferCancelled)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to upload file"))
                }
            }
        }
    }

    func createDirectory(path: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if sftp.createDirectory(atPath: path) {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to create directory: \(path)"))
                }
            }
        }
    }

    func deleteFile(path: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if sftp.removeFile(atPath: path) {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to delete file: \(path)"))
                }
            }
        }
    }

    func deleteDirectory(path: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if sftp.removeDirectory(atPath: path) {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to delete directory: \(path)"))
                }
            }
        }
    }

    func rename(from: String, to: String) async throws {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if sftp.moveItem(atPath: from, toPath: to) {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: SFTPError.operationFailed("Failed to rename: \(from) -> \(to)"))
                }
            }
        }
    }

    func getFileSize(path: String) async throws -> UInt64 {
        guard let sftp = sftp, isConnected else {
            throw SFTPError.notConnected
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if let file = sftp.infoForFile(atPath: path) {
                    continuation.resume(returning: file.fileSize?.uint64Value ?? 0)
                } else {
                    continuation.resume(throwing: SFTPError.fileNotFound(path))
                }
            }
        }
    }

    func fileExists(path: String) async -> Bool {
        guard let sftp = sftp, isConnected else {
            return false
        }

        return await withCheckedContinuation { continuation in
            queue.async {
                let exists = sftp.fileExists(atPath: path)
                continuation.resume(returning: exists)
            }
        }
    }

    // MARK: - Transfer Control

    func cancelTransfer() {
        isCancelled = true
    }

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var tempDownloadDirectory: URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SFTPDownloads")
        if !FileManager.default.fileExists(atPath: tempDir.path) {
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }
        return tempDir
    }
}

#endif
