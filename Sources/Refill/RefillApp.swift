import SwiftUI
import AppKit

@main
struct RefillApp: App {
    @StateObject private var monitor: Monitor

    init() {
        PreviewIcon.runIfRequested()
        PreviewOG.runIfRequested()
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
            SettingsView().environmentObject(monitor).tint(Theme.accent).preferredColorScheme(.dark)
        }
    }
}

struct MenuView: View {
    @EnvironmentObject var monitor: Monitor
    @ObservedObject private var updates = UpdateChecker.shared
    @State private var tagline = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(spacing: Space.m) {
                Drip(mood: monitor.mood, size: 30, level: monitor.lowestRemaining)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Refill").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                    Text(tagline).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                IconButton(symbol: "arrow.clockwise", spinning: monitor.refreshing) { Task { await monitor.refresh() } }
            }

            if let u = updates.available {
                HStack(alignment: .center, spacing: Space.s) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(Theme.accent)
                    Text("Refill \(u.version) is available")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Download") { updates.download() }.buttonStyle(DarkButton(prominent: true)).fixedSize()
                }
                .padding(Space.s + 2)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.panelRadius))
            }
            if monitor.accounts.isEmpty {
                Text("No tanks found. Log into Claude Code or Codex and I'll sniff them out.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.muted)
            }
            ForEach(monitor.accounts) { AccountCard(account: $0) }

            if let e = monitor.events.last {
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Theme.color(e.kind)).frame(width: 7, height: 7).padding(.top, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(e.title.softWrapped).font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(e.accountName.softWrapped).font(Theme.rounded(12)).foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(e.detectedAt, style: .relative).font(Theme.mono(10)).foregroundStyle(Theme.muted)
                        .fixedSize().padding(.top, 2)
                }
            }

            menuActions
        }
        .padding(Space.m)
        .frame(width: 340)
        .background(Theme.ink)
        .preferredColorScheme(.dark)
        .onAppear { tagline = Voice.tagline(monitor.mood) }
        .onChange(of: monitor.mood) { _, m in tagline = Voice.tagline(m) }
    }

    /// Pills stay on one row when they fit. On a narrow menu or at larger text they stack
    /// instead of drawing past the edge.
    private var menuActions: some View {
        let pills = ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.xs) { dashboardPill; historyPill }
            VStack(alignment: .leading, spacing: Space.xs) { dashboardPill; historyPill }
        }
        let icons = HStack(spacing: Space.xs) {
            IconButton(symbol: "bolt.fill") { monitor.sendTest() }.help("Send a test signal")
            IconButton(symbol: "gearshape.fill") { AppBootstrap.openSettings() }
            IconButton(symbol: "power") { NSApp.terminate(nil) }
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.xs) { pills; Spacer(minLength: Space.xs); icons }
            VStack(alignment: .leading, spacing: Space.xs) {
                pills
                HStack { Spacer(minLength: 0); icons }
            }
        }
    }

    private var dashboardPill: some View {
        Pill(symbol: "gauge.with.dots.needle.67percent", label: "Dashboard") {
            NSWorkspace.shared.open(URL(string: "http://127.0.0.1:\(Prefs.current.port)")!)
        }
    }

    private var historyPill: some View {
        Pill(symbol: "chart.xyaxis.line", label: "History") { HistoryWindow.show() }
    }
}

struct AccountCard: View {
    let account: AccountSnapshot
    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(spacing: Space.s) {
                Image(systemName: account.provider == "codex" ? "chevron.left.forwardslash.chevron.right" : "sparkle")
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.muted).frame(width: 14)
                Text(account.title.softWrapped).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: Space.s)
                Menu { AccountMenuItems(account: account) } label: {
                    Image(systemName: "ellipsis").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.muted)
                        .frame(width: 20, height: 18).contentShape(Rectangle())
                }
                .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
                .opacity(hover ? 1 : 0)
                .onHover { ClickFeedback.cursor(hovering: $0, enabled: true) }
                if let plan = account.plan {
                    Text(plan.capitalized).font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.muted)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
                }
            }
            if let err = account.error {
                Text(err.softWrapped).font(.system(size: 11)).foregroundStyle(Theme.amber)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(account.windows) { TankRow(window: $0, accountId: account.id) }
        }
        .padding(Space.m)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.panelRadius, style: .continuous))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .contextMenu { AccountMenuItems(account: account) }
    }
}

/// One window = two lines: label · countdown · % left, then a thin bar.
struct TankRow: View {
    let window: UsageWindow
    var accountId = ""
    var left: Double { max(0, min(100, 100 - window.utilization)) }
    var color: Color { Theme.level(used: window.utilization) }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                Text(window.label.softWrapped).font(.system(size: 12)).foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                TimelineView(.periodic(from: .now, by: 30)) { ctx in
                    Text(subtitle(ctx.date)).font(.system(size: 11)).monospacedDigit().foregroundStyle(Theme.muted)
                        .fixedSize()
                }
                Text("\(Int(left.rounded()))%").font(.system(size: 12, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(window.utilization >= 70 ? color : Theme.text)
                    .frame(minWidth: 34, alignment: .trailing)
                    .fixedSize()
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(color).frame(width: max(left > 0 ? 3 : 0, g.size.width * left / 100))
                }
            }
            .frame(height: 3)
            .animation(.spring(response: 0.4, dampingFraction: 1), value: left)
            BurnBadge(accountId: accountId, windowKey: window.key)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func subtitle(_ now: Date) -> String {
        guard let r = window.resetsAt else { return "not started" }
        return r <= now ? "ready" : "in \(shortDuration(r.timeIntervalSince(now)))"
    }
}

struct Pill: View {
    let symbol: String, label: String, action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol).font(Theme.rounded(12, .medium)).lineLimit(1).fixedSize()
                .foregroundStyle(Theme.text)
                .padding(.horizontal, Space.s).padding(.vertical, 5)
                .background(hover ? Theme.hover : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.radius + 2))
        }
        .buttonStyle(PointerButtonStyle()).onHover { hover = $0 }
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
        .buttonStyle(PointerButtonStyle()).onHover { hover = $0 }
    }
}
