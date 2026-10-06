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
        for key in ["primary", "secondary"] {
            guard let w = limits[key] as? [String: Any],
                  let used = (w["used_percent"] as? NSNumber)?.doubleValue else { continue }
            let mins = (w["window_minutes"] as? NSNumber)?.intValue ?? 0
            var reset: Date?
            if let at = (w["resets_at"] as? NSNumber)?.doubleValue {
                reset = Date(timeIntervalSince1970: at)
            } else if let inSec = (w["resets_in_seconds"] as? NSNumber)?.doubleValue {
                reset = stamp.addingTimeInterval(inSec)
            }
            // Stale log: if reset time already passed, usage is effectively 0.
            let effective = (reset.map { $0 < Date() } ?? false) ? 0 : used
            snap.windows.append(UsageWindow(key: key, label: label(mins), utilization: effective, resetsAt: reset))
        }
        return snap
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
        for line in text.split(separator: "\n").reversed() where line.contains("\"rate_limits\"") {
            guard let j = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let payload = j["payload"] as? [String: Any],
                  let limits = payload["rate_limits"] as? [String: Any] else { continue }
            return (limits, parseISODate(j["timestamp"] as? String) ?? Date())
        }
        return nil
    }
}
