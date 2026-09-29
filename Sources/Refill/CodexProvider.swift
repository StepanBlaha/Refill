import Foundation

/// Codex CLI writes `token_count` events with `rate_limits` into its session
/// rollout logs. We read the newest one — no network, no credentials.
enum CodexProvider {
    static let sessions = Paths.home.appendingPathComponent(".codex/sessions")

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: Paths.home.appendingPathComponent(".codex").path)
    }

    static func fetch() -> AccountSnapshot {
        var snap = AccountSnapshot(id: "codex:default", provider: "codex", name: "Codex",
                                   email: nil, plan: nil, windows: [], updatedAt: Date())
        guard let file = newestRollout() else {
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

    static func newestRollout() -> URL? {
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
