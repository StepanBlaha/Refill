import SwiftUI
import AppKit

/// `Refill --render <dir>`: renders UI states to PNG for design review, then exits.
@MainActor
enum PreviewRender {
    static func run(dir: String) {
        let now = Date()
        func w(_ k: String, _ l: String, _ u: Double, _ h: Double) -> UsageWindow {
            UsageWindow(key: k, label: l, utilization: u, resetsAt: now.addingTimeInterval(h * 3600))
        }
        let sample = [
            AccountSnapshot(id: "claude:a", provider: "claude", name: "Claude", email: "stepan@example.cz", plan: "max",
                            windows: [w("five_hour", "5h session", 12, 1.4), w("seven_day", "Week", 72, 40)], updatedAt: now),
            AccountSnapshot(id: "claude:b", provider: "claude", name: "Claude · .claude-work", email: "work@example.cz", plan: "pro",
                            windows: [w("five_hour", "5h session", 93, 0.6), w("seven_day", "Week", 41, 90)], updatedAt: now),
            AccountSnapshot(id: "codex", provider: "codex", name: "Codex", email: nil, plan: "plus",
                            windows: [w("primary", "5h session", 21, 3.9)], updatedAt: now),
        ]
        let m = Monitor(preview: sample)
        save(MenuView().environmentObject(m), "\(dir)/menu.png")
        let row = HStack(spacing: 24) {
            ForEach([Voice.Mood.happy, .focused, .sweaty, .asleep, .party], id: \.self) { Drip(mood: $0, size: 64) }
        }.padding(24).background(Theme.ink)
        save(row, "\(dir)/moods.png")
        snap(SettingsView().environmentObject(m), NSSize(width: 640, height: 900), "\(dir)/settings.png")
        snap(HistoryView().environmentObject(m), NSSize(width: 680, height: 560), "\(dir)/history.png")
        snap(ScrollView { VStack(alignment: .leading, spacing: 20) { AccountsTab() }.padding(24) }.environmentObject(m),
             NSSize(width: 640, height: 700), "\(dir)/accounts.png")
        exit(0)
    }

    /// AppKit snapshot so real controls (toggles, menus) draw, unlike ImageRenderer.
    static func snap(_ v: some View, _ size: NSSize, _ path: String) {
        let host = NSHostingView(rootView: v.tint(Theme.accent).preferredColorScheme(.dark).background(Color.black))
        host.appearance = NSAppearance(named: .darkAqua)
        let win = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        win.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }

    static func save(_ v: some View, _ path: String) {
        let r = ImageRenderer(content: v.environment(\.colorScheme, .dark))
        r.scale = 2
        guard let img = r.nsImage, let tiff = img.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }
}
