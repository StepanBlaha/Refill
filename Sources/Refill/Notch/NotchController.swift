import SwiftUI
import AppKit

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

extension DisplayGeometry {
    init(_ screen: NSScreen, main: NSScreen?) {
        self.init(frame: screen.frame,
                  visibleFrame: screen.visibleFrame,
                  safeAreaTop: max(0, screen.safeAreaInsets.top),
                  auxiliaryTopLeft: DisplayGeometry.usableArea(screen.auxiliaryTopLeftArea),
                  auxiliaryTopRight: DisplayGeometry.usableArea(screen.auxiliaryTopRightArea),
                  isMain: screen == main)
    }
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
    private var screenWatch: NSObjectProtocol?

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
        let first = model.layout.panelFrame
        let p = NotchPanel(contentRect: first,
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
        watchScreens()
        return p
    }

    private func watchScreens() {
        guard screenWatch == nil else { return }
        screenWatch = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.syncFrame() }
        }
    }

    /// Places the pill from the live safe-area insets. A display connect, resolution change,
    /// or move onto another panel runs this again.
    private func syncFrame() {
        guard let p = panel else { return }
        let main = NSScreen.main
        let screens = NSScreen.screens.map { DisplayGeometry($0, main: main) }
        guard let screen = NotchLayout.select(screens, cursor: NSEvent.mouseLocation) else { return }
        let layout = NotchLayout.resolve(screen)
        if model.layout != layout { model.layout = layout }
        let next = layout.panelFrame
        if p.frame.integral != next.integral { p.setFrame(next, display: true) }
    }
}
