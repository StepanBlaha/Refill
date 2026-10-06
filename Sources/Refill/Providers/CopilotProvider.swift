import Foundation

/// One GitHub CLI login that can carry a Copilot seat.
struct GhLogin: Equatable {
    var login: String
    var active: Bool
}

struct CopilotAssignment: Equatable {
    var id: String
    var login: String
}

/// GitHub Copilot quota via the (unofficial) copilot_internal/user endpoint,
/// authenticated with the user's `gh` token or the Copilot editor oauth token.
enum CopilotProvider {
    static let id = "copilot:default"
    /// GitHub login that owns `copilot:default`, so switching the active `gh` user
    /// does not rename the account Refill already tracked.
    static let anchorKey = "copilotAnchorLogin"
    static let ghPaths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
    static let configDir = Paths.home.appendingPathComponent(".config/github-copilot")

    static var isInstalled: Bool {
        ProviderSupport.exists(configDir.path)
            || ProviderSupport.first(executable: ["gh"], in: ghPaths) != nil
    }

    /// The anchored login keeps `copilot:default`. Every other login is `copilot:<login>`.
    /// A login literally named `default` is `copilot:login:default` so it cannot collide.
    static func assign(logins: [GhLogin], anchor: String?) -> (accounts: [CopilotAssignment], anchor: String?) {
        var seen = Set<String>()
        let names = logins.map(\.login).filter { seen.insert($0).inserted }
        guard let first = names.first else { return ([], anchor) }
        let active = logins.first { $0.active && names.contains($0.login) }?.login
        let chosen = anchor.flatMap { names.contains($0) ? $0 : nil } ?? active ?? first
        let rows = names.map { login in
            CopilotAssignment(id: accountId(login: login, isAnchor: login == chosen), login: login)
        }
        let ordered = rows.sorted { lhs, rhs in
            if lhs.id == id { return true }
            if rhs.id == id { return false }
            return lhs.login < rhs.login
        }
        return (ordered, chosen)
    }

    static func accountId(login: String, isAnchor: Bool) -> String {
        if isAnchor { return id }
        if login == "default" { return "copilot:login:default" }
        return "copilot:" + login
    }

    /// `gh auth status` text. Only github.com hosts count; Copilot's quota API is there.
    static func parseAuthStatus(_ text: String) -> [GhLogin] {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        var out: [GhLogin] = []
        var i = 0
        while i < lines.count {
            if let parsed = parseLoginLine(lines[i]), parsed.host.caseInsensitiveCompare("github.com") == .orderedSame {
                var active = false
                var j = i + 1
                while j < lines.count, parseLoginLine(lines[j]) == nil {
                    if lines[j].contains("Active account: true") { active = true }
                    j += 1
                }
                out.append(GhLogin(login: parsed.login, active: active))
                i = j
                continue
            }
            i += 1
        }
        return out
    }

    static func parseLoginLine(_ line: String) -> (host: String, login: String)? {
        let marker = "Logged in to "
        guard let r = line.range(of: marker) else { return nil }
        let parts = line[r.upperBound...].split(separator: " ")
        guard parts.count >= 3, parts[1] == "account" else { return nil }
        let login = String(parts[2])
        guard !login.isEmpty else { return nil }
        return (String(parts[0]), login)
    }

    static func fetchAll() async -> [AccountSnapshot] {
        let hidden = Set(UserDefaults.standard.stringArray(forKey: "hiddenAccounts") ?? [])
        if let gh = ProviderSupport.first(executable: ["gh"], in: ghPaths),
           let text = await statusText(gh) {
            let parsed = parseAuthStatus(text)
            if !parsed.isEmpty {
                let stored = UserDefaults.standard.string(forKey: anchorKey)
                let assigned = assign(logins: parsed, anchor: stored)
                if let next = assigned.anchor { UserDefaults.standard.set(next, forKey: anchorKey) }
                let rows = assigned.accounts.filter { !hidden.contains($0.id) }
                return await withTaskGroup(of: (Int, AccountSnapshot).self) { group in
                    for (i, row) in rows.enumerated() {
                        group.addTask { (i, await CopilotProvider.fetchLogin(gh, row)) }
                    }
                    var out: [(Int, AccountSnapshot)] = []
                    for await r in group { out.append(r) }
                    return out.sorted { $0.0 < $1.0 }.map(\.1)
                }
            }
        }
        if hidden.contains(id) { return [] }
        return [await fetchEditor()]
    }

    static func fetch() async -> AccountSnapshot {
        await fetchAll().first ?? ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot",
                                                         "No GitHub token (run `gh auth login`)")
    }

    private static func fetchLogin(_ gh: String, _ row: CopilotAssignment) async -> AccountSnapshot {
        let name = row.id == id ? "Copilot" : "Copilot · \(row.login)"
        guard let token = await token(gh, user: row.login) else {
            return ProviderSupport.failed(id: row.id, provider: "copilot", name: name,
                                          "No GitHub token for \(row.login) (run `gh auth login`)")
        }
        return await fetch(token: token, id: row.id, name: name, login: row.login)
    }

    /// Single account from `gh auth token` or the editor's apps.json / hosts.json.
    private static func fetchEditor() async -> AccountSnapshot {
        guard let token = await readToken() else {
            return ProviderSupport.failed(id: id, provider: "copilot", name: "Copilot",
                                          "No GitHub token (run `gh auth login`)")
        }
        return await fetch(token: token, id: id, name: "Copilot", login: nil)
    }

    private static func fetch(token: String, id: String, name: String, login: String?) async -> AccountSnapshot {
        do {
            var req = URLRequest(url: URL(string: "https://api.github.com/copilot_internal/user")!)
            for (k, v) in headers(token: token) { req.setValue(v, forHTTPHeaderField: k) }
            let (data, status) = try await ProviderSupport.send(req)
            guard status == 200 else {
                let hint = status == 401 || status == 403 ? " (token rejected or no Copilot seat)" : ""
                return ProviderSupport.failed(id: id, provider: "copilot", name: name, "HTTP \(status)\(hint)")
            }
            guard var snap = parse(data, id: id, name: name) else {
                return ProviderSupport.failed(id: id, provider: "copilot", name: name, "Unexpected response")
            }
            snap.email = login ?? await self.login(token: token)
            return snap
        } catch {
            return ProviderSupport.failed(id: id, provider: "copilot", name: name, error.localizedDescription)
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

    /// stdout even when `gh auth status` exits non-zero (one bad account does that).
    static func statusText(_ gh: String) async -> String? {
        await ProviderSupport.run(gh, ["auth", "status"], allowNonZero: true)
    }

    static func token(_ gh: String, user: String) async -> String? {
        guard let out = await ProviderSupport.run(gh, ["auth", "token", "--hostname", "github.com", "--user", user]) else { return nil }
        let t = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

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

    static func parse(_ data: Data, now: Date = Date(), id: String = CopilotProvider.id, name: String = "Copilot") -> AccountSnapshot? {
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
        var snap = AccountSnapshot(id: id, provider: "copilot", name: name, email: nil,
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
