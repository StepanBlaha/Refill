import SwiftUI
import AppKit

/// Wires feature modules into Monitor's hooks, URL scheme, and UI routes.
@MainActor
enum AppBootstrap {
    private static let urlHandler = URLEventHandler()

    static func start(_ monitor: Monitor) {
        AutomationBridge.monitor = monitor
        AppHooks.onEvent.append { e in
            if NotchController.shared.enabled { NotchController.shared.show(e) }
        }
        AppHooks.onRefresh.append { HistoryStore.shared.record($0) }
        AppHooks.onRefresh.append { [weak monitor] in SharedStatus.write($0, lastEvent: monitor?.events.last) }
        AppHooks.onEvent.append { [weak monitor] e in
            if let monitor { SharedStatus.write(monitor.accounts, lastEvent: e) }
        }

        NSAppleEventManager.shared().setEventHandler(
            urlHandler, andSelector: #selector(URLEventHandler.handle(_:reply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        let nc = NotificationCenter.default
        func on(_ name: String, _ f: @escaping @MainActor () -> Void) {
            nc.addObserver(forName: .init("refill.open.\(name)"), object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { f() }
            }
        }
        on("dashboard") { NSWorkspace.shared.open(URL(string: "http://127.0.0.1:\(Prefs.current.port)")!) }
        on("settings") { openSettings() }
        on("history") { HistoryWindow.show() }
        on("open") { HistoryWindow.show() }   // widget tap
        on("onboarding") { Onboarding.show(monitor: monitor) }

        DispatchQueue.main.async { Onboarding.showIfNeeded(monitor: monitor) }
    }

    static func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

final class URLEventHandler: NSObject {
    @objc func handle(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let s = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue, let url = URL(string: s) else { return }
        Task { @MainActor in URLRouter.handle(url) }
    }
}

@MainActor
enum HistoryWindow {
    private static var window: NSWindow?

    static func show() {
        NSApp.activate(ignoringOtherApps: true)
        if let w = window { w.makeKeyAndOrderFront(nil); return }
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 560),
                         styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        w.title = "Refill · History"
        w.contentView = NSHostingView(rootView: HistoryView())
        w.isReleasedWhenClosed = false
        w.center()
        w.makeKeyAndOrderFront(nil)
        window = w
    }
}
