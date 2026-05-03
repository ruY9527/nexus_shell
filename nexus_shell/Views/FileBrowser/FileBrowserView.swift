//
//  FileBrowserView.swift
//  nexus_shell
//
//  Created by opencode on 2026-05-03.
//

#if canImport(NMSSH)
import SwiftUI
import Combine
import UIKit
import UniformTypeIdentifiers

/// 文件浏览器视图
struct FileBrowserView: View {
    @StateObject private var viewModel: FileBrowserViewModel
    @Environment(\.dismiss) private var dismiss

    let sshConnection: RealSSHConnection

    init(sshConnection: RealSSHConnection) {
        self.sshConnection = sshConnection
        _viewModel = StateObject(wrappedValue: FileBrowserViewModel(sshConnection: sshConnection))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 路径导航栏
                PathNavigationBar(
                    currentPath: viewModel.currentPath,
                    onNavigate: { path in
                        viewModel.navigateTo(path: path)
                    }
                )

                // 文件列表
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.files.isEmpty {
                    EmptyDirectoryView()
                } else {
                    FileListView(
                        files: viewModel.files,
                        onFileTap: { file in
                            viewModel.handleFileTap(file)
                        },
                        onFileLongPress: { file in
                            viewModel.selectedFile = file
                            viewModel.showFileActions = true
                        }
                    )
                }

                // 底部操作栏
                FileActionBar(
                    onUpload: { viewModel.showUploadSheet = true },
                    onNewFolder: { viewModel.showNewFolderAlert = true }
                )
            }
            .navigationTitle("File Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("New Folder", isPresented: $viewModel.showNewFolderAlert) {
                TextField("Folder name", text: $viewModel.newFolderName)
                Button("Cancel", role: .cancel) {
                    viewModel.newFolderName = ""
                }
                Button("Create") {
                    viewModel.createFolder()
                }
            }
            .sheet(isPresented: $viewModel.showUploadSheet) {
                DocumentPickerView { urls in
                    viewModel.uploadFiles(urls)
                }
            }
            .confirmationDialog("File Actions", isPresented: $viewModel.showFileActions, presenting: viewModel.selectedFile) { file in
                if !file.isDirectory {
                    Button("Download") {
                        viewModel.downloadFile(file)
                    }
                }

                Button("Rename") {
                    viewModel.showRenameAlert = true
                }

                Button("Delete", role: .destructive) {
                    viewModel.deleteFile(file)
                }

                Button("Cancel", role: .cancel) {}
            } message: { file in
                Text(file.name)
            }
            .alert("Rename", isPresented: $viewModel.showRenameAlert, presenting: viewModel.selectedFile) { file in
                TextField("New name", text: $viewModel.newFileName)
                Button("Cancel", role: .cancel) {
                    viewModel.newFileName = ""
                }
                Button("Rename") {
                    viewModel.renameFile(file)
                }
            } message: { file in
                Text("Enter new name for \(file.name)")
            }
            .overlay {
                if viewModel.isTransferring {
                    TransferProgressOverlay(progress: viewModel.transferProgress)
                }
            }
        }
    }
}

// MARK: - Path Navigation Bar

struct PathNavigationBar: View {
    let currentPath: String
    let onNavigate: (String) -> Void

    var pathComponents: [String] {
        currentPath.split(separator: "/").map { String($0) }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    onNavigate("/")
                } label: {
                    Image(systemName: "house.fill")
                        .foregroundStyle(AppColors.accent)
                }

                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.secondaryText)

                    let path = "/" + pathComponents[0...index].joined(separator: "/")
                    Button {
                        onNavigate(path)
                    } label: {
                        Text(component)
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .background(AppColors.secondaryBackground)
    }
}

// MARK: - File List View

struct FileListView: View {
    let files: [SFTPFile]
    let onFileTap: (SFTPFile) -> Void
    let onFileLongPress: (SFTPFile) -> Void

    var sortedFiles: [SFTPFile] {
        let directories = files.filter { $0.isDirectory }.sorted { $0.name < $1.name }
        let regularFiles = files.filter { !$0.isDirectory }.sorted { $0.name < $1.name }
        return directories + regularFiles
    }

    var body: some View {
        List {
            ForEach(sortedFiles) { file in
                FileRowView(file: file)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onFileTap(file)
                    }
                    .onLongPressGesture {
                        onFileLongPress(file)
                    }
                    .listRowBackground(AppColors.cardBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let file: SFTPFile

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 文件图标
            Image(systemName: fileIcon)
                .font(.system(size: 24))
                .foregroundStyle(fileIconColor)
                .frame(width: 32)

            // 文件信息
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(file.readableSize)
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)

                    Text(file.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private var fileIcon: String {
        if file.isDirectory {
            return "folder.fill"
        } else if file.isSymbolicLink {
            return "link"
        } else {
            return "doc"
        }
    }

    private var fileIconColor: Color {
        if file.isDirectory {
            return AppColors.accent
        } else {
            return AppColors.secondaryText
        }
    }
}

// MARK: - Empty Directory View

struct EmptyDirectoryView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.secondaryText.opacity(0.5))

            Text("Empty Directory")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - File Action Bar

struct FileActionBar: View {
    let onUpload: () -> Void
    let onNewFolder: () -> Void

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            Button(action: onUpload) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("Upload")
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.accent)
            }

            Spacer()

            Button(action: onNewFolder) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("New Folder")
                }
                .font(AppTypography.label)
                .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(AppColors.secondaryBackground)
    }
}

// MARK: - Transfer Progress Overlay

