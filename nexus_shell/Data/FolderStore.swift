//
//  FolderStore.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Combine

/// 文件夹数据存储
/// 用于 SwiftUI 视图绑定和状态管理
@MainActor
class FolderStore: ObservableObject {
    static let shared = FolderStore()
    
    @Published var folders: [ServerFolder] = []
    @Published var selectedFolderId: UUID?
    
    private let repository = FolderRepository.shared
    private let serverRepository = ServerRepository.shared
    
    private init() {
        loadFolders()
    }
    
    // MARK: - Data Loading
    
    /// 加载所有文件夹
    func loadFolders() {
        folders = repository.fetchAll()
    }
    
    /// 刷新文件夹数据
    func refresh() {
        loadFolders()
    }
    
    /// 获取选中的文件夹
    var selectedFolder: ServerFolder? {
        if let id = selectedFolderId {
            return folders.first { $0.id == id }
        }
        return nil
    }
    
    /// 根目录（无文件夹）显示名称
    var rootFolderName: String {
        String(localized: "Root")
    }
    
    // MARK: - CRUD Operations
    
    /// 添加文件夹
    func addFolder(_ folder: ServerFolder) {
        if repository.insert(folder) {
            loadFolders()
        }
    }
    
    /// 创建新文件夹
    func createFolder(
        name: String,
        color: FolderColor = .blue,
        icon: FolderIcon = .folder,
        description: String? = nil
    ) -> ServerFolder {
        let folder = ServerFolder(
            name: name,
            color: color,
            icon: icon,
            description: description,
            sortOrder: folders.count
        )
        
        addFolder(folder)
        return folder
    }
    
    /// 更新文件夹
    func updateFolder(_ folder: ServerFolder) {
        if repository.update(folder) {
            loadFolders()
        }
    }
    
    /// 删除文件夹
    func deleteFolder(_ folderId: UUID) {
        if repository.delete(folderId) {
            // 如果删除的是当前选中的文件夹，切换到根目录
            if selectedFolderId == folderId {
                selectedFolderId = nil
            }
            loadFolders()
        }
    }
    
    /// 获取文件夹
    func getFolder(byId id: UUID) -> ServerFolder? {
        return repository.fetchById(id)
    }
    
    // MARK: - Folder Contents
    
    /// 获取文件夹内的服务器数量
    func serverCountInFolder(_ folderId: UUID) -> Int {
        return repository.countByFolder(folderId)
    }
    
    /// 获取根目录服务器数量
    func rootServerCount() -> Int {
        return serverRepository.fetchRootServers().count
    }
    
    /// 获取文件夹内的服务器
    func serversInFolder(_ folderId: UUID) -> [Server] {
        return repository.getServersInFolder(folderId)
    }
    
    /// 获取根目录的服务器
    func rootServers() -> [Server] {
        return repository.getRootServers()
    }
    
    /// 获取当前选中位置的服务器（文件夹或根目录）
    func serversForCurrentSelection() -> [Server] {
        if let folderId = selectedFolderId {
            return serversInFolder(folderId)
        }
        return rootServers()
    }
    
    // MARK: - Statistics
    
    /// 文件夹总数
    var totalFolders: Int {
        repository.count()
    }
    
    /// 所有文件夹及其服务器数量
    var foldersWithCounts: [(ServerFolder, Int)] {
        folders.map { folder in
            (folder, serverCountInFolder(folder.id))
        }
    }
    
    // MARK: - Selection
    
    /// 选择文件夹
    func selectFolder(_ folderId: UUID?) {
        selectedFolderId = folderId
    }
    
    /// 切换到根目录
    func selectRoot() {
        selectedFolderId = nil
    }
    
    // MARK: - Sort
    
    /// 更新文件夹排序
    func updateSortOrder(_ folderIds: [UUID]) {
        _ = repository.updateSortOrders(folderIds)
        loadFolders()
    }
}