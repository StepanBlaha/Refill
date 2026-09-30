import Foundation

/// Pure detection rules (no side effects) so they can be unit tested.
enum ResetDetector {
    struct Crossing: Equatable { let window: UsageWindow; let threshold: Double }

    /// Thresholds (plus 100) crossed upward between two polls.
    static func crossings(old: [UsageWindow], new: [UsageWindow], thresholds: [Double]) -> [Crossing] {
        new.flatMap { nw -> [Crossing] in
            let before = old.first(where: { $0.key == nw.key })?.utilization ?? nw.utilization
            return (thresholds + [100]).filter { before < $0 && nw.utilization >= $0 }
                .map { Crossing(window: nw, threshold: $0) }
        }
    }

    /// Old windows that a new poll shows were reset: reset time jumped forward >10 min
    /// (or vanished after passing) and usage dropped.
    static func observedResets(old: [UsageWindow], new: [UsageWindow], now: Date = Date()) -> [UsageWindow] {
        old.filter { ow in
            guard ow.utilization > 0, let oldReset = ow.resetsAt,
                  let nw = new.first(where: { $0.key == ow.key }) else { return false }
            let moved = nw.resetsAt.map { $0 > oldReset.addingTimeInterval(600) } ?? (oldReset < now)
            return moved && nw.utilization < ow.utilization
        }
    }

    /// Windows whose known reset time has passed while they were in use.
    static func scheduledResets(_ windows: [UsageWindow], now: Date = Date()) -> [UsageWindow] {
        windows.filter { w in w.utilization > 0 && (w.resetsAt.map { $0 <= now } ?? false) }
    }

    /// Dedupe key; resets_at jitters by seconds, so bucket to 10 minutes.
    static func key(accountId: String, window: UsageWindow, kind: EventKind, tag: String = "") -> String? {
        guard let r = window.resetsAt else { return nil }
        return "\(accountId)|\(window.key)|\(Int(r.timeIntervalSince1970 / 600))|\(kind.rawValue)\(tag)"
    }

    static func isQuiet(hour h: Int, from: Int, to: Int) -> Bool {
        from <= to ? (h >= from && h < to) : (h >= from || h < to)
    }
}
