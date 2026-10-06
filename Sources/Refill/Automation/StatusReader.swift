import Foundation

/// Reads the live status.json written by the running Monitor.
enum StatusReader {
    struct Status: Codable {
        let updatedAt: Date?
        let accounts: [AccountSnapshot]
        let lastEvent: RefillEvent?
    }

    struct Reading {
        let account: AccountSnapshot
        let window: UsageWindow
        var remaining: Int? {
            guard let left = window.percentLeft else { return nil }
            return min(100, max(0, Int(left.rounded())))
        }
    }

    static func read() -> Status? {
        guard let data = try? Data(contentsOf: Paths.statusFile) else { return nil }
        return try? JSONDecoder.refill.decode(Status.self, from: data)
    }

    static func rawJSON() -> String {
        guard let d = try? Data(contentsOf: Paths.statusFile), let s = String(data: d, encoding: .utf8) else { return "{}" }
        return s
    }

    /// provider: "claude" | "codex" | nil (any). window: "five_hour" | "seven_day".
    /// Picks the matching reading with the LEAST remaining (most constrained).
    static func reading(provider: String?, window: String, account: String? = nil) -> Reading? {
        guard let st = read() else { return nil }
        let acct = account?.trimmingCharacters(in: .whitespaces).lowercased()
        let out: [Reading] = st.accounts.compactMap { a in
            if let p = provider, a.provider != p { return nil }
            if let acct, !acct.isEmpty {
                let names = [a.email, a.name, a.label, a.title].compactMap { $0?.lowercased() }
                if !names.contains(acct) { return nil }
            }
            guard a.error == nil, let w = a.windows.first(where: { $0.key == window }) else { return nil }
            return Reading(account: a, window: w)
        }
        let live = out.filter { !$0.window.stale }
        return (live.isEmpty ? out : live).max { $0.window.utilization < $1.window.utilization }
    }

    static func remaining(provider: String?, window: String, account: String? = nil) -> Int? {
        reading(provider: provider, window: window, account: account)?.remaining
    }

    /// Earliest upcoming reset across matching accounts/windows.
    static func nextRefill(provider: String? = nil, window: String? = nil) -> Date? {
        let now = Date()
        return read()?.accounts
            .filter { provider == nil || $0.provider == provider }
            .flatMap { $0.windows.filter { window == nil || $0.key == window } }
            .compactMap(\.resetsAt).filter { $0 > now }.min()
    }

    static func summary(provider: String?, window: String, account: String? = nil) -> String {
        let name = provider.map { $0.capitalized } ?? "Your tank"
        guard let r = reading(provider: provider, window: window, account: account) else {
            return "No usage data for \(name) yet. Is Refill running?"
        }
        let who = provider == nil ? r.account.provider.capitalized : name
        if r.window.stale {
            return "\(who) usage isn't current (\(lastSeenLabel(r.window.observedAt)))."
        }
        guard let left = r.remaining else {
            return "No usage data for \(name) yet. Is Refill running?"
        }
        var s = "\(who) has \(left)% left"
        if let t = r.window.resetsAt, t > Date() { s += ", refills in \(shortDuration(t.timeIntervalSinceNow))" }
        return s
    }
}
