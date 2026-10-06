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
    let name: String
    var email: String?
    var plan: String?
    var windows: [UsageWindow]
    var updatedAt: Date
    var error: String?
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

func lastSeenLabel(_ date: Date?) -> String {
    guard let date else { return "last seen" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "d MMM"
    return "last seen \(f.string(from: date))"
}

func shortDuration(_ t: TimeInterval) -> String {
    let s = max(0, Int(t))
    let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
    if d > 0 { return "\(d)d \(h)h" }
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}