struct TransferProgressOverlay: View {
    let progress: FTPProgress?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let progress = progress {
                ProgressView(value: progress.progress)
                    .progressViewStyle(.linear)
                    .tint(AppColors.accent)
                    .frame(width: 200)

                Text(progress.fileName)
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(AppColors.primaryText)

                Text("\(progress.percentComplete)%")
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.accent)
            } else {
                ProgressView()
                    .tint(AppColors.accent)

                Text("Transferring...")
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.md)
        .shadow(radius: 10)
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .fileURL])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

// MARK: - File Browser ViewModel

@MainActor
class FileBrowserViewModel: ObservableObject {
    @Published var files: [SFTPFile] = []
    @Published var currentPath: String = "/home"
    @Published var isLoading: Bool = false
    @Published var selectedFile: SFTPFile?
    @Published var showFileActions: Bool = false
    @Published var showUploadSheet: Bool = false
    @Published var showNewFolderAlert: Bool = false
    @Published var showRenameAlert: Bool = false
    @Published var newFolderName: String = ""
    @Published var newFileName: String = ""
    @Published var isTransferring: Bool = false
    @Published var transferProgress: FTPProgress?

    private let sftpManager: SFTPManager
    private let sshConnection: RealSSHConnection

    init(sshConnection: RealSSHConnection) {
        self.sshConnection = sshConnection
        self.sftpManager = SFTPManager()

        Task {
            await loadFiles()
        }
    }

    func loadFiles() async {
        isLoading = true

        do {
            if !sftpManager.isConnected {
                try await sftpManager.connect(to: sshConnection)
            }
            files = try await sftpManager.listDirectory(path: currentPath)
        } catch {
            print("Failed to load files: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func refresh() {
        Task {
            await loadFiles()
        }
    }

    func navigateTo(path: String) {
        currentPath = path
        Task {
            await loadFiles()
        }
    }

    func handleFileTap(_ file: SFTPFile) {
        if file.isDirectory {
            navigateTo(path: file.path)
        }
    }

    func createFolder() {
        guard !newFolderName.isEmpty else { return }

        let folderPath = currentPath.hasSuffix("/") ? currentPath + newFolderName : currentPath + "/" + newFolderName

        Task {
            do {
                try await sftpManager.createDirectory(path: folderPath)

                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .info,
                    message: "Created folder: \(newFolderName)"
                )
                LogStore.shared.addLog(log)

                newFolderName = ""
                await loadFiles()
            } catch {
                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .error,
                    message: "Create folder failed: \(newFolderName) - \(error.localizedDescription)"
                )
                LogStore.shared.addLog(log)
            }
        }
    }

    func deleteFile(_ file: SFTPFile) {
        Task {
            do {
                if file.isDirectory {
                    try await sftpManager.deleteDirectory(path: file.path)
                } else {
                    try await sftpManager.deleteFile(path: file.path)
                }

                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .info,
                    message: "Deleted: \(file.name)"
                )
                LogStore.shared.addLog(log)

                selectedFile = nil
                await loadFiles()
            } catch {
                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .error,
                    message: "Delete failed: \(file.name) - \(error.localizedDescription)"
                )
                LogStore.shared.addLog(log)
            }
        }
    }

    func renameFile(_ file: SFTPFile) {
        guard !newFileName.isEmpty else { return }

        let parentPath = (file.path as NSString).deletingLastPathComponent
        let newPath = parentPath.hasSuffix("/") ? parentPath + newFileName : parentPath + "/" + newFileName

        Task {
            do {
                try await sftpManager.rename(from: file.path, to: newPath)

                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .info,
                    message: "Renamed: \(file.name) -> \(newFileName)"
                )
                LogStore.shared.addLog(log)

                newFileName = ""
                selectedFile = nil
                await loadFiles()
            } catch {
                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .error,
                    message: "Rename failed: \(file.name) - \(error.localizedDescription)"
                )
                LogStore.shared.addLog(log)
            }
        }
    }

    func downloadFile(_ file: SFTPFile) {
        guard !file.isDirectory else { return }

        isTransferring = true

        Task {
            do {
                let localPath = SFTPManager.tempDownloadDirectory.appendingPathComponent(file.name).path
                try await sftpManager.downloadFile(remotePath: file.path, localPath: localPath) { [weak self] progress in
                    Task { @MainActor in
                        self?.transferProgress = progress
                    }
                }

                // 记录下载日志
                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .info,
                    message: "Downloaded: \(file.name) (\(file.readableSize))"
                )
                LogStore.shared.addLog(log)

                isTransferring = false
                selectedFile = nil
            } catch {
                let log = LogEntry(
                    serverId: sshConnection.serverId,
                    level: .error,
                    message: "Download failed: \(file.name) - \(error.localizedDescription)"
                )
                LogStore.shared.addLog(log)
                isTransferring = false
            }
        }
    }

    func uploadFiles(_ urls: [URL]) {
        isTransferring = true

        Task {
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                let fileName = url.lastPathComponent
                let remotePath = currentPath.hasSuffix("/") ? currentPath + fileName : currentPath + "/" + fileName

                do {
                    try await sftpManager.uploadFile(localPath: url.path, remotePath: remotePath) { [weak self] progress in
                        Task { @MainActor in
                            self?.transferProgress = progress
                        }
                    }

                    // 记录上传日志
                    let log = LogEntry(
                        serverId: sshConnection.serverId,
                        level: .info,
                        message: "Uploaded: \(fileName) to \(remotePath)"
                    )
                    LogStore.shared.addLog(log)
                } catch {
                    let log = LogEntry(
                        serverId: sshConnection.serverId,
                        level: .error,
                        message: "Upload failed: \(fileName) - \(error.localizedDescription)"
                    )
                    LogStore.shared.addLog(log)
                }
            }
            isTransferring = false
            showUploadSheet = false
            await loadFiles()
        }
    }
}

#Preview {
    Text("FileBrowserView Preview")
}

#endif
