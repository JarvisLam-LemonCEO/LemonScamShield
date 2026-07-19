import SwiftUI
import SwiftData

@main
struct ScamShieldApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: ScanHistoryItem.self
        )
    }
}
