import SwiftUI
import AppKit

/// Wires feature modules into Monitor's hooks, URL scheme, and UI routes.
@MainActor
enum AppBootstrap {
    /// The launch callback is `@Sendable` but always runs on the main queue, same as this type.
    private nonisolated(unsafe) static let urlHandler = URLEventHandler()

    static func start(_ monitor: Monitor) {
        AutomationBridge.monitor = monitor
        ExtraProviders.register()
        UpdateChecker.shared.start()
        self.monitor = monitor
        AppHooks.onEvent.append { e in
            if NotchController.shared.enabled { NotchController.shared.show(e) }
        }
        AppHooks.onRefresh.append { HistoryStore.shared.record($0) }
        AppHooks.onRefresh.append { [weak monitor] in SharedStatus.write($0, lastEvent: monitor?.events.last) }
        AppHooks.onEvent.append { [weak monitor] e in
            if let monitor { SharedStatus.write(monitor.accounts, lastEvent: e) }
        }

        // SwiftUI installs its own GetURL handler during launch; register ours after it.
        NotificationCenter.default.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main) { _ in
            NSAppleEventManager.shared().setEventHandler(
                urlHandler, andSelector: #selector(URLEventHandler.handle(_:reply:)),
                forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        }

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

    static weak var monitor: Monitor?

    static func openSettings() {
        guard let monitor else { return }
        AppWindow.show(id: "settings", title: "Refill Settings", size: NSSize(width: 640, height: 580),
                       SettingsView().environmentObject(monitor))
    }
}

final class URLEventHandler: NSObject, @unchecked Sendable {
    @objc func handle(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let s = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue, let url = URL(string: s) else { return }
        Task { @MainActor in URLRouter.handle(url) }
    }
}

/// Brink-style app windows: dark, green tint, one instance per id.
@MainActor
enum AppWindow {
    private static var windows: [String: NSWindow] = [:]

    static func show(id: String, title: String, size: NSSize, _ view: some View) {
        NSApp.activate(ignoringOtherApps: true)
        if let w = windows[id] { w.makeKeyAndOrderFront(nil); return }
        let w = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                         backing: .buffered, defer: false)
        w.title = title
        w.titlebarAppearsTransparent = true
        w.appearance = NSAppearance(named: .darkAqua)
        w.backgroundColor = .black
        w.contentView = NSHostingView(rootView: view
            .tint(Theme.accent)
            .preferredColorScheme(.dark)
            .frame(minWidth: size.width, minHeight: size.height)
            .background(Color.black))
        w.isReleasedWhenClosed = false
        w.center()
        w.makeKeyAndOrderFront(nil)
        windows[id] = w
    }
}

@MainActor
enum HistoryWindow {
    static func show() {
        AppWindow.show(id: "history", title: "Refill History", size: NSSize(width: 680, height: 560),
                       HistoryView().padding(.top, 20))
    }
}
