import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem {
                    Label(
                        "Check",
                        systemImage:
                            "shield.checkered"
                    )
                }

            HistoryView()
                .tabItem {
                    Label(
                        "History",
                        systemImage:
                            "clock.arrow.circlepath"
                    )
                }

            SafetyCenterView()
                .tabItem {
                    Label(
                        "Safety",
                        systemImage:
                            "cross.case.fill"
                    )
                }

            SettingsView()
                .tabItem {
                    Label(
                        "Settings",
                        systemImage: "gearshape.fill"
                    )
                }
        }
    }
}

#Preview {
    ContentView()
}
