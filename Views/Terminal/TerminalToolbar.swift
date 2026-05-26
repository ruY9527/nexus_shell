import SwiftUI

struct TerminalToolbar: View {
    @Bindable var viewModel: TerminalViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    SpecialKeyButton(key: .escape, action: { viewModel.sendSpecialKey(.escape) })
                    SpecialKeyButton(key: .tab, action: { viewModel.sendSpecialKey(.tab) })
                    SpecialKeyButton(key: .ctrlC, action: { viewModel.sendSpecialKey(.ctrlC) })
                    SpecialKeyButton(key: .ctrlD, action: { viewModel.sendSpecialKey(.ctrlD) })
                    SpecialKeyButton(key: .ctrlZ, action: { viewModel.sendSpecialKey(.ctrlZ) })
                    SpecialKeyButton(key: .arrowUp, action: { viewModel.sendSpecialKey(.arrowUp) })
                    SpecialKeyButton(key: .arrowDown, action: { viewModel.sendSpecialKey(.arrowDown) })
                    SpecialKeyButton(key: .arrowLeft, action: { viewModel.sendSpecialKey(.arrowLeft) })
                    SpecialKeyButton(key: .arrowRight, action: { viewModel.sendSpecialKey(.arrowRight) })
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(Color(.secondarySystemBackground))

            HStack(spacing: 8) {
                TextField("Enter command...", text: $viewModel.currentInput)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.sendCommand(viewModel.currentInput)
                    }

                Button {
                    HapticManager.impact(.medium)
                    viewModel.sendCommand(viewModel.currentInput)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.currentInput.isEmpty ? Color.secondary : Color.blue)
                }
                .disabled(viewModel.currentInput.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .onAppear {
            isInputFocused = true
        }
    }
}

struct SpecialKeyButton: View {
    let key: SpecialKey
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            Text(key.displayName)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        TerminalToolbar(viewModel: TerminalViewModel(server: .preview))
    }
}
