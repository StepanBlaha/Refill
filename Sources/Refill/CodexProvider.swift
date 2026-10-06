import Foundation

/// One Codex CLI home. The default `~/.codex` keeps the id `codex:default`
/// so history, hide and fired alerts from older Refill builds still match.
struct CodexHome: Equatable {
    var path: String
    var isDefault: Bool
    var fromEnv: Bool
    var userListed: Bool

    var id: String { isDefault ? "codex:default" : "codex:" + path }
    var sessionsURL: URL { URL(fileURLWithPath: path).appendingPathComponent("sessions", isDirectory: true) }
    var fallbackName: String {
        isDefault ? "Codex" : "Codex · " + (path as NSString).lastPathComponent
    }
}

/// Codex CLI writes `token_count` events with `rate_limits` into its session
/// rollout logs. We read the newest one — no network, no credentials.
enum CodexProvider {
    static func discover(home: String, codexHomeEnv: String?, extraDirs: [String], directoryNames: [String]) -> [CodexHome] {
        let defaultPath = normalize(path: home + "/.codex", home: home)
        var byPath: [String: CodexHome] = [
            defaultPath: CodexHome(path: defaultPath, isDefault: true, fromEnv: false, userListed: false),
        ]
        func add(_ raw: String, fromEnv: Bool, userListed: Bool) {
            let p = normalize(path: raw, home: home)
            guard !p.isEmpty else { return }
            if var existing = byPath[p] {
                existing.fromEnv = existing.fromEnv || fromEnv
                existing.userListed = existing.userListed || userListed
                byPath[p] = existing
                return
            }
            byPath[p] = CodexHome(path: p, isDefault: false, fromEnv: fromEnv, userListed: userListed)
        }
        if let env = codexHomeEnv?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            add(env, fromEnv: true, userListed: false)
        }
        for name in directoryNames where name.hasPrefix(".codex-") || name.hasPrefix(".codex_") {
            add(home + "/" + name, fromEnv: false, userListed: false)
        }
        for extra in extraDirs { add(extra, fromEnv: false, userListed: true) }
        let rest = byPath.values.filter { !$0.isDefault }.sorted { $0.path < $1.path }
        return [byPath[defaultPath]!] + rest
    }

    /// `~` expands against `home` so tests don't depend on the machine's real home.
    static func normalize(path: String, home: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let expanded: String
        if trimmed == "~" { expanded = home }
        else if trimmed.hasPrefix("~/") { expanded = home + String(trimmed.dropFirst(1)) }
        else { expanded = trimmed }
        return (expanded as NSString).standardizingPath
    }

    static func present(extraDirs: [String]) -> [CodexHome] {
        let fm = FileManager.default
        let home = Paths.home.path
        let names = (try? fm.contentsOfDirectory(atPath: home)) ?? []
        let env = ProcessInfo.processInfo.environment["CODEX_HOME"]
        return discover(home: home, codexHomeEnv: env, extraDirs: extraDirs, directoryNames: names)
            .filter { fm.fileExists(atPath: $0.path) }
    }

    static var isInstalled: Bool { !present(extraDirs: []).isEmpty }

    static func fetch(_ home: CodexHome) -> AccountSnapshot {
        var snap = AccountSnapshot(id: home.id, provider: "codex", name: home.fallbackName,
                                   email: nil, plan: nil, windows: [], updatedAt: Date())
        guard let file = newestRollout(in: home.sessionsURL) else {
            snap.error = "No Codex sessions yet"
            return snap
        }
        guard let (limits, stamp) = lastRateLimits(in: file) else {
            snap.error = "No rate-limit data in latest session"
            return snap
        }
        snap.plan = limits["plan_type"] as? String
        snap.updatedAt = stamp
        snap.windows = windows(from: limits, eventTime: stamp)
        return snap
    }

    /// `used_percent` is the share already consumed, same as Claude's `utilization`.
    /// Surfaces show percent left as `100 - utilization`. A reset time that has
    /// already passed is not a refill: Codex keeps the logged percent until a
    /// newer event says the window is empty.
    static func windows(from limits: [String: Any], eventTime: Date) -> [UsageWindow] {
        var out: [UsageWindow] = []
        for key in ["primary", "secondary"] {
            guard let w = limits[key] as? [String: Any],
                  let used = ProviderSupport.num(w["used_percent"]) else { continue }
            out.append(UsageWindow(key: key, label: label(windowMinutes(w)),
                                   utilization: ProviderSupport.clamp(used),
                                   resetsAt: resetDate(w, eventTime: eventTime)))
        }
        return out
    }

    static func windowMinutes(_ w: [String: Any]) -> Int {
        if let mins = ProviderSupport.num(w["window_minutes"]), mins > 0 { return Int(mins.rounded()) }
        if let secs = ProviderSupport.num(w["limit_window_seconds"]), secs > 0 {
            return Int((secs / 60).rounded())
        }
        return 0
    }

    static func resetDate(_ w: [String: Any], eventTime: Date) -> Date? {
        if let raw = ProviderSupport.num(w["resets_at"]) ?? ProviderSupport.num(w["reset_at"]) {
            let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
            return Date(timeIntervalSince1970: seconds)
        }
        if let delay = ProviderSupport.num(w["resets_in_seconds"]) ?? ProviderSupport.num(w["reset_after_seconds"]) {
            return eventTime.addingTimeInterval(delay)
        }
        return nil
    }

    static func label(_ mins: Int) -> String {
        switch mins {
        case 300: return "5h session"
        case 10080: return "Week"
        case 0: return "Window"
        default: return mins % 1440 == 0 ? "\(mins / 1440)d" : "\(mins / 60)h"
        }
    }

    static func newestRollout(in sessions: URL) -> URL? {
        guard let e = FileManager.default.enumerator(at: sessions,
                                                     includingPropertiesForKeys: [.contentModificationDateKey]) else { return nil }
        var best: (URL, Date)?
        for case let url as URL in e where url.pathExtension == "jsonl" {
            let d = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if best == nil || d > best!.1 { best = (url, d) }
        }
        return best?.0
    }

    static func lastRateLimits(in file: URL) -> ([String: Any], Date)? {
        guard let h = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? h.close() }
        let size = (try? h.seekToEnd()) ?? 0
        try? h.seek(toOffset: size > 512_000 ? size - 512_000 : 0)
        guard let data = try? h.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }
        return rateLimits(in: text)
    }

    /// Newest plan snapshot (`limit_id` missing or `codex`). A later model
    /// bucket such as `codex_other` does not replace it. If the log has no
    /// plan snapshot, the newest line is used.
    static func rateLimits(in text: String) -> ([String: Any], Date)? {
        var newest: ([String: Any], Date)?
        for line in text.split(separator: "\n").reversed() where line.contains("\"rate_limits\"") {
            guard let j = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let payload = j["payload"] as? [String: Any],
                  let limits = payload["rate_limits"] as? [String: Any] else { continue }
            let parsed = (limits, parseISODate(j["timestamp"] as? String) ?? Date())
            if newest == nil { newest = parsed }
            if isPlanLimit(limits["limit_id"]) { return parsed }
        }
        return newest
    }

    static func isPlanLimit(_ value: Any?) -> Bool {
        guard let value, !(value is NSNull) else { return true }
        guard let raw = value as? String else { return false }
        let id = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return id.isEmpty || id == "codex"
    }
}
