import SwiftUI
import AppKit

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

@MainActor
final class NotchController {
    static let shared = NotchController()

    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "notchEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notchEnabled") }
    }

    private let model = NotchModel()
    private var panel: NotchPanel?
    private var queue: [RefillEvent] = []
    private var running = false

    func show(_ e: RefillEvent) {
        guard enabled else { return }
        queue.append(e)
        if !running { running = true; Task { await self.drain() } }
    }

    func preview() {
        show(RefillEvent(kind: .reset, provider: "claude", accountId: "preview", accountName: "Preview",
                         window: "five_hour", windowLabel: "5h", utilization: 92, resetsAt: nil,
                         detectedAt: Date(), reason: "test", title: "Refilled!",
                         message: "Your 5-hour Claude window just reset. Go build something."))
    }

    private func drain() async {
        while !queue.isEmpty {
            let e = queue.removeFirst()
            await present(e)
        }
        running = false
    }

    private func present(_ e: RefillEvent) async {
        let p = makePanel()
        position(p)
        model.expanded = false
        model.event = e
        p.ignoresMouseEvents = false
        p.orderFrontRegardless()
        try? await Task.sleep(nanoseconds: 60_000_000)
        model.expanded = true
        try? await Task.sleep(nanoseconds: 600_000_000)
        var elapsed = 0.0
        while elapsed < 6.0 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if !model.hovering { elapsed += 0.1 }
        }
        model.expanded = false
        try? await Task.sleep(nanoseconds: 600_000_000)
        p.ignoresMouseEvents = true
        p.orderOut(nil)
        model.hovering = false
        model.event = nil
    }

    private func makePanel() -> NotchPanel {
        if let panel { return panel }
        let p = NotchPanel(contentRect: NSRect(x: 0, y: 0, width: NotchMetrics.width, height: NotchMetrics.panelHeight),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.hidesOnDeactivate = false
        p.isMovable = false
        p.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingView(rootView: NotchView(model: model))
        host.sizingOptions = []
        p.contentView = host
        panel = p
        return p
    }

    private func position(_ p: NSPanel) {
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
        if screen.safeAreaInsets.top > 0,
           let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            model.notchWidth = max(100, screen.frame.width - l.width - r.width)
            model.notchHeight = screen.safeAreaInsets.top
        } else {
            model.notchWidth = 140
            model.notchHeight = 6
        }
        let f = screen.frame
        p.setFrame(NSRect(x: f.midX - NotchMetrics.width / 2, y: f.maxY - NotchMetrics.panelHeight,
                          width: NotchMetrics.width, height: NotchMetrics.panelHeight), display: false)
    }
}
