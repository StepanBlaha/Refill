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

struct ResetEvent: Codable {
    let provider: String
    let accountId: String
    let accountName: String
    let window: String
    let windowLabel: String
    let previousUtilization: Double
    let resetsAt: Date
    let detectedAt: Date
    let reason: String           // "scheduled" | "observed" | "test"
}

enum Paths {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let config = home.appendingPathComponent(".config/refill", isDirectory: true)
    static let hook = config.appendingPathComponent("on-reset")
    static let statusFile = config.appendingPathComponent("status.json")
    static let eventsFile = config.appendingPathComponent("events.jsonl")
    static let stateFile = config.appendingPathComponent("state.json")

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
