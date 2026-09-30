import AppKit
import Foundation

/// Handles refill:// URLs. Wire: `.onOpenURL { URLRouter.handle($0) }`.
@MainActor
enum URLRouter {
    static let uiRoutes: Set<String> = ["dashboard", "settings", "history", "onboarding"]

    static func name(_ route: String) -> Notification.Name { Notification.Name("refill.open.\(route)") }

    static func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "refill" else { return }
        // refill://refresh -> host "refresh"; tolerate refill:///refresh too.
        let route = (url.host.flatMap { $0.isEmpty ? nil : $0 }
                     ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func q(_ n: String) -> String? { items.first { $0.name == n }?.value }

        switch route {
        case "refresh":
            Task { await AutomationBridge.monitor?.refresh() }
        case "test":
            AutomationBridge.monitor?.sendTest()
        case "status":
            callback(success: q("x-success"), error: q("x-error"))
        case _ where uiRoutes.contains(route):
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: name(route), object: nil)
        default:
            NSSound.beep()
        }
    }

    /// x-callback-url: open x-success with remaining + json, or x-error if no data.
    private static func callback(success: String?, error: String?) {
        let remaining = StatusReader.remaining(provider: nil, window: "five_hour")
        let target: String?
        var extra: [(String, String)]
        if let remaining {
            target = success
            extra = [("remaining", String(remaining)), ("json", StatusReader.rawJSON())]
        } else {
            target = error ?? success
            extra = [("errorMessage", "No usage data. Is Refill running?")]
        }
        guard let target, var c = URLComponents(string: target) else { return }
        let existing = c.percentEncodedQueryItems ?? []
        let enc = { (s: String) in s.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? s }
        c.percentEncodedQueryItems = existing + extra.map { URLQueryItem(name: $0.0, value: enc($0.1)) }
        if let u = c.url { NSWorkspace.shared.open(u) }
    }
}
