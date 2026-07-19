import SwiftUI

struct AppLockView: View {
    @ObservedObject var lockManager:
        AppLockManager

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            lockIcon

            titleSection

            unlockButton

            if let errorMessage =
                lockManager.errorMessage {
                errorSection(errorMessage)
            }

            Spacer()

            privacyNotice
        }
        .padding(28)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            Color(uiColor:
                .systemGroupedBackground)
        )
        .task {
            guard !lockManager.isUnlocked,
                  !lockManager.isAuthenticating
            else {
                return
            }

            await lockManager.authenticate()
        }
    }

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(
                    Color.blue.opacity(0.12)
                )
                .frame(
                    width: 110,
                    height: 110
                )

            Image(
                systemName:
                    lockManager
                        .authenticationSystemImage()
            )
            .font(.system(size: 52))
            .foregroundStyle(.blue)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("ScamShield Locked")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(
                "Authenticate to access your scans, history, and safety tools."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    private var unlockButton: some View {
        Button {
            Task {
                await lockManager.authenticate()
            }
        } label: {
            HStack {
                if lockManager.isAuthenticating {
                    ProgressView()
                        .tint(.white)

                    Text("Authenticating...")
                } else {
                    Image(
                        systemName:
                            lockManager
                                .authenticationSystemImage()
                    )

                    Text(
                        "Unlock with \(lockManager.authenticationMethodName())"
                    )
                }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .background(
                lockManager.isAuthenticating
                ? Color.gray
                : Color.blue
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(
            lockManager.isAuthenticating
        )
    }

    private func errorSection(
        _ message: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)

            Spacer()
        }
        .padding()
        .background(
            Color.orange.opacity(0.1)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var privacyNotice: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)

            Text(
                "Authentication is handled by iOS. ScamShield does not receive or store your biometric information or device passcode."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    AppLockView(
        lockManager: AppLockManager()
    )
}
