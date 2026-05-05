//
//  CommandEngineTests.swift
//  nexus_shellTests
//
//  Created by baoyang on 2026/05/06.
//

import XCTest
@testable import nexus_shell

final class CommandEngineTests: XCTestCase {

    private var engine: DefaultCommandEngine!

    override func setUp() {
        super.setUp()
        engine = DefaultCommandEngine(host: "test-server.local", username: "testuser", port: 22)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Basic Properties Tests

    func testEngineProperties() {
        XCTAssertEqual(engine.host, "test-server.local")
        XCTAssertEqual(engine.username, "testuser")
        XCTAssertEqual(engine.port, 22)
        XCTAssertEqual(engine.homeDirectory, "/home/testuser")
        XCTAssertEqual(engine.currentDirectory, "/home/testuser")
    }

    func testInitialDirectoryIsHome() {
        XCTAssertEqual(engine.currentDirectory, engine.homeDirectory)
    }

    // MARK: - CD Command Tests

    func testCdToHome() {
        engine.setCurrentDirectory("/var/log")
        engine.execute("cd ~")
        XCTAssertEqual(engine.currentDirectory, "/home/testuser")
    }

    func testCdToParentDirectory() {
        engine.setCurrentDirectory("/home/testuser/projects")
        engine.execute("cd ..")
        XCTAssertEqual(engine.currentDirectory, "/home/testuser")
    }

    func testCdToRoot() {
        engine.execute("cd /")
        XCTAssertEqual(engine.currentDirectory, "/")
    }

    func testCdToAbsolutePath() {
        engine.execute("cd /var/log")
        XCTAssertEqual(engine.currentDirectory, "/var/log")
    }

    func testCdToRelativePath() {
        engine.setCurrentDirectory("/home/testuser")
        engine.execute("cd projects")
        XCTAssertEqual(engine.currentDirectory, "/home/testuser/projects")
    }

    // MARK: - Basic Commands Tests

    func testPwdCommand() {
        let output = engine.execute("pwd")
        XCTAssertTrue(output.contains("/home/testuser"))
    }

    func testWhoamiCommand() {
        let output = engine.execute("whoami")
        XCTAssertTrue(output.contains("testuser"))
    }

    func testUnameCommand() {
        let output = engine.execute("uname")
        XCTAssertFalse(output.isEmpty)
    }

    func testUnameACommand() {
        let output = engine.execute("uname -a")
        XCTAssertFalse(output.isEmpty)
    }

    func testHostnameCommand() {
        let output = engine.execute("hostname")
        XCTAssertTrue(output.contains("test-server"))
    }

    func testDateCommand() {
        let output = engine.execute("date")
        XCTAssertFalse(output.isEmpty)
    }

    // MARK: - Clear Command Tests

    func testClearCommand() {
        let output = engine.execute("clear")
        XCTAssertEqual(output, "\u{001B}[2J\u{001B}[H")
    }

    // MARK: - Empty Command Tests

    func testEmptyCommand() {
        let output = engine.execute("")
        XCTAssertEqual(output, "")
    }

    func testWhitespaceCommand() {
        let output = engine.execute("   ")
        XCTAssertEqual(output, "")
    }

    // MARK: - Unknown Command Tests

    func testUnknownCommand() {
        let output = engine.execute("unknown-command-xyz")
        XCTAssertTrue(output.contains("command not found"))
    }

    // MARK: - Echo Command Tests

    func testEchoCommand() {
        let output = engine.execute("echo Hello World")
        XCTAssertTrue(output.contains("Hello World"))
    }

    func testEchoEmpty() {
        let output = engine.execute("echo")
        XCTAssertEqual(output, "\n")
    }

    // MARK: - Help Command Tests

    func testHelpCommand() {
        let output = engine.execute("help")
        XCTAssertTrue(output.contains("Available commands"))
        XCTAssertTrue(output.contains("ls"))
        XCTAssertTrue(output.contains("pwd"))
    }

    // MARK: - History Command Tests

    func testHistoryCommand() {
        let output = engine.execute("history")
        XCTAssertFalse(output.isEmpty)
    }

    // MARK: - Exit Command Tests

    func testExitCommand() {
        let output = engine.execute("exit")
        XCTAssertEqual(output, "logout\n")
    }

    func testLogoutCommand() {
        let output = engine.execute("logout")
        XCTAssertEqual(output, "logout\n")
    }

    // MARK: - Which Command Tests

    func testWhichLs() {
        let output = engine.execute("which ls")
        XCTAssertTrue(output.contains("/usr/bin/ls"))
    }

    func testWhichGit() {
        let output = engine.execute("which git")
        XCTAssertTrue(output.contains("/usr/bin/git"))
    }

    func testWhichUnknown() {
        let output = engine.execute("which unknown-cmd-xyz")
        XCTAssertEqual(output, "")
    }

    // MARK: - System Info Commands Tests

    func testLscpuCommand() {
        let output = engine.execute("lscpu")
        XCTAssertTrue(output.contains("Architecture"))
        XCTAssertTrue(output.contains("CPU"))
    }

    func testLsblkCommand() {
        let output = engine.execute("lsblk")
        XCTAssertTrue(output.contains("NAME"))
    }

    func testLsmemCommand() {
        let output = engine.execute("lsmem")
        XCTAssertTrue(output.contains("MEMORY"))
    }

    // MARK: - Cat Command Tests

    func testCatEtcOsRelease() {
        let output = engine.execute("cat /etc/os-release")
        XCTAssertTrue(output.contains("Ubuntu") || output.contains("PRETTY_NAME"))
    }

    func testCatEtcHostname() {
        let output = engine.execute("cat /etc/hostname")
        XCTAssertTrue(output.contains("test-server"))
    }

    func testCatEtcPasswd() {
        let output = engine.execute("cat /etc/passwd")
        XCTAssertTrue(output.contains("testuser"))
    }

    func testCatUnknownFile() {
        let output = engine.execute("cat /nonexistent/file.txt")
        XCTAssertTrue(output.contains("No such file"))
    }

    // MARK: - Find Command Tests

    func testFindCommand() {
        let output = engine.execute("find /home")
        XCTAssertFalse(output.isEmpty)
        XCTAssertTrue(output.contains("/home"))
    }

    // MARK: - Man Command Tests

    func testManCommand() {
        let output = engine.execute("man ls")
        XCTAssertTrue(output.contains("No manual entry"))
    }

    // MARK: - Touch/Mkdir/Rm Commands Tests

    func testTouchCommand() {
        let output = engine.execute("touch newfile.txt")
        XCTAssertEqual(output, "")
    }

    func testMkdirCommand() {
        let output = engine.execute("mkdir newdir")
        XCTAssertEqual(output, "")
    }

    func testRmCommand() {
        let output = engine.execute("rm file.txt")
        XCTAssertEqual(output, "")
    }

    func testCpCommand() {
        let output = engine.execute("cp source.txt dest.txt")
        XCTAssertEqual(output, "")
    }

    func testMvCommand() {
        let output = engine.execute("mv old.txt new.txt")
        XCTAssertEqual(output, "")
    }

    func testChmodCommand() {
        let output = engine.execute("chmod 755 script.sh")
        XCTAssertEqual(output, "")
    }

    // MARK: - Free Command Tests

    func testFreeCommand() {
        let output = engine.execute("free")
        XCTAssertTrue(output.contains("Mem:"))
    }

    func testFreeMCommand() {
        let output = engine.execute("free -m")
        XCTAssertTrue(output.contains("Mem:"))
    }

    func testFreeHCommand() {
        let output = engine.execute("free -h")
        XCTAssertTrue(output.contains("Mem:"))
    }

    // MARK: - DF Command Tests

    func testDfCommand() {
        let output = engine.execute("df")
        XCTAssertTrue(output.contains("Filesystem"))
    }

    func testDfHCommand() {
        let output = engine.execute("df -h")
        XCTAssertTrue(output.contains("Filesystem"))
    }

    // MARK: - PS Command Tests

    func testPsCommand() {
        let output = engine.execute("ps")
        XCTAssertFalse(output.isEmpty)
    }

    func testPsAuxCommand() {
        let output = engine.execute("ps aux")
        XCTAssertTrue(output.contains("USER"))
        XCTAssertTrue(output.contains("PID"))
    }

    // MARK: - Top Command Tests

    func testTopCommand() {
        let output = engine.execute("top")
        XCTAssertTrue(output.contains("Cpu(s)") || output.contains("PID"))
    }

    // MARK: - Network Commands Tests

    func testIfconfigCommand() {
        let output = engine.execute("ifconfig")
        XCTAssertTrue(output.contains("eth0") || output.contains("ens"))
    }

    func testIpAddrCommand() {
        let output = engine.execute("ip addr")
        XCTAssertTrue(output.contains("inet"))
    }

    func testPingCommand() {
        let output = engine.execute("ping -c 1 8.8.8.8")
        XCTAssertTrue(output.contains("PING") || output.contains("packets"))
    }

    // MARK: - Piped Commands Tests

    func testPsAuxHeadCommand() {
        let output = engine.execute("ps aux | head -10")
        XCTAssertFalse(output.isEmpty)
    }

    func testTopHeadCommand() {
        let output = engine.execute("top -bn1 | head -5")
        XCTAssertFalse(output.isEmpty)
    }

    // MARK: - Service Commands Tests

    func testSystemctlStatusCommand() {
        let output = engine.execute("systemctl status nginx")
        XCTAssertTrue(output.contains("nginx") || output.contains("Unit"))
    }

    func testSystemctlListUnitsCommand() {
        let output = engine.execute("systemctl list-units --type=service --state=running")
        XCTAssertTrue(output.contains("UNIT") || output.contains("service"))
    }

    // MARK: - Docker Commands Tests

    func testDockerPsCommand() {
        let output = engine.execute("docker ps")
        XCTAssertTrue(output.contains("CONTAINER ID"))
    }

    func testDockerImagesCommand() {
        let output = engine.execute("docker images")
        XCTAssertTrue(output.contains("REPOSITORY"))
    }

    func testDockerStatsCommand() {
        let output = engine.execute("docker stats --no-stream")
        XCTAssertTrue(output.contains("CONTAINER ID") || output.contains("CPU %"))
    }

    // MARK: - Package Commands Tests

    func testAptUpdateCommand() {
        let output = engine.execute("apt update")
        XCTAssertTrue(output.contains("Hit") || output.contains("Get"))
    }

    func testDpkgLCommand() {
        let output = engine.execute("dpkg -l")
        XCTAssertTrue(output.contains("Desired=Unknown"))
    }

    // MARK: - User Commands Tests

    func testIdCommand() {
        let output = engine.execute("id")
        XCTAssertTrue(output.contains("uid="))
        XCTAssertTrue(output.contains("gid="))
    }

    func testGroupsCommand() {
        let output = engine.execute("groups")
        XCTAssertTrue(output.contains("testuser"))
    }

    func testLastlogCommand() {
        let output = engine.execute("lastlog")
        XCTAssertTrue(output.contains("Username") || output.contains("testuser"))
    }

    // MARK: - Log Commands Tests

    func testJournalctlCommand() {
        let output = engine.execute("journalctl -n 10")
        XCTAssertFalse(output.isEmpty)
    }

    func testDmesgCommand() {
        let output = engine.execute("dmesg")
        XCTAssertFalse(output.isEmpty)
    }

    // MARK: - Utility Commands Tests

    func testBase64EncodeCommand() {
        let output = engine.execute("base64 -d <<< aGVsbG8gd29ybGQ=")
        XCTAssertTrue(output.contains("hello world"))
    }

    func testMD5SumCommand() {
        let output = engine.execute("echo -n hello | md5sum")
        XCTAssertTrue(output.contains("5d41402abc4b2a76b9719d911017c592"))
    }

    func testSha256SumCommand() {
        let output = engine.execute("echo -n hello | sha256sum")
        XCTAssertTrue(output.contains("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"))
    }
}

// MARK: - CommandSimulator Integration Tests

final class CommandSimulatorIntegrationTests: XCTestCase {

