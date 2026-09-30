import Foundation

/// GitHub Copilot quota via the (unofficial) copilot_internal/user endpoint,
/// authenticated with the user's `gh` token or the Copilot editor oauth token.
enum CopilotProvider {
    static let id = "copilot:default"
    static let ghPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
    static let configDir = Paths.home.appendingPathComponent(".config/github-copilot")

    static var isInstalled: Bool {
        ProviderSupport.exists(configDir.path)
            || ProviderSupport.first(executable: ["gh"], in: ghPaths) != nil
    }

    static func fetch() async -> AccountSnapshot {
        guard let token = await readToken() else {
            return ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot",
                                          "No GitHub token (run `gh auth login`)")
        }
        do {
            var req = URLRequest(url: URL(string: "https://api.github.com/copilot_internal/user")!)
            for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }
            let (data, status) = try await ProviderSupport.send(req)
            guard status == 200 else {
                let hint = status == 401 || status == 403 ? " (token rejected or no Copilot seat)" : ""
                return ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot", "HTTP \(status)\(hint)")
            }
            guard var snap = parse(data) else {
                return ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot", "Unexpected response")
            }
            snap.email = await login(token: token)
            return snap
        } catch {
            return ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot", error.localizedDescription)
        }
    }

    static func headers(token: String) -> [String: String] {
        ["Authorization": "token \(token)", "Accept": "application/json",
         "Editor-Version": "vscode/1.96.2", "Editor-Plugin-Version": "copilot-chat/0.26.7",
         "User-Agent": "GitHubCopilotChat/0.26.7", "X-Github-Api-Version": "2025-04-01"]
    }

    static func login(token: String) async -> String? {
        var req = URLRequest(url: URL(string: "https://api.github.com/user")!)
        req.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("Refill", forHTTPHeaderField: "User-Agent")
        guard let (data, s) = try? await ProviderSupport.send(req, timeout: 5), s == 200 else { return nil }
        return ProviderSupport.json(data)?["login"] as? String
    }

    // MARK: token discovery (runtime only)

    static func readToken() async -> String? {
        if let gh = ProviderSupport.first(executable: ["gh"], in: ghPaths),
           let out = await ProviderSupport.run(gh, ["auth", "token"]) {
            let t = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        for name in ["apps.json", "hosts.json"] {
            let url = configDir.appendingPathComponent(name)
            if let d = try? Data(contentsOf: url), let t = token(fromConfig: d) { return t }
        }
        return nil
    }

    /// apps.json / hosts.json: { "github.com:<id>": { "oauth_token": "..." } }
    static func token(fromConfig data: Data) -> String? {
        guard let j = ProviderSupport.json(data) else { return nil }
        for (key, value) in j.sorted(by: { $0.key < $1.key }) where key.contains("github.com") {
            if let o = value as? [String: Any], let t = o["oauth_token"] as? String, !t.isEmpty { return t }
        }
        return nil
    }

    // MARK: parsing (pure)

    static func parse(_ data: Data, now: Date = Date()) -> AccountSnapshot? {
        guard let j = ProviderSupport.json(data) else { return nil }
        let quotas = j["quota_snapshots"] as? [String: Any] ?? [:]
        let reset = parseReset(j["quota_reset_date"] as? String ?? j["quota_reset_date_utc"] as? String)
        var windows: [UsageWindow] = []
        for (key, label) in [("premium_interactions", "Premium requests"), ("chat", "Chat"), ("completions", "Completions")] {
            guard let q = quotas[key] as? [String: Any] else { continue }
            if q["unlimited"] as? Bool == true { continue }
            var used: Double?
            if let rem = ProviderSupport.num(q["percent_remaining"]) { used = 100 - rem }
            else if let u = ProviderSupport.num(q["used_percent"]) { used = u }
            guard let u = used else { continue }
            windows.append(UsageWindow(key: key, label: label, utilization: ProviderSupport.clamp(u), resetsAt: reset))
        }
        var snap = AccountSnapshot(id: id, provider: "copilot", name: "Copilot", email: nil,
                                   plan: j["copilot_plan"] as? String, windows: windows, updatedAt: now)
        if windows.isEmpty { snap.error = "No metered Copilot quotas (unlimited plan?)" }
        return snap
    }

    static func parseReset(_ s: String?) -> Date? {
        guard let s else { return nil }
        if let d = parseISODate(s) { return d }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}
