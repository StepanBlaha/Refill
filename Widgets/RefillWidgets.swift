import WidgetKit
import SwiftUI

// MARK: - Timeline

struct RefillEntry: TimelineEntry {
    let date: Date
    let accounts: [AccountSnapshot]
    let lastEvent: RefillEvent?
}

struct RefillProvider: TimelineProvider {
    func placeholder(in context: Context) -> RefillEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (RefillEntry) -> Void) {
        completion(context.isPreview ? Self.sample : entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RefillEntry>) -> Void) {
        let now = Date()
        let e = entry(at: now)
        // Refresh every 15 min, or right at the next reset if that comes sooner.
        let nextReset = e.accounts.flatMap(\.windows).compactMap(\.resetsAt).filter { $0 > now }.min()
        let quarter = now.addingTimeInterval(15 * 60)
        let next = min(quarter, nextReset.map { $0.addingTimeInterval(2) } ?? quarter)
        completion(Timeline(entries: [e], policy: .after(next)))
    }

    private func entry(at date: Date) -> RefillEntry {
        let p = SharedStatus.read()
        return RefillEntry(date: date, accounts: p?.accounts ?? [], lastEvent: p?.lastEvent)
    }

    static var sample: RefillEntry {
        let now = Date()
        func w(_ k: String, _ l: String, _ u: Double, _ h: Double) -> UsageWindow {
            UsageWindow(key: k, label: l, utilization: u, resetsAt: now.addingTimeInterval(h * 3600))
        }
        return RefillEntry(date: now, accounts: [
            AccountSnapshot(id: "a", provider: "claude", name: "Claude", email: nil, plan: "max",
                            windows: [w("five_hour", "5h session", 32, 1.33), w("seven_day", "Week", 72, 40)], updatedAt: now),
            AccountSnapshot(id: "b", provider: "claude", name: "Work", email: nil, plan: "pro",
                            windows: [w("five_hour", "5h session", 78, 0.6), w("seven_day", "Week", 41, 90)], updatedAt: now),
            AccountSnapshot(id: "c", provider: "codex", name: "Codex", email: nil, plan: "plus",
                            windows: [w("primary", "5h session", 21, 3.9)], updatedAt: now),
        ], lastEvent: nil)
    }
}

// MARK: - Helpers

extension AccountSnapshot {
    var fiveHour: UsageWindow? {
        windows.first { !$0.stale && ($0.key == "five_hour" || $0.key == "primary" || $0.label.contains("5h")) }
            ?? windows.first { $0.key == "five_hour" || $0.key == "primary" || $0.label.contains("5h") }
            ?? windows.first { !$0.stale }
            ?? windows.first
    }
}

extension RefillEntry {
    /// Account whose 5h window has the least left.
    var lowest: (account: AccountSnapshot, window: UsageWindow)? {
        accounts.compactMap { a in a.fiveHour.map { (a, $0) } }.max { $0.1.utilization < $1.1.utilization }
    }
    var mood: Voice.Mood {
        guard let l = lowest, !l.window.stale else { return accounts.isEmpty ? .asleep : .happy }
        let rem = l.window.percentLeft ?? 100
        return rem <= 0 ? .asleep : rem < 15 ? .sweaty : rem < 45 ? .focused : .happy
    }
}

func remaining(_ w: UsageWindow) -> Double { w.percentLeft ?? 0 }

func remainingLabel(_ w: UsageWindow) -> String {
    guard let left = w.percentLeft else { return "—" }
    return "\(Int(left.rounded()))%"
}

func refillsIn(_ w: UsageWindow, from now: Date) -> String {
    if w.stale { return lastSeenLabel(w.observedAt) }
    guard let r = w.resetsAt, r > now else { return "refilled" }
    return "refills in \(shortDuration(r.timeIntervalSince(now)))"
}

// MARK: - Views

struct TankBar: View {
    let window: UsageWindow
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule().fill(Theme.level(used: window.utilization))
                    .frame(width: window.stale ? 0 : max(height, g.size.width * remaining(window) / 100))
            }
        }.frame(height: height)
    }
}

struct EmptyState: View {
    var body: some View {
        VStack(spacing: 6) {
            Drip(mood: .asleep, size: 40)
            Text("Open Refill to connect").font(Theme.rounded(11, .medium)).foregroundStyle(Theme.muted)
        }
    }
}

struct SmallView: View {
    let e: RefillEntry
    var body: some View {
        if let l = e.lowest {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Drip(mood: e.mood, size: 44)
                    Spacer()
                }
                Spacer(minLength: 0)
                Text(remainingLabel(l.window))
                    .font(Theme.rounded(34, .heavy)).foregroundStyle(Theme.level(used: l.window.utilization))
                Text(refillsIn(l.window, from: e.date)).font(Theme.rounded(11, .medium)).foregroundStyle(Theme.muted)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else { EmptyState() }
    }
}

struct MediumView: View {
    let e: RefillEntry
    var body: some View {
        if e.accounts.isEmpty { EmptyState() } else {
            HStack(spacing: 14) {
                Drip(mood: e.mood, size: 56)
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(e.accounts.prefix(3)) { a in
                        if let w = a.fiveHour {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text(a.title).font(Theme.rounded(11, .semibold)).foregroundStyle(Theme.text)
                                        .lineLimit(1).frame(minWidth: 0, alignment: .leading)
                                    Spacer(minLength: 4)
                                    Text("\(remainingLabel(w)) · \(refillsIn(w, from: e.date))")
                                        .font(Theme.mono(9)).foregroundStyle(Theme.muted)
                                        .lineLimit(1).minimumScaleFactor(0.7).layoutPriority(1)
                                }
                                TankBar(window: w)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct LargeView: View {
    let e: RefillEntry
    var body: some View {
        if e.accounts.isEmpty { EmptyState() } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Drip(mood: e.mood, size: 40)
                    Text("Refill").font(Theme.rounded(18, .heavy)).foregroundStyle(Theme.lime)
                    Spacer()
                }
                ForEach(e.accounts.prefix(4)) { a in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(a.title).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                        ForEach(a.windows.prefix(2)) { w in
                            HStack(spacing: 8) {
                                Text(w.label).font(Theme.rounded(10)).foregroundStyle(Theme.muted).frame(width: 64, alignment: .leading)
                                TankBar(window: w, height: 7)
                                Text(remainingLabel(w)).font(Theme.mono(10)).foregroundStyle(Theme.text)
                                    .frame(width: 32, alignment: .trailing)
                            }
                            Text(refillsIn(w, from: e.date)).font(Theme.mono(9)).foregroundStyle(Theme.muted)
                                .padding(.leading, 72)
                        }
                    }
                }
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct RefillWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RefillEntry
    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(e: entry)
            case .systemMedium: MediumView(e: entry)
            default: LargeView(e: entry)
            }
        }
        .containerBackground(Theme.ink, for: .widget)
        .widgetURL(URL(string: "refill://open"))
    }
}

struct RefillWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RefillWidget", provider: RefillProvider()) { RefillWidgetView(entry: $0) }
            .configurationDisplayName("Refill")
            .description("Your AI usage tanks, with Drip.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct RefillWidgetBundle: WidgetBundle {
    var body: some Widget { RefillWidget() }
}
