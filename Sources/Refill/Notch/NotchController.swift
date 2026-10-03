import SwiftUI
import AppKit
import Combine

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
    private var heightWatch: AnyCancellable?

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
        model.expanded = false
        model.event = e
        model.contentHeight = NotchMetrics.minHeight
        syncFrame()
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
        let p = NotchPanel(contentRect: NSRect(x: 0, y: 0, width: NotchMetrics.width, height: NotchMetrics.minHeight + 8),
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
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        panel = p
        if heightWatch == nil {
            heightWatch = model.$contentHeight
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.syncFrame() }
        }
        return p
    }

    /// Sizes the panel to the measured banner so a long Drip line isn't clipped by the window.
    private func syncFrame() {
        guard let p = panel else { return }
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        if screen.safeAreaInsets.top > 0,
           let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            model.notchWidth = max(100, screen.frame.width - l.width - r.width)
            model.notchHeight = screen.safeAreaInsets.top
        } else {
            model.notchWidth = 140
            model.notchHeight = 6
        }
        let w = min(NotchMetrics.width, max(280, screen.frame.width - 16))
        if abs(model.bannerWidth - w) > 0.5 { model.bannerWidth = w }
        let h = max(model.contentHeight, NotchMetrics.minHeight) + 8
        let f = screen.frame
        let next = NSRect(x: (f.midX - w / 2).rounded(), y: f.maxY - h, width: w, height: h)
        if p.frame.integral != next.integral { p.setFrame(next, display: true) }
    }
}
