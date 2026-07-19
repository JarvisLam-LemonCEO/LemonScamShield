import SwiftUI

struct RootView: View {
    @AppStorage(
        AppPreferenceKeys.appLockEnabled
    )
    private var appLockEnabled = false

    @AppStorage(
        AppPreferenceKeys.appearance
    )
    private var appearanceRawValue =
        AppAppearance.system.rawValue

    @Environment(\.scenePhase)
    private var scenePhase

    @StateObject private var lockManager =
        AppLockManager()

    @State private var hasPreparedForLaunch = false

    private var selectedColorScheme:
        ColorScheme? {

        AppAppearance(
            rawValue: appearanceRawValue
        )?
        .colorScheme
    }

    var body: some View {
        Group {
            if !hasPreparedForLaunch {
                ProgressView()
            } else if appLockEnabled
                        && !lockManager.isUnlocked {
                AppLockView(
                    lockManager: lockManager
                )
            } else {
                ContentView()
            }
        }
        .preferredColorScheme(
            selectedColorScheme
        )
        .task {
            guard !hasPreparedForLaunch else {
                return
            }

            lockManager.prepareForLaunch(
                appLockEnabled:
                    appLockEnabled
            )

            hasPreparedForLaunch = true
        }
        .onChange(
            of: scenePhase
        ) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .onChange(
            of: appLockEnabled
        ) { _, enabled in
            handleLockSettingChange(enabled)
        }
    }

    private func handleScenePhase(
        _ phase: ScenePhase
    ) {
        switch phase {
        case .active:
            break

        case .inactive:
            break

        case .background:
            lockManager.lock(
                appLockEnabled:
                    appLockEnabled
            )

        @unknown default:
            break
        }
    }

    private func handleLockSettingChange(
        _ enabled: Bool
    ) {
        if enabled {
            lockManager.lock(
                appLockEnabled: true
            )
        } else {
            lockManager
                .unlockWithoutAuthentication()
        }
    }
}

#Preview {
    RootView()
}
