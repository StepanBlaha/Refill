import SwiftUI
import AppKit

@main
struct RefillApp: App {
    @StateObject private var monitor = Monitor()

    var body: some Scene {
        MenuBarExtra {
            MenuView().environmentObject(monitor)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                if let h = monitor.headline { Text("\(h)%") }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(monitor)
        }
    }
}

struct MenuView: View {
    @EnvironmentObject var monitor: Monitor
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Refill").font(.headline)
                Spacer()
                if monitor.refreshing { ProgressView().controlSize(.small) }
                Button { Task { await monitor.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless).help("Refresh now")
            }
            if monitor.accounts.isEmpty {
                Text("No accounts detected yet.").foregroundStyle(.secondary)
            }
            ForEach(monitor.accounts) { AccountCard(account: $0) }

            if let e = monitor.events.last {
                Text("Last reset: \(e.accountName) · \(e.windowLabel) · \(e.detectedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Button("Test signal") { monitor.sendTest() }
                Button("Dashboard") {
                    NSWorkspace.shared.open(URL(string: "http://127.0.0.1:\(Prefs.current.port)")!)
                }
                Button("Hooks") { NSWorkspace.shared.open(Paths.config) }
                Spacer()
                Button { NSApp.activate(ignoringOtherApps: true); openSettings() } label: { Image(systemName: "gearshape") }
                Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
            }
            .buttonStyle(.borderless).font(.callout)
        }
        .padding(14)
        .frame(width: 340)
    }
}

struct AccountCard: View {
    let account: AccountSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: account.provider == "codex" ? "chevron.left.forwardslash.chevron.right" : "sparkle")
                    .foregroundStyle(.secondary)
                Text(account.email ?? account.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Spacer()
                if let plan = account.plan { Text(plan.capitalized).font(.caption2).foregroundStyle(.secondary) }
            }
            if account.email != nil {
                Text(account.name).font(.caption2).foregroundStyle(.tertiary)
            }
            ForEach(account.windows) { WindowRow(window: $0) }
            if let err = account.error {
                Text(err).font(.caption).foregroundStyle(.orange).lineLimit(2)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct WindowRow: View {
    let window: UsageWindow

    var color: Color { window.utilization >= 90 ? .red : window.utilization >= 70 ? .orange : .green }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(window.label).font(.caption)
                Spacer()
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    Text(resetText(now: ctx.date)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            ProgressView(value: min(window.utilization, 100), total: 100).tint(color)
        }
    }

    func resetText(now: Date) -> String {
        let pct = "\(Int(window.utilization.rounded()))%"
        guard let r = window.resetsAt else { return pct }
        return r <= now ? "\(pct) · resetting…" : "\(pct) · resets in \(shortDuration(r.timeIntervalSince(now)))"
    }
}
