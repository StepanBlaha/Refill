import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ink.ignoresSafeArea()
                if store.events.isEmpty {
                    VStack(spacing: 10) {
                        Drip(mood: .asleep, size: 70)
                        Text("Nothing yet. Quiet pipes.").font(Theme.rounded(15)).foregroundStyle(Theme.muted)
                    }
                } else {
                    List(store.events) { ev in
                        HStack(alignment: .top, spacing: 12) {
                            Circle().fill(Theme.color(ev.kind)).frame(width: 10, height: 10).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(ev.title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.text)
                                Text(ev.message).font(Theme.rounded(13)).foregroundStyle(Theme.muted)
                                Text("\(ev.accountName) · \(ev.windowLabel) · \(ev.detectedAt.formatted(.relative(presentation: .named)))")
                                    .font(Theme.mono(10)).foregroundStyle(Theme.muted.opacity(0.8))
                            }
                        }
                        .listRowBackground(Theme.panel)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable { await store.refresh() }
                }
            }
            .navigationTitle("Activity")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
