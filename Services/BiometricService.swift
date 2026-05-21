import LocalAuthentication

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed(String)
    case userCancel
    case userFallback

    var errorDescription: String? {
        switch self {
        case .notAvailable: return String(localized: "Biometric authentication is not available", comment: "Biometric error")
        case .authenticationFailed(let reason): return String(localized: "Authentication failed: \(reason)", comment: "Biometric error with reason")
        case .userCancel: return String(localized: "Authentication cancelled by user", comment: "Biometric error")
        case .userFallback: return String(localized: "User chose to use password", comment: "Biometric error")
        }
    }
}

enum BiometricType {
    case none
    case faceID
    case touchID

    var displayName: String {
        switch self {
        case .none: return String(localized: "None", comment: "Biometric type none")
        case .faceID: return String(localized: "Face ID", comment: "Biometric type")
        case .touchID: return String(localized: "Touch ID", comment: "Biometric type")
        }
    }
}

@MainActor
final class BiometricService {
    static let shared = BiometricService()

    private init() {}

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .faceID
        case .none: return .none
        @unknown default: return .none
        }
    }

    var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    nonisolated func authenticate(reason: String = String(localized: "Unlock Nexus Shell", comment: "Biometric auth reason")) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Use Password", comment: "Biometric cancel button")

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else if let error = error as? LAError {
                    switch error.code {
                    case .userCancel:
                        continuation.resume(throwing: BiometricError.userCancel)
                    case .userFallback:
                        continuation.resume(throwing: BiometricError.userFallback)
                    case .biometryNotAvailable:
                        continuation.resume(throwing: BiometricError.notAvailable)
                    default:
                        continuation.resume(throwing: BiometricError.authenticationFailed(error.localizedDescription))
                    }
                } else {
                    continuation.resume(throwing: BiometricError.authenticationFailed(String(localized: "Unknown error", comment: "Fallback error")))
                }
            }
        }
    }
}
