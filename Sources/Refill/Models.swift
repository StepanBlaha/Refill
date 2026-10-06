import Foundation

struct UsageWindow: Codable, Hashable, Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let utilization: Double      // 0...100
    let resetsAt: Date?
}

struct AccountSnapshot: Codable, Identifiable {
    let id: String               // stable: provider + profile
    let provider: String         // "claude" | "codex"
    let name: String             // provider fallback (folder or tool name)
    var email: String?
    var plan: String?
    var windows: [UsageWindow]
    var updatedAt: Date
    var error: String?
    /// Custom name from Settings. Nil means "use email, then name".
    var label: String? = nil

    /// Menu, notch, dashboard and notifications. Custom name, then email, then folder.
    var title: String {
        if let label = label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty { return label }
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty { return email }
        return name
    }

    /// Secondary line: identity that the title did not already use, plus the plan.
    var detail: String {
        var parts: [String] = []
        if let email, !email.isEmpty, email != title { parts.append(email) }
        if name != title, name != email { parts.append(name) }
        if let plan, !plan.isEmpty { parts.append(plan.capitalized) }
        return parts.joined(separator: " · ")
    }
}

enum EventKind: String, Codable, CaseIterable {
    case reset, warning, empty, test
    var title: String {
        switch self {
        case .reset: return "Refilled"
        case .warning: return "Getting low"
        case .empty: return "Tank empty"
        case .test: return "Test"
        }
    }
    /// Light color for integrations (Hue/WLED/webhook {{color}}).
    var rgb: (Int, Int, Int) {
        switch self {
        case .reset, .test: return (200, 255, 77)
        case .warning: return (255, 181, 71)
        case .empty: return (255, 80, 60)
        }
    }
    var hex: String { let c = rgb; return String(format: "#%02X%02X%02X", c.0, c.1, c.2) }
}

struct RefillEvent: Codable {
    let kind: EventKind
    let provider: String
    let accountId: String
    let accountName: String
    let window: String
    let windowLabel: String
    let utilization: Double      // used % at the moment of the event (pre-reset for resets)
    let resetsAt: Date?
    let detectedAt: Date
    let reason: String           // scheduled | observed | threshold | test
    let title: String
    let message: String
}

enum Paths {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let config = home.appendingPathComponent(".config/refill", isDirectory: true)
    static let hook = config.appendingPathComponent("on-reset")
    static let integrationsFile = config.appendingPathComponent("integrations.json")
    static let statusFile = config.appendingPathComponent("status.json")
    static let eventsFile = config.appendingPathComponent("events.jsonl")
    static let stateFile = config.appendingPathComponent("state.json")
    /// Bookkeeping for ntfy messages scheduled ahead of a reset. No tokens.
    static let ntfyScheduleFile = config.appendingPathComponent("ntfy-schedule.json")

    static func ensure() {
        try? FileManager.default.createDirectory(at: config, withIntermediateDirectories: true)
    }
}

extension JSONEncoder {
    static let refill: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}

extension JSONDecoder {
    static let refill: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

func parseISODate(_ s: String?) -> Date? {
    guard let s else { return nil }
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)
}

func shortDuration(_ t: TimeInterval) -> String {
    let s = max(0, Int(t))
    let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
    if d > 0 { return "\(d)d \(h)h" }
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}
