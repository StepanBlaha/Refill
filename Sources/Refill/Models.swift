import Foundation

struct UsageWindow: Codable, Hashable, Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let utilization: Double      // 0...100, share already consumed
    let resetsAt: Date?
    /// When a session-log fallback was written. Nil for a live reading.
    let observedAt: Date?
    /// The number comes from a log whose window has already ended.
    let stale: Bool

    init(key: String, label: String, utilization: Double, resetsAt: Date?,
         observedAt: Date? = nil, stale: Bool = false) {
        self.key = key
        self.label = label
        self.utilization = utilization
        self.resetsAt = resetsAt
        self.observedAt = observedAt
        self.stale = stale
    }

    /// Percent still available. Nil when the reading is stale, so a passed
    /// reset is never drawn as a full tank.
    var percentLeft: Double? {
        guard !stale else { return nil }
        return max(0, min(100, 100 - utilization))
    }

    enum CodingKeys: String, CodingKey {
        case key, label, utilization, resetsAt, observedAt, stale
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        label = try c.decode(String.self, forKey: .label)
        utilization = try c.decode(Double.self, forKey: .utilization)
        resetsAt = try c.decodeIfPresent(Date.self, forKey: .resetsAt)
        observedAt = try c.decodeIfPresent(Date.self, forKey: .observedAt)
        stale = try c.decodeIfPresent(Bool.self, forKey: .stale) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .key)
        try c.encode(label, forKey: .label)
        try c.encode(utilization, forKey: .utilization)
        try c.encodeIfPresent(resetsAt, forKey: .resetsAt)
        try c.encodeIfPresent(observedAt, forKey: .observedAt)
        try c.encode(stale, forKey: .stale)
    }
}

/// "last seen 24 Sep" for a stale Codex log. Local calendar, no time.
func lastSeenLabel(_ date: Date?) -> String {
    guard let date else { return "last seen" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "d MMM"
    return "last seen \(f.string(from: date))"
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
