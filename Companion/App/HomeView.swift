import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ink.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Drip(mood: store.mood, size: 88)
                            Text(Voice.tagline(store.mood)).font(Theme.rounded(17, .semibold))
                                .foregroundStyle(Theme.text).multilineTextAlignment(.center)
                            if let r = store.lowestRemaining {
                                Text("\(Int(r.rounded()))% left in the tightest 5h window")
                                    .font(Theme.mono(12)).foregroundStyle(Theme.muted)
                            }
                        }.padding(.top, 8)

                        if let e = store.error {
                            Text(e).font(Theme.rounded(13)).foregroundStyle(Theme.coral)
                                .padding(12).frame(maxWidth: .infinity)
                                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                        }
                        ForEach(store.status?.accounts ?? []) { AccountCard(account: $0) }
                        if store.status == nil && store.error == nil {
                            ProgressView().tint(Theme.lime).padding(.top, 40)
                        }
                    }.padding(16)
                }
                .refreshable { await store.refresh() }
            }
            .navigationTitle("Refill")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct AccountCard: View {
    let account: WireAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.text)
                    Text([account.provider.capitalized, account.plan].compactMap { $0 }.joined(separator: " · "))
                        .font(Theme.mono(11)).foregroundStyle(Theme.muted)
                }
                Spacer()
            }
            if let err = account.error {
                Text(err).font(Theme.rounded(12)).foregroundStyle(Theme.amber)
            }
            ForEach(account.windows) { WindowRow(window: $0) }
        }
        .padding(16)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
    }
}

struct WindowRow: View {
    let window: WireWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(window.label).font(Theme.rounded(14, .medium)).foregroundStyle(Theme.text)
                Spacer()
                Text(window.remaining.map { "\(Int($0.rounded()))% left" } ?? "—")
                    .font(Theme.mono(13, .semibold))
                    .foregroundStyle(window.stale ? Theme.muted : Theme.level(used: window.utilization))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line)
                    Capsule().fill(Theme.level(used: window.utilization))
                        .frame(width: window.stale ? 0 : max(6, g.size.width * (window.remaining ?? 0) / 100))
                }
            }.frame(height: 10)
            if window.stale {
                Text(lastSeenLabel(window.observedAt)).font(Theme.mono(11)).foregroundStyle(Theme.muted)
            } else if let r = window.resetsAt {
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    let t = r.timeIntervalSince(ctx.date)
                    Text(t > 0 ? "Refills in \(shortDuration(t))" : "Refill due")
                        .font(Theme.mono(11)).foregroundStyle(Theme.muted)
                }
            }
        }
    }
}