    private var simulator: CommandSimulator!

    override func setUp() {
        super.setUp()
        simulator = CommandSimulator(host: "integration-test.local", username: "tester", port: 22)
    }

    override func tearDown() {
        simulator = nil
        super.tearDown()
    }

    func testSimulatorInitialState() {
        XCTAssertEqual(simulator.getCurrentDirectory(), "/home/tester")
    }

    func testSimulatorPwd() {
        let output = simulator.simulate("pwd")
        XCTAssertTrue(output.contains("/home/tester"))
    }

    func testSimulatorCdAndPwd() {
        _ = simulator.simulate("cd /var/log")
        let output = simulator.simulate("pwd")
        XCTAssertTrue(output.contains("/var/log"))
    }

    func testSimulatorLs() {
        let output = simulator.simulate("ls")
        XCTAssertTrue(output.contains("Documents") || output.contains("README"))
    }

    func testSimulatorWhoami() {
        let output = simulator.simulate("whoami")
        XCTAssertTrue(output.contains("tester"))
    }

    func testSimulatorCatOsRelease() {
        let output = simulator.simulate("cat /etc/os-release")
        XCTAssertFalse(output.isEmpty)
    }

    func testSimulatorTop() {
        let output = simulator.simulate("top -bn1 | head -5")
        XCTAssertFalse(output.isEmpty)
    }

    func testSimulatorDockerPs() {
        let output = simulator.simulate("docker ps")
        XCTAssertTrue(output.contains("CONTAINER ID"))
    }

    func testSimulatorAptUpdate() {
        let output = simulator.simulate("apt update")
        XCTAssertFalse(output.isEmpty)
    }

    func testSimulatorMultipleCommands() {
        _ = simulator.simulate("cd /tmp")
        XCTAssertEqual(simulator.getCurrentDirectory(), "/tmp")

        _ = simulator.simulate("cd /home")
        XCTAssertEqual(simulator.getCurrentDirectory(), "/home")

        _ = simulator.simulate("cd ~")
        XCTAssertEqual(simulator.getCurrentDirectory(), "/home/tester")
    }
}
