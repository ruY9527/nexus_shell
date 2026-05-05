//
//  CommandSimulator.swift
//  nexus_shell
//
//  Created by baoyang on 2026/4/22.
//

import Foundation

/// 命令模拟器 - 模拟 Linux 命令输出
final class CommandSimulator {

    // MARK: - Properties

    private let engine: DefaultCommandEngine

    // MARK: - Initialization

    init(host: String, username: String, port: Int) {
        self.engine = DefaultCommandEngine(host: host, username: username, port: port)
    }

    // MARK: - Public Methods

    /// 模拟命令执行并返回输出
    func simulate(_ command: String) -> String {
        return engine.execute(command)
    }

    /// 更新当前目录
    func setCurrentDirectory(_ path: String) {
        engine.setCurrentDirectory(path)
    }

    /// 获取当前目录
    func getCurrentDirectory() -> String {
        return engine.currentDirectory
    }
}