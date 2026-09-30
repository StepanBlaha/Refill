import SwiftUI
import AppKit

@main
struct RefillApp: App {
    @StateObject private var monitor: Monitor

    init() {
        PreviewIcon.runIfRequested()
        if let i = CommandLine.arguments.firstIndex(of: "--render") {
            PreviewRender.run(dir: CommandLine.arguments.dropFirst(i + 1).first ?? ".")
        }
        let m = Monitor()
        _monitor = StateObject(wrappedValue: m)
        LoginItem.enableOnFirstRun()
        AppBootstrap.start(m)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView().environmentObject(monitor)
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: TankIcon.image(remaining: monitor.lowestRemaining))
                if let r = monitor.lowestRemaining { Text("\(Int(r.rounded()))%") }
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
    @State private var tagline = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Drip(mood: monitor.mood, size: 34, level: monitor.lowestRemaining)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Refill").font(.system(size: 19, weight: .semibold)).foregroundStyle(Theme.text)
                    Text(tagline).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.muted).lineLimit(1)
                }
                Spacer()
                IconButton(symbol: "arrow.clockwise", spinning: monitor.refreshing) { Task { await monitor.refresh() } }
            }

            if monitor.accounts.isEmpty {
                Text("No tanks found. Log into Claude Code or Codex and I'll sniff them out.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.muted)
            }
            ForEach(monitor.accounts) { AccountCard(account: $0) }

            if let e = monitor.events.last {
                HStack(spacing: 8) {
                    Circle().fill(Theme.color(e.kind)).frame(width: 7, height: 7)
                    Text(e.title).font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.text)
                    Text("· \(e.accountName)").font(Theme.rounded(12)).foregroundStyle(Theme.muted).lineLimit(1)
                    Spacer()
                    Text(e.detectedAt, style: .relative).font(Theme.mono(10)).foregroundStyle(Theme.muted)
                }
            }

            HStack(spacing: 8) {
                Pill(symbol: "gauge.with.dots.needle.67percent", label: "Dashboard") {
                    NSWorkspace.shared.open(URL(string: "http://127.0.0.1:\(Prefs.current.port)")!)
                }
                Pill(symbol: "chart.xyaxis.line", label: "History") { HistoryWindow.show() }
                Pill(symbol: "bolt.fill", label: "Test") { monitor.sendTest() }
                Spacer()
                IconButton(symbol: "gearshape.fill") { NSApp.activate(ignoringOtherApps: true); openSettings() }
                IconButton(symbol: "power") { NSApp.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 360)
        .background(Theme.ink)
        .preferredColorScheme(.dark)
        .onAppear { tagline = Voice.tagline(monitor.mood) }
        .onChange(of: monitor.mood) { _, m in tagline = Voice.tagline(m) }
    }
}

struct AccountCard: View {
    let account: AccountSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: account.provider == "codex" ? "chevron.left.forwardslash.chevron.right" : "sparkle")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.muted)
                    .frame(width: 22, height: 22).background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius + 1))
                VStack(alignment: .leading, spacing: 0) {
                    Text(account.email ?? account.name).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                    if account.email != nil { Text(account.name).font(Theme.rounded(10)).foregroundStyle(Theme.muted) }
                }
                Spacer()
                if let plan = account.plan {
                    Text(plan.capitalized).font(Theme.rounded(11, .medium)).foregroundStyle(Theme.muted)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
            ForEach(account.windows) { TankRow(window: $0, accountId: account.id) }
            if let err = account.error {
                Label(err, systemImage: "exclamationmark.triangle.fill").font(Theme.rounded(11))
                    .foregroundStyle(Theme.coral).lineLimit(2)
            }
        }
        .padding(12)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.panelRadius, style: .continuous))
    }
}

/// Horizontal tank: liquid = what's LEFT.
struct TankRow: View {
    let window: UsageWindow
    var accountId = ""
    var left: Double { max(0, min(100, 100 - window.utilization)) }
    var color: Color { Theme.level(used: window.utilization) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(window.label).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.text)
                Spacer()
                Text("\(Int(left.rounded()))%").font(Theme.mono(13, .semibold)).foregroundStyle(window.utilization >= 70 ? color : Theme.text)
                Text("left").font(Theme.rounded(10)).foregroundStyle(Theme.muted)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: max(left > 0 ? 4 : 0, g.size.width * left / 100))
                }
            }
            .frame(height: 4)
            .animation(Theme.unfold, value: left)
            HStack {
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    Text(subtitle(ctx.date)).font(Theme.mono(10)).foregroundStyle(Theme.muted)
                }
                Spacer()
                BurnBadge(accountId: accountId, windowKey: window.key)
            }
        }
    }

    func subtitle(_ now: Date) -> String {
        guard let r = window.resetsAt else { return "\(Int(window.utilization.rounded()))% used" }
        return r <= now ? "refilling…" : "refills in \(shortDuration(r.timeIntervalSince(now)))"
    }
}

struct Pill: View {
    let symbol: String, label: String, action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol).font(Theme.rounded(12, .medium)).lineLimit(1).fixedSize()
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(hover ? Theme.hover : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.radius + 2))
        }
        .buttonStyle(.plain).onHover { hover = $0 }
    }
}

struct IconButton: View {
    let symbol: String
    var spinning = false
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 12, weight: .bold))
                .foregroundStyle(hover ? Theme.text : Theme.muted)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(spinning ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: spinning)
                .frame(width: 26, height: 26).background(hover ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: Theme.radius + 2))
        }
        .buttonStyle(.plain).onHover { hover = $0 }
    }
}
