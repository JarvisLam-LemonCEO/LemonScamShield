import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var historyItems: [ScanHistoryItem]

    @AppStorage(
        AppPreferenceKeys.automaticallySaveHistory
    )
    private var automaticallySaveHistory = true
    
    @AppStorage(
        AppPreferenceKeys.appLockEnabled
    )
    private var appLockEnabled = false
    
    @AppStorage(AppPreferenceKeys.appearance)
    private var appearanceRawValue =
        AppAppearance.system.rawValue

    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingResetConfirmation = false
    @State private var errorMessage = ""
    @State private var isShowingError = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                securitySection
                historySection
                privacySection
                aboutSection
                resetSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all scan history?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Delete All History",
                    role: .destructive
                ) {
                    deleteAllHistory()
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {}
            } message: {
                Text(
                    "Every saved scan will be permanently deleted. This action cannot be undone."
                )
            }
            .confirmationDialog(
                "Reset app settings?",
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Reset Settings",
                    role: .destructive
                ) {
                    resetSettings()
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {}
            } message: {
                Text(
                    "This resets preferences but does not delete scan history."
                )
            }
            .alert(
                "Action Could Not Be Completed",
                isPresented: $isShowingError
            ) {
                Button(
                    "OK",
                    role: .cancel
                ) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Picker(
                "Appearance",
                selection: $appearanceRawValue
            ) {
                ForEach(AppAppearance.allCases) {
                    appearance in

                    Label(
                        appearance.title,
                        systemImage:
                            appearance.systemImage
                    )
                    .tag(appearance.rawValue)
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text(
                "System follows your iPhone's current appearance setting."
            )
        }
    }
    
    private var securitySection: some View {
        Section {
            Toggle(
                isOn: $appLockEnabled
            ) {
                Label(
                    "Require Authentication",
                    systemImage:
                        "lock.shield.fill"
                )
            }
        } header: {
            Text("Security")
        } footer: {
            Text(
                appLockEnabled
                ? "ScamShield will lock after the app moves to the background. Unlock using Face ID, Touch ID, or the device passcode."
                : "Turn this on to protect ScamShield with Face ID, Touch ID, or the device passcode."
            )
        }
    }
    
    private var historySection: some View {
        Section {
            Toggle(
                isOn: $automaticallySaveHistory
            ) {
                Label(
                    "Save Scans Automatically",
                    systemImage:
                        "clock.arrow.circlepath"
                )
            }

            HStack {
                Label(
                    "Saved Scans",
                    systemImage: "tray.full"
                )

                Spacer()

                Text("\(historyItems.count)")
                    .foregroundStyle(.secondary)
            }

            Button(
                role: .destructive
            ) {
                isShowingDeleteConfirmation = true
            } label: {
                Label(
                    "Delete All History",
                    systemImage: "trash"
                )
            }
            .disabled(historyItems.isEmpty)
        } header: {
            Text("History")
        } footer: {
            Text(historyFooterText)
        }
    }

    private var privacySection: some View {
        Section {
            SettingsInformationRow(
                title: "Message Analysis",
                detail:
                    "Message rules run directly on your device.",
                systemImage:
                    "text.bubble.fill"
            )

            SettingsInformationRow(
                title: "Image Recognition",
                detail:
                    "Screenshot and document text recognition run on your device.",
                systemImage:
                    "text.viewfinder"
            )

            SettingsInformationRow(
                title: "Saved Images",
                detail:
                    "Screenshots and document photographs are not saved in scan history.",
                systemImage:
                    "photo.badge.checkmark"
            )

            SettingsInformationRow(
                title: "Network Access",
                detail:
                    "This version does not upload analyzed content to a server.",
                systemImage:
                    "network.slash"
            )
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "Saved scan text remains in the app's local SwiftData storage until you delete it or remove the app."
            )
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label(
                    "App",
                    systemImage:
                        "shield.checkered"
                )

                Spacer()

                Text("ScamShield")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(
                    "Version",
                    systemImage: "number"
                )

                Spacer()

                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(
                    "Build",
                    systemImage: "hammer"
                )

                Spacer()

                Text(buildNumber)
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                AboutScamShieldView()
            } label: {
                Label(
                    "About ScamShield",
                    systemImage: "info.circle"
                )
            }
        } header: {
            Text("About")
        }
    }

    private var resetSection: some View {
        Section {
            Button(
                role: .destructive
            ) {
                isShowingResetConfirmation = true
            } label: {
                Label(
                    "Reset Settings",
                    systemImage:
                        "arrow.counterclockwise"
                )
            }
        } footer: {
            Text(
                "Resetting settings turns automatic history saving back on and disables the app lock. It does not delete saved scans."
            )
        }
    }

    private var historyFooterText: String {
        if automaticallySaveHistory {
            return """
            New results are automatically added to History. You can still delete individual scans later.
            """
        }

        return """
        New results will not be added to History. Existing saved scans remain available.
        """
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleVersion"
        ) as? String ?? "1"
    }

    private func deleteAllHistory() {
        for item in historyItems {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            showError(error)
        }
    }

    private func resetSettings() {
        automaticallySaveHistory = true
        appLockEnabled = false
    }

    private func showError(
        _ error: Error
    ) {
        errorMessage =
            error.localizedDescription

        isShowingError = true
    }
}

private struct SettingsInformationRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(title)
                    .font(.body)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct AboutScamShieldView: View {
    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                headerSection
                purposeSection
                limitationsSection
                privacySection
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Image(
                systemName: "shield.checkered"
            )
            .font(.system(size: 54))
            .foregroundStyle(.blue)

            Text("ScamShield")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Check before you trust")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var purposeSection: some View {
        informationCard(
            title: "Purpose",
            systemImage: "target"
        ) {
            Text(
                "ScamShield helps people identify common warning signs in suspicious messages, website addresses, phone numbers, screenshots, and printed documents."
            )
        }
    }

    private var limitationsSection: some View {
        informationCard(
            title: "Important limitations",
            systemImage:
                "exclamationmark.triangle.fill"
        ) {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text(
                    "ScamShield cannot guarantee that an item is safe or fraudulent."
                )

                Text(
                    "The current phone check examines number formatting only and does not use a live reputation database."
                )

                Text(
                    "Website checks examine the address structure but do not open or inspect the website."
                )
            }
        }
    }

    private var privacySection: some View {
        informationCard(
            title: "Privacy",
            systemImage: "lock.fill"
        ) {
            Text(
                "This version performs analysis and text recognition locally on the device. Analyzed content is not uploaded to a ScamShield server."
            )
        }
    }

    private func informationCard<
        Content: View
    >(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                title,
                systemImage: systemImage
            )
            .font(.headline)

            content()
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            Color.secondary.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(
            for: ScanHistoryItem.self,
            inMemory: true
        )
}
