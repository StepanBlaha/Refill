import SwiftUI
import AppKit

/// `Refill --render <dir>`: renders UI states to PNG for design review, then exits.
@MainActor
enum PreviewRender {
    static func sampleAccounts() -> [AccountSnapshot] {
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
        return sample
    }

    static func run(dir: String) {
        let m = Monitor(preview: sampleAccounts())
        save(MenuView().environmentObject(m), "\(dir)/menu.png")
        let row = HStack(spacing: 24) {
            ForEach([Voice.Mood.happy, .focused, .sweaty, .asleep, .party], id: \.self) { Drip(mood: $0, size: 64) }
        }.padding(24).background(Theme.ink)
        save(row, "\(dir)/moods.png")
        snap(SettingsView().environmentObject(m), NSSize(width: 640, height: 900), "\(dir)/settings.png")
        snap(HistoryView().environmentObject(m), NSSize(width: 680, height: 560), "\(dir)/history.png")
        snap(ScrollView { VStack(alignment: .leading, spacing: 20) { AccountsTab() }.padding(24) }.environmentObject(m),
             NSSize(width: 640, height: 700), "\(dir)/accounts.png")
        renderNotch(NotchLayout.resolve(.macBookPro14), housing: true, "\(dir)/notch-notched.png")
        renderNotch(NotchLayout.resolve(.studio), housing: false, "\(dir)/notch-plain.png")
        var obscured = DisplayGeometry.studio
        obscured.safeAreaTop = 32
        renderNotch(NotchLayout.resolve(obscured), housing: false, "\(dir)/notch-below.png")
        exit(0)
    }

    /// Open pill on a stand-in menu bar. The notched case strokes the camera housing so the gap is visible.
    private static func renderNotch(_ layout: NotchBannerLayout, housing: Bool, _ path: String) {
        let model = NotchModel()
        model.layout = layout
        model.expanded = true
        model.event = RefillEvent(kind: .reset, provider: "claude", accountId: "preview", accountName: "Preview",
                                   window: "five_hour", windowLabel: "5h", utilization: 92, resetsAt: nil,
                                   detectedAt: Date(), reason: "test", title: "Refilled!",
                                   message: "Your 5-hour Claude window just reset. Go build something.")
        let pad: CGFloat = 16
        let mark = housing ? layout.notchRect.map { layout.panelLocal($0) } : nil
        let clearance: CGFloat = {
            if case .below(let c) = layout.placement { return c }
            return 0
        }()
        let view = ZStack(alignment: .topLeading) {
            Color(white: 0.93)
            NotchView(model: model).offset(x: pad, y: pad)
            if let mark {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.45), lineWidth: 1)
                    Circle().fill(Color.black.opacity(0.55)).frame(width: 8, height: 8)
                }
                .frame(width: mark.width, height: mark.height)
                .offset(x: pad + mark.minX, y: pad + mark.minY)
            } else if clearance > 0 {
                Rectangle()
                    .stroke(Color.black.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: layout.panelFrame.width, height: clearance)
                    .offset(x: pad, y: pad)
            }
        }
        .frame(width: layout.panelFrame.width + pad * 2, height: layout.panelFrame.height + pad * 2)
        save(view, path)
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
