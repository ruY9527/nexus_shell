import Foundation

@Observable
final class ServerEditViewModel {
    var name: String = ""
    var host: String = ""
    var port: String = "22"
    var username: String = ""
    var authMethod: Server.AuthMethod = .password
    var password: String = ""
    var privateKey: String = ""
    var selectedGroupId: UUID?
    var tags: [String] = []
    var notes: String = ""
    var color: String = "#007AFF"

    var isEditing: Bool = false
    var isTesting: Bool = false
    var testResult: TestResult?
    var errorMessage: String?

    enum TestResult {
        case success(String)
        case failure(String)
    }

    private var serverId: UUID?
    private var createdAt: Date?

    init(server: Server? = nil) {
        if let server {
            isEditing = true
            serverId = server.id
            name = server.name
            host = server.host
            port = String(server.port)
            username = server.username
            authMethod = server.authMethod
            selectedGroupId = server.groupId
            tags = server.tags
            notes = server.notes
            color = server.color
            createdAt = server.createdAt
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !host.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(port) ?? 0) > 0 && (Int(port) ?? 0) <= 65535
    }

    var portNumber: Int {
        Int(port) ?? 22
    }

    func buildServer() -> Server {
        Server(
            id: serverId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            host: host.trimmingCharacters(in: .whitespaces),
            port: portNumber,
            username: username.trimmingCharacters(in: .whitespaces),
            authMethod: authMethod,
            groupId: selectedGroupId,
            tags: tags,
            createdAt: createdAt ?? Date(),
            notes: notes,
            color: color
        )
    }

    func saveCredentials(for serverId: UUID) throws {
        let keychain = KeychainService.shared

        if authMethod == .password {
            try keychain.savePassword(password, for: serverId)
        } else if !privateKey.isEmpty {
            try keychain.savePrivateKey(Data(privateKey.utf8), for: serverId)
        }
    }

    func testConnection() async {
        isTesting = true
        testResult = nil

        let server = buildServer()
        let sshService = SSHService()

        do {
            if authMethod == .password {
                try await sshService.connect(to: server, password: password)
            } else {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_key")
                try privateKey.write(to: tempURL, atomically: true, encoding: .utf8)
                try await sshService.connect(to: server, privateKeyPath: tempURL.path)
                try? FileManager.default.removeItem(at: tempURL)
            }

            let output = try await sshService.execute("echo 'Connection successful'")
            sshService.disconnect()
            testResult = .success(String(localized: "Connected! Response: \(output.trimmingCharacters(in: .whitespacesAndNewlines))", comment: "Test connection success"))
        } catch {
            testResult = .failure(error.localizedDescription)
        }

        isTesting = false
    }

    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
        }
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
