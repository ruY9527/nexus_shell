//
//  nexus_shellTests.swift
//  nexus_shellTests
//
//  Created by baoyang on 2026/4/22.
//

import XCTest
@testable import nexus_shell

final class nexus_shellTests: XCTestCase {

    @MainActor
    private func resetPersistentState() {
        DatabaseManager.shared.resetAllData()
        LogStore.shared.clearFilters()
        ServerStore.shared.selectRootFolder()
        FolderStore.shared.loadFolders()
    }

    @MainActor
    func testServerModelAndCommandSimulator() {
        resetPersistentState()

        let defaultPortServer = Server(name: "Default", host: "example.com", username: "deploy")
        XCTAssertEqual(defaultPortServer.displayAddress, "example.com")

        let customPortServer = Server(name: "Custom", host: "example.com", port: 2222, username: "deploy")
        XCTAssertEqual(customPortServer.displayAddress, "example.com:2222")

        let simulator = CommandSimulator(host: "demo.local", username: "tester", port: 22)
        XCTAssertEqual(simulator.simulate("pwd"), "/home/tester\n")

        let listing = simulator.simulate("ls")
        XCTAssertTrue(listing.contains("Documents"))
        XCTAssertTrue(listing.contains("README.md"))
        XCTAssertFalse(listing.contains(".bashrc"))

        XCTAssertEqual(simulator.simulate("cd /var/log"), "")
        XCTAssertEqual(simulator.simulate("pwd"), "/var/log\n")
        XCTAssertTrue(simulator.simulate("whoami").contains("tester"))
        XCTAssertTrue(simulator.simulate("cat /etc/os-release").contains("Ubuntu"))
        XCTAssertTrue(simulator.simulate("unknown-command").contains("command not found"))
    }

    @MainActor
    func testFolderServerAndLogStoresWorkTogether() throws {
        resetPersistentState()

        let folder = ServerFolder(name: "QA", color: .green, icon: .server, description: "Test lab")
        FolderStore.shared.addFolder(folder)
        XCTAssertEqual(FolderStore.shared.folders.count, 1)

        let rootServer = Server(name: "Root Server", host: "root.example.com", username: "root")
        ServerStore.shared.addServer(rootServer)
        XCTAssertEqual(ServerStore.shared.rootServerCount, 1)
        XCTAssertEqual(ServerStore.shared.servers.map(\.name), ["Root Server"])

        ServerStore.shared.updateServerFolder(rootServer.id, folderId: folder.id)
        XCTAssertEqual(ServerStore.shared.rootServerCount, 0)
        XCTAssertEqual(FolderStore.shared.serverCountInFolder(folder.id), 1)

        ServerStore.shared.selectFolder(folder.id)
        XCTAssertEqual(ServerStore.shared.servers.first?.name, "Root Server")

        let movedServer = try XCTUnwrap(ServerStore.shared.servers.first)
        movedServer.name = "Moved Server"
        movedServer.tags = ["qa", "ssh"]
        ServerStore.shared.updateServer(movedServer)
        XCTAssertEqual(ServerStore.shared.servers.first?.name, "Moved Server")
        XCTAssertEqual(ServerStore.shared.filteredServers.first?.tags, ["qa", "ssh"])

        LogStore.shared.addLog(LogEntry(serverId: movedServer.id, level: .info, message: "Connected to QA"))
        LogStore.shared.addLog(LogEntry(serverId: movedServer.id, level: .error, message: "Simulated failure"))
        XCTAssertEqual(LogStore.shared.totalLogs, 2)
        XCTAssertEqual(LogStore.shared.levelCounts[.error], 1)

        LogStore.shared.filterByServer(movedServer.id)
        XCTAssertEqual(LogStore.shared.logs.count, 2)

        ServerStore.shared.deleteServer(movedServer)
        XCTAssertEqual(FolderStore.shared.serverCountInFolder(folder.id), 0)
        XCTAssertTrue(FolderRepository.shared.delete(folder.id))
    }

    @MainActor
    func testSettingsObserverReflectsReset() {
        AppSettings.shared.hapticFeedbackEnabled = false
        AppSettings.shared.autoRefreshEnabled = false
        AppSettings.shared.refreshInterval = 30
        AppSettings.shared.terminalFontSize = 24
        AppSettings.shared.colorSchemeString = "light"

        AppSettings.shared.resetAllSettings()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        XCTAssertTrue(SettingsObserver.shared.hapticFeedbackEnabled)
        XCTAssertTrue(SettingsObserver.shared.autoRefreshEnabled)
        XCTAssertEqual(SettingsObserver.shared.refreshInterval, 5)
        XCTAssertEqual(SettingsObserver.shared.terminalFontSize, 14)
        XCTAssertEqual(SettingsObserver.shared.colorSchemeString, "dark")
    }
}
