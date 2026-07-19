import Foundation
import Combine
import LocalAuthentication

@MainActor
final class AppLockManager: ObservableObject {
    @Published private(set) var isUnlocked = false
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    func prepareForLaunch(
        appLockEnabled: Bool
    ) {
        if appLockEnabled {
            isUnlocked = false
        } else {
            isUnlocked = true
        }
    }

    func lock(
        appLockEnabled: Bool
    ) {
        guard appLockEnabled else {
            isUnlocked = true
            return
        }

        isUnlocked = false
        errorMessage = nil
    }

    func unlockWithoutAuthentication() {
        isUnlocked = true
        isAuthenticating = false
        errorMessage = nil
    }

    func authenticate() async {
        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        errorMessage = nil

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        let policy: LAPolicy =
            .deviceOwnerAuthentication

        var authenticationError: NSError?

        guard context.canEvaluatePolicy(
            policy,
            error: &authenticationError
        ) else {
            isAuthenticating = false

            errorMessage =
                authenticationError?
                    .localizedDescription
                ?? "Authentication is not available on this device."

            return
        }

        do {
            let success =
                try await context.evaluatePolicy(
                    policy,
                    localizedReason:
                        "Unlock your private scan history and ScamShield data."
                )

            isUnlocked = success
            isAuthenticating = false

            if !success {
                errorMessage =
                    "Authentication was not successful."
            }
        } catch {
            isUnlocked = false
            isAuthenticating = false

            handleAuthenticationError(error)
        }
    }

    func authenticationMethodName() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return "Device Passcode"
        }

        switch context.biometryType {
        case .faceID:
            return "Face ID"

        case .touchID:
            return "Touch ID"

        case .opticID:
            return "Optic ID"

        case .none:
            return "Device Passcode"

        @unknown default:
            return "Device Authentication"
        }
    }

    func authenticationSystemImage() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return "lock.fill"
        }

        switch context.biometryType {
        case .faceID:
            return "faceid"

        case .touchID:
            return "touchid"

        case .opticID:
            return "opticid"

        case .none:
            return "lock.fill"

        @unknown default:
            return "lock.fill"
        }
    }

    private func handleAuthenticationError(
        _ error: Error
    ) {
        guard let localError =
            error as? LAError
        else {
            errorMessage =
                error.localizedDescription

            return
        }

        switch localError.code {
        case .userCancel:
            errorMessage =
                "Authentication was canceled."

        case .systemCancel:
            errorMessage =
                "Authentication was canceled by the system."

        case .appCancel:
            errorMessage =
                "Authentication was canceled because the app became inactive."

        case .authenticationFailed:
            errorMessage =
                "Your identity could not be verified."

        case .biometryNotAvailable:
            errorMessage =
                "Biometric authentication is not available."

        case .biometryNotEnrolled:
            errorMessage =
                "No Face ID or Touch ID is enrolled. You can use the device passcode instead."

        case .biometryLockout:
            errorMessage =
                "Biometric authentication is locked. Use the device passcode to continue."

        case .passcodeNotSet:
            errorMessage =
                "A device passcode has not been configured."

        default:
            errorMessage =
                localError.localizedDescription
        }
    }
}
