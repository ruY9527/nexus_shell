import SwiftUI

struct StatusBadge: View {
    let status: SessionState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(status.displayText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .error: return .red
        case .disconnected: return .gray
        }
    }
}

struct ServerCardView: View {
    let server: Server
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: server.color))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "server.rack")
                                .foregroundStyle(.white)
                                .font(.title3)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(server.displayAddress)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }

                if !server.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(server.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if let lastConnected = server.lastConnected {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(String(localized: "Last connected: \(lastConnected.relativeFormatted)", comment: "Server card label"))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadge(status: .connected)
        StatusBadge(status: .connecting)
        StatusBadge(status: .reconnecting(attempt: 2, maxAttempts: 3))
        StatusBadge(status: .error("Timeout"))
        StatusBadge(status: .disconnected)

        ServerCardView(server: .preview) { }
    }
    .padding()
}
