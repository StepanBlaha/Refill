import Foundation
import AppKit
import UserNotifications

/// Checks GitHub Releases daily; no keys, no framework. Newer tag → banner + one notification.
@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    static let repo = "StepanBlaha/Refill"

    struct Release: Equatable { let version: String; let page: URL; let dmg: URL? }

    @Published private(set) var available: Release?
    @Published private(set) var lastCheck: Date?
    @Published private(set) var status = ""
    private var timer: Timer?

    var current: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0" }

    func start() {
        Task { await check(silent: true) }
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.check(silent: true) }
        }
    }

    func check(silent: Bool = false) async {
        status = "Checking…"
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        defer { lastCheck = Date() }
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = j["tag_name"] as? String, let page = (j["html_url"] as? String).flatMap(URL.init) else {
            status = "No releases found"; return
        }
        let version = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let dmg = (j["assets"] as? [[String: Any]])?
            .first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
            .flatMap { ($0["browser_download_url"] as? String).flatMap(URL.init) }
        guard Self.isNewer(version, than: current) else {
            available = nil; status = "You're up to date (\(current))"; return
        }
        let r = Release(version: version, page: page, dmg: dmg)
        status = "Version \(version) is available"
        if available != r { available = r; notifyOnce(r) }
    }

    func download() {
        guard let r = available else { return }
        NSWorkspace.shared.open(r.dmg ?? r.page)
    }

    private func notifyOnce(_ r: Release) {
        let key = "notifiedUpdate"
        guard UserDefaults.standard.string(forKey: key) != r.version, Bundle.main.bundleIdentifier != nil else { return }
        UserDefaults.standard.set(r.version, forKey: key)
        let c = UNMutableNotificationContent()
        c.title = "Refill \(r.version) is out"
        c.body = "Open the menu to download it."
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "update-\(r.version)", content: c, trigger: nil))
    }

    /// Numeric dot-version compare: 0.10.0 > 0.9.2.
    nonisolated static func isNewer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
