import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var repairing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Mac") {
                    LabeledContent("Host", value: store.host)
                    if let t = store.lastFetch {
                        LabeledContent("Last update", value: t.formatted(date: .omitted, time: .standard))
                    }
                    Button("Change Mac") { repairing = true }
                }
                Section("Push when away") {
                    TextField("ntfy topic (optional note)", text: $store.ntfyTopic)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("For push when away, subscribe to your ntfy topic in the ntfy app.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                Section {
                    Text("This app polls your Mac every 15s while open and shows a local notification when a reset shows up.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.ink)
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $repairing) {
                PairingView(onDone: { repairing = false }).environmentObject(store)
            }
        }
    }
}
