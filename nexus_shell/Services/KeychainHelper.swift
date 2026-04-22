//
//  KeychainHelper.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation
import Security

/// Keychain 安全存储助手
/// 用于存储服务器密码和私钥等敏感信息
final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Key Prefix
    
    private let keyPrefix = "nexus_shell_"
    
    private func makeKey(for serverId: UUID, type: KeyType) -> String {
        return keyPrefix + type.rawValue + "_" + serverId.uuidString
    }
    
    enum KeyType: String {
        case password = "password"
        case privateKey = "private_key"
        case passphrase = "passphrase"
    }
    
    // MARK: - Save
    
    /// 保存密码到 Keychain
    func savePassword(_ password: String, for serverId: UUID) -> Bool {
        let key = makeKey(for: serverId, type: .password)
        return save(password, for: key)
    }
    
    /// 保存私钥到 Keychain
    func savePrivateKey(_ privateKey: String, for serverId: UUID) -> Bool {
        let key = makeKey(for: serverId, type: .privateKey)
        return save(privateKey, for: key)
    }
    
    /// 保存私钥密码短语到 Keychain
    func savePassphrase(_ passphrase: String, for serverId: UUID) -> Bool {
        let key = makeKey(for: serverId, type: .passphrase)
        return save(passphrase, for: key)
    }
    
    private func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // 先删除旧值
        delete(key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve
    
    /// 获取密码
    func getPassword(for serverId: UUID) -> String? {
        let key = makeKey(for: serverId, type: .password)
        return retrieve(key)
    }
    
    /// 获取私钥
    func getPrivateKey(for serverId: UUID) -> String? {
        let key = makeKey(for: serverId, type: .privateKey)
        return retrieve(key)
    }
    
    /// 获取私钥密码短语
    func getPassphrase(for serverId: UUID) -> String? {
        let key = makeKey(for: serverId, type: .passphrase)
        return retrieve(key)
    }
    
    private func retrieve(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Delete
    
    /// 删除服务器相关的所有敏感信息
    func deleteAllForServer(_ serverId: UUID) {
        deletePassword(for: serverId)
        deletePrivateKey(for: serverId)
        deletePassphrase(for: serverId)
    }
    
    func deletePassword(for serverId: UUID) {
        let key = makeKey(for: serverId, type: .password)
        delete(key)
    }
    
    func deletePrivateKey(for serverId: UUID) {
        let key = makeKey(for: serverId, type: .privateKey)
        delete(key)
    }
    
    func deletePassphrase(for serverId: UUID) {
        let key = makeKey(for: serverId, type: .passphrase)
        delete(key)
    }
    
    private func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Update
    
    /// 更新密码
    func updatePassword(_ password: String, for serverId: UUID) -> Bool {
        let key = makeKey(for: serverId, type: .password)
        return update(password, for: key)
    }
    
    /// 更新私钥
    func updatePrivateKey(_ privateKey: String, for serverId: UUID) -> Bool {
        let key = makeKey(for: serverId, type: .privateKey)
        return update(privateKey, for: key)
    }
    
    private func update(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // 如果不存在，则创建新条目
            return save(value, for: key)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Check Exists
    
    func hasPassword(for serverId: UUID) -> Bool {
        return getPassword(for: serverId) != nil
    }
    
    func hasPrivateKey(for serverId: UUID) -> Bool {
        return getPrivateKey(for: serverId) != nil
    }
}