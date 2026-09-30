import Foundation

/// Drip's voice. Short, cheeky, never corporate.
enum Voice {
    static func line(for kind: EventKind, account: String, window: String, used: Double, resetsIn: TimeInterval?) -> (String, String) {
        let pct = Int(used.rounded())
        let wait = resetsIn.map { shortDuration($0) } ?? "a bit"
        switch kind {
        case .reset:
            return (["Tank's full", "Refilled", "Back in business"].randomElement()!,
                    ["\(account): \(window) is fresh. Go break something.",
                     "\(window) reset on \(account). Claude's caffeinated and waiting.",
                     "\(account) has a clean \(window). Whatever you were doing, resume it."].randomElement()!)
        case .warning:
            return (["Easy there", "Running warm", "\(pct)% gone"].randomElement()!,
                    ["\(account) has burned \(pct)% of the \(window). Refill in \(wait).",
                     "\(pct)% of \(window) used on \(account). Maybe save the big refactor for later.",
                     "\(account) at \(pct)%. Pace yourself, refill in \(wait)."].randomElement()!)
        case .empty:
            return (["Tank's dry", "Out of juice", "That's all, folks"].randomElement()!,
                    ["\(account) hit the \(window) limit. Back in \(wait). Touch grass?",
                     "\(window) on \(account) is empty. I'll ping you in \(wait).",
                     "\(account) is done for now. Refill in \(wait). Go stretch."].randomElement()!)
        case .test:
            return ("Testing, testing", "If you see this, the pipes work. Drip approves.")
        }
    }

    enum Mood { case happy, focused, sweaty, asleep, party }

    static func mood(remaining: Double?, recentReset: Bool) -> Mood {
        if recentReset { return .party }
        guard let r = remaining else { return .happy }
        switch r {
        case ..<1: return .asleep
        case ..<20: return .sweaty
        case ..<50: return .focused
        default: return .happy
        }
    }

    static func tagline(_ m: Mood) -> String {
        switch m {
        case .happy: return ["Tanks full. Go wild.", "Plenty of juice. Ship it.", "All systems caffeinated."].randomElement()!
        case .focused: return ["Half-tank energy. Stay sharp.", "Burning steady.", "Still got fuel. Use it wisely."].randomElement()!
        case .sweaty: return ["Running on fumes…", "Pace yourself, champ.", "Maybe don't start that refactor."].randomElement()!
        case .asleep: return ["Dry. I'll wake you when it's back.", "Zzz… ping me at refill.", "Nap time. For both of us."].randomElement()!
        case .party: return ["Refilled. Back to it.", "Fresh tank! Back to work.", "We ride again."].randomElement()!
        }
    }
}
