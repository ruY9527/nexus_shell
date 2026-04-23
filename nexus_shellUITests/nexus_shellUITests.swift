//
//  nexus_shellUITests.swift
//  nexus_shellUITests
//
//  Created by baoyang on 2026/4/22.
//

import XCTest

@MainActor
final class nexus_shellUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainTabsSettingsLogsAndTerminalSession() throws {
        app = launchApp(seedData: true)

        XCTAssertTrue(app.staticTexts["Dashboard"].waitForExistence(timeout: 10))

        app.element("tab.servers").tap()
        XCTAssertTrue(app.staticTexts["Servers"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.element("folderRow.Company A").waitForExistence(timeout: 10))
        XCTAssertTrue(app.element("serverRow.Public Server").waitForExistence(timeout: 10))

        app.element("folderRow.Company A").tap()
        XCTAssertTrue(app.staticTexts["Company A"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.element("serverRow.Dev Server").waitForExistence(timeout: 10))
        app.buttons["Back"].tap()

        app.element("tab.logs").tap()
        XCTAssertTrue(app.staticTexts["Logs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Sample log for Public Server"].waitForExistence(timeout: 10))

        app.element("tab.settings").tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Terminal Font Size"].exists)
        app.buttons["Done"].tap()

        app.element("tab.terminal").tap()
        XCTAssertTrue(app.staticTexts["No Active Session"].waitForExistence(timeout: 10))
        app.buttons["terminal.selectServer"].tap()
        app.element("terminal.server.Public Server").tap()

        XCTAssertTrue(app.staticTexts["Connected"].waitForExistence(timeout: 8))
        let commandInput = app.textFields["terminal.commandInput"]
        XCTAssertTrue(commandInput.waitForExistence(timeout: 10))
        commandInput.tap()
        commandInput.typeText("whoami\n")
        XCTAssertTrue(app.staticText(containing: "$ whoami").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticText(containing: "\nuser").waitForExistence(timeout: 10))

        commandInput.tap()
        commandInput.typeText("pwd")
        app.buttons["terminal.sendCommand"].tap()
        XCTAssertTrue(app.staticText(containing: "$ pwd").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticText(containing: "/home/user").waitForExistence(timeout: 10))

        app.buttons["terminal.quickCommands"].tap()
        XCTAssertTrue(app.buttons["terminal.quickCommand.hostname"].waitForExistence(timeout: 10))
        app.buttons["terminal.quickCommand.hostname"].tap()
        XCTAssertTrue(app.staticText(containing: "$ hostname").waitForExistence(timeout: 10))

        app.buttons["Disconnect"].tap()
        XCTAssertTrue(app.staticTexts["No Active Session"].waitForExistence(timeout: 10))
    }

    func testCreateMoveAndDeleteServerFlow() throws {
        app = launchApp(seedData: false)

        app.element("tab.servers").tap()
        XCTAssertTrue(app.staticTexts["No Servers Yet"].waitForExistence(timeout: 10))

        app.buttons["servers.empty.createFolder"].tap()
        let folderName = app.textFields["addFolder.name"]
        XCTAssertTrue(folderName.waitForExistence(timeout: 10))
        folderName.typeText("QA Folder")
        app.buttons["addFolder.create"].tap()
        XCTAssertTrue(app.element("folderRow.QA Folder").waitForExistence(timeout: 10))

        app.element("folderRow.QA Folder").tap()
        XCTAssertTrue(app.staticTexts["No Servers in QA Folder"].waitForExistence(timeout: 10))
        app.buttons["servers.folder.addServer"].tap()

        XCTAssertTrue(app.staticTexts["Add Server"].waitForExistence(timeout: 10))
        app.textFields["addServer.name"].tap()
        app.textFields["addServer.name"].typeText("UI Test Server")
        app.textFields["addServer.host"].tap()
        app.textFields["addServer.host"].typeText("127.0.0.1")
        app.textFields["addServer.username"].tap()
        app.textFields["addServer.username"].typeText("tester")
        app.secureTextFields["addServer.password"].tap()
        app.secureTextFields["addServer.password"].typeText("secret123")
        app.buttons["addServer.save"].tap()
        app.alerts["Save Server?"].buttons["Save"].tap()

        let folderServer = app.element("serverRow.UI Test Server")
        XCTAssertTrue(folderServer.waitForExistence(timeout: 10))
        folderServer.swipeLeft()
        XCTAssertTrue(app.buttons["serverRow.move.UI Test Server"].waitForExistence(timeout: 10))
        app.buttons["serverRow.move.UI Test Server"].tap()
        XCTAssertTrue(app.staticTexts["Move Server"].waitForExistence(timeout: 10))
        app.element("moveServer.root").tap()
        XCTAssertFalse(folderServer.waitForExistence(timeout: 2))

        app.buttons["Back"].tap()
        let rootServer = app.element("serverRow.UI Test Server")
        XCTAssertTrue(rootServer.waitForExistence(timeout: 10))

        rootServer.tap()
        XCTAssertTrue(app.staticTexts["UI Test Server"].waitForExistence(timeout: 10))
        app.buttons["serverDetail.delete"].tap()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertFalse(app.element("serverRow.UI Test Server").waitForExistence(timeout: 3))

        let folder = app.element("folderRow.QA Folder")
        XCTAssertTrue(folder.waitForExistence(timeout: 10))
        folder.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertFalse(app.element("folderRow.QA Folder").waitForExistence(timeout: 3))
    }

    private func launchApp(seedData: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-reset-data",
            "--ui-testing-simulated-network",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]

        if seedData {
            app.launchArguments.append("--ui-testing-seed-data")
        } else {
            app.launchArguments.append("--ui-testing-disable-sample-data")
        }

        app.launch()
        return app
    }
}

private extension XCUIApplication {
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier]
    }

    func staticText(containing text: String) -> XCUIElement {
        staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
