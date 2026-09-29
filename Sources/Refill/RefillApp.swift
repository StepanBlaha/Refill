import SwiftUI
import AppKit

@main
struct RefillApp: App {
    @StateObject private var monitor: Monitor

    init() {
        if let i = CommandLine.arguments.firstIndex(of: "--render") {
            PreviewRender.run(dir: CommandLine.arguments.dropFirst(i + 1).first ?? ".")
        }
        _monitor = StateObject(wrappedValue: Monitor())
        LoginItem.enableOnFirstRun()
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
                Drip(mood: monitor.mood, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Refill").font(Theme.rounded(22, .heavy)).foregroundStyle(Theme.text)
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
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.ink)
                    .frame(width: 20, height: 20).background(Theme.lime, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text(account.email ?? account.name).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                    if account.email != nil { Text(account.name).font(Theme.rounded(10)).foregroundStyle(Theme.muted) }
                }
                Spacer()
                if let plan = account.plan {
                    Text(plan.uppercased()).font(Theme.mono(9, .bold)).foregroundStyle(Theme.lime)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(Capsule().stroke(Theme.lime.opacity(0.5)))
                }
            }
            ForEach(account.windows) { TankRow(window: $0) }
            if let err = account.error {
                Label(err, systemImage: "exclamationmark.triangle.fill").font(Theme.rounded(11))
                    .foregroundStyle(Theme.coral).lineLimit(2)
            }
        }
        .padding(12)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
    }
}

/// Horizontal tank: liquid = what's LEFT.
struct TankRow: View {
    let window: UsageWindow
    var left: Double { max(0, min(100, 100 - window.utilization)) }
    var color: Color { Theme.level(used: window.utilization) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(window.label).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.text)
                Spacer()
                Text("\(Int(left.rounded()))%").font(Theme.mono(13, .bold)).foregroundStyle(color)
                Text("left").font(Theme.rounded(10)).foregroundStyle(Theme.muted)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line)
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(left > 0 ? 8 : 0, g.size.width * left / 100))
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: left)
            TimelineView(.periodic(from: .now, by: 30)) { ctx in
                Text(subtitle(ctx.date)).font(Theme.mono(10)).foregroundStyle(Theme.muted)
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
            Label(label, systemImage: symbol).font(Theme.rounded(12, .semibold))
                .foregroundStyle(hover ? Theme.ink : Theme.text)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background(hover ? Theme.lime : Theme.panel, in: Capsule())
                .overlay(Capsule().stroke(Theme.line))
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
                .foregroundStyle(hover ? Theme.lime : Theme.muted)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(spinning ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: spinning)
                .frame(width: 28, height: 28).background(Theme.panel, in: Circle())
        }
        .buttonStyle(.plain).onHover { hover = $0 }
    }
}
