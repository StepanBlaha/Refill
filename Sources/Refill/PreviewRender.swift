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
        exit(0)
    }

    static func save(_ v: some View, _ path: String) {
        let r = ImageRenderer(content: v.environment(\.colorScheme, .dark))
        r.scale = 2
        guard let img = r.nsImage, let tiff = img.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: URL(fileURLWithPath: path))
    }
}
