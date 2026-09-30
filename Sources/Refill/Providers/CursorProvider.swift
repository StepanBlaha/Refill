import Foundation

/// Cursor plan usage. Reads the desktop app's access token from its sqlite state
/// DB at runtime, builds the WorkosCursorSessionToken cookie, calls cursor.com.
enum CursorProvider {
    static let id = "cursor:default"
    static let db = Paths.home.appendingPathComponent(
        "Library/Application Support/Cursor/User/globalStorage/state.vscdb")

    static var isInstalled: Bool { ProviderSupport.exists(db.path) }

    static func fetch() async -> AccountSnapshot {
        guard let token = await readValue("cursorAuth/accessToken") else {
            return ProviderSupport.failed(id: id, provider: "cursor", name: "Cursor", "Not signed in to Cursor")
        }
        let email = await readValue("cursorAuth/cachedEmail")
        guard let cookie = cookieHeader(accessToken: token) else {
            return ProviderSupport.failed(id: id, provider: "cursor", name: "Cursor", "Unreadable Cursor token")
        }
        do {
            var req = URLRequest(url: URL(string: "https://cursor.com/api/usage-summary")!)
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue(cookie, forHTTPHeaderField: "Cookie")
            let (data, status) = try await ProviderSupport.send(req)
            guard status == 200 else {
                let hint = status == 401 || status == 403 ? " (session expired, reopen Cursor)" : ""
                return ProviderSupport.failed(id: id, provider: "cursor", name: "Cursor", "HTTP \(status)\(hint)")
            }
            guard var snap = parse(data) else {
                return ProviderSupport.failed(id: id, provider: "cursor", name: "Cursor", "Unexpected response")
            }
            snap.email = email
            return snap
        } catch {
            return ProviderSupport.failed(id: id, provider: "cursor", name: "Cursor", error.localizedDescription)
        }
    }

    static func readValue(_ key: String) async -> String? {
        let sql = "SELECT value FROM ItemTable WHERE key='\(key)';"
        guard let out = await ProviderSupport.run("/usr/bin/sqlite3", ["-readonly", db.path, sql]) else { return nil }
        let v = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }

    /// WorkosCursorSessionToken=<sub's last "|" segment, lowercased>%3A%3A<jwt>
    static func cookieHeader(accessToken: String) -> String? {
        guard let sub = ProviderSupport.jwtPayload(accessToken)?["sub"] as? String,
              let user = sub.split(separator: "|").last else { return nil }
        return "WorkosCursorSessionToken=\(user.lowercased())%3A%3A\(accessToken)"
    }

    // MARK: parsing (pure)

    static func parse(_ data: Data, now: Date = Date()) -> AccountSnapshot? {
        guard let j = ProviderSupport.json(data) else { return nil }
        let reset = parseISODate(j["billingCycleEnd"] as? String)
        let indiv = j["individualUsage"] as? [String: Any] ?? [:]
        let plan = indiv["plan"] as? [String: Any] ?? [:]
        var windows: [UsageWindow] = []

        func add(_ key: String, _ label: String, _ pct: Double?) {
            guard let pct else { return }
            windows.append(UsageWindow(key: key, label: label, utilization: ProviderSupport.clamp(pct), resetsAt: reset))
        }
        func ratio(_ o: [String: Any]) -> Double? {
            guard let used = ProviderSupport.num(o["used"]), let lim = ProviderSupport.num(o["limit"]), lim > 0 else { return nil }
            return used / lim * 100
        }
        let auto = ProviderSupport.num(plan["autoPercentUsed"])
        let api = ProviderSupport.num(plan["apiPercentUsed"])
        var total = ProviderSupport.num(plan["totalPercentUsed"])
        if total == nil, let a = auto, let p = api { total = (a + p) / 2 }
        if total == nil { total = api ?? auto ?? ratio(plan) }
        if total == nil, let o = indiv["overall"] as? [String: Any] { total = ratio(o) }
        add("monthly", "Monthly", total)
        add("auto", "Auto", auto)
        add("api", "API", api)
        if let od = indiv["onDemand"] as? [String: Any] { add("on_demand", "On-demand", ratio(od)) }

        var snap = AccountSnapshot(id: id, provider: "cursor", name: "Cursor", email: nil,
                                   plan: j["membershipType"] as? String, windows: windows, updatedAt: now)
        if windows.isEmpty { snap.error = "No usage data in response" }
        return snap
    }
}
