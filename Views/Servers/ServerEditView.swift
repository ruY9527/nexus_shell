import SwiftUI

struct ServerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ServerEditViewModel
    @State private var showPassword: Bool = false
    @State private var newTag: String = ""

    let onSave: (Server) -> Void

    init(server: Server? = nil, onSave: @escaping (Server) -> Void) {
        _viewModel = State(initialValue: ServerEditViewModel(server: server))
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Server Information") {
                TextField("Name", text: $viewModel.name)
                TextField("Host", text: $viewModel.host)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                HStack {
                    Text("Port")
                    Spacer()
                    TextField("22", text: $viewModel.port)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("Authentication") {
                Picker("Method", selection: $viewModel.authMethod) {
                    ForEach(Server.AuthMethod.allCases, id: \.self) { method in
                        Text(method == .password ? "Password" : "Private Key").tag(method)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.authMethod == .password {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $viewModel.password)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                        }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Private Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $viewModel.privateKey)
                            .frame(minHeight: 100)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            Section("Connection") {
                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Section("Tags") {
                ForEach(viewModel.tags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button {
                            viewModel.removeTag(tag)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    TextField("Add tag", text: $newTag)
                    Button("Add") {
                        viewModel.addTag(newTag)
                        newTag = ""
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Notes") {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 60)
            }

            Section("Color") {
                ColorPicker("Server Color", selection: Binding(
                    get: { Color(hex: viewModel.color) },
                    set: { viewModel.color = $0.hexString }
                ))
            }

            Section {
                Button {
                    Task { await viewModel.testConnection() }
                } label: {
                    HStack {
                        if viewModel.isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Test Connection")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.isValid || viewModel.isTesting)

                if let result = viewModel.testResult {
                    switch result {
                    case .success(let message):
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    case .failure(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Server" : "Add Server")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let server = viewModel.buildServer()
                    do {
                        try viewModel.saveCredentials(for: server.id)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                    onSave(server)
                    dismiss()
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ServerEditView { _ in }
    }
}
