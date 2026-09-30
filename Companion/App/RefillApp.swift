import SwiftUI

@main
struct RefillApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Group {
                if store.host.isEmpty { PairingView() } else { RootTabs() }
            }
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .tint(Theme.lime)
            .task { store.requestNotificationPermission() }
            .onChange(of: phase) { _, p in
                if p == .active { store.startPolling() } else { store.stopPolling() }
            }
            .onAppear { store.startPolling() }
        }
    }
}

struct RootTabs: View {
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Home", systemImage: "drop.fill") }
            ActivityView().tabItem { Label("Activity", systemImage: "bolt.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
