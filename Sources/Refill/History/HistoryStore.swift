import Foundation
import SwiftUI

struct HistorySample: Codable, Hashable {
    let t: Date
    let accountId: String
    let accountName: String
    let provider: String
    let windowKey: String
    let windowLabel: String
    let utilization: Double
    let resetsAt: Date?
}

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    static let file = Paths.config.appendingPathComponent("history.jsonl")

    @Published private(set) var samples: [HistorySample] = []
    private var lastByKey: [String: HistorySample] = [:]
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.sortedKeys]; return e
    }()

    init() { load() }

    private static func key(_ s: HistorySample) -> String { s.accountId + "|" + s.windowKey }

    private func load() {
        var loaded: [HistorySample] = []
        if let data = try? Data(contentsOf: Self.file), let text = String(data: data, encoding: .utf8) {
            let cutoff = Date().addingTimeInterval(-90 * 86400)
            let lines = text.split(separator: "\n")
            for line in lines {
                if let d = line.data(using: .utf8),
                   let s = try? JSONDecoder.refill.decode(HistorySample.self, from: d), s.t >= cutoff {
                    loaded.append(s)
                }
            }
            loaded.sort { $0.t < $1.t }
            if loaded.count != lines.count { rewrite(loaded) }   // compact on launch
        }
        samples = loaded
        for s in loaded { lastByKey[Self.key(s)] = s }
    }

    private func rewrite(_ list: [HistorySample]) {
        Paths.ensure()
        var out = Data()
        for s in list { if let d = try? encoder.encode(s) { out.append(d); out.append(10) } }
        try? out.write(to: Self.file, options: .atomic)
    }

    func record(_ accounts: [AccountSnapshot]) {
        let now = Date()
        var fresh: [HistorySample] = []
        for a in accounts where a.error == nil {
            for w in a.windows where !w.stale {
                let s = HistorySample(t: now, accountId: a.id, accountName: a.title, provider: a.provider,
                                      windowKey: w.key, windowLabel: w.label, utilization: w.utilization,
                                      resetsAt: w.resetsAt)
                if let l = lastByKey[Self.key(s)], l.utilization == s.utilization, l.resetsAt == s.resetsAt,
                   l.accountName == s.accountName, now.timeIntervalSince(l.t) < 15 * 60 { continue }
                fresh.append(s); lastByKey[Self.key(s)] = s
            }
        }
        guard !fresh.isEmpty else { return }
        samples.append(contentsOf: fresh)
        Paths.ensure()
        var out = Data()
        for s in fresh { if let d = try? encoder.encode(s) { out.append(d); out.append(10) } }
        if let h = try? FileHandle(forWritingTo: Self.file) {
            defer { try? h.close() }
            _ = try? h.seekToEnd()
            try? h.write(contentsOf: out)
        } else {
            try? out.write(to: Self.file)
        }
    }

    func series(accountId: String, windowKey: String, since: Date? = nil) -> [HistorySample] {
        samples.filter { $0.accountId == accountId && $0.windowKey == windowKey && (since == nil || $0.t >= since!) }
    }

    /// Accounts known from history, sorted by name.
    var accounts: [(id: String, name: String)] {
        var seen = Set<String>(); var out: [(id: String, name: String)] = []
        for s in samples.reversed() where seen.insert(s.accountId).inserted { out.append((s.accountId, s.accountName)) }
        return out.sorted { $0.name < $1.name }
    }

    func windows(accountId: String) -> [(key: String, label: String)] {
        var seen = Set<String>(); var out: [(key: String, label: String)] = []
        for s in samples.reversed() where s.accountId == accountId && seen.insert(s.windowKey).inserted {
            out.append((s.windowKey, s.windowLabel))
        }
        return out.sorted { $0.key < $1.key }
    }

    func forecast(accountId: String, windowKey: String) -> (perHour: Double, runsOutAt: Date?)? {
        let s = series(accountId: accountId, windowKey: windowKey, since: Date().addingTimeInterval(-3 * 3600))
        guard let last = s.last else { return nil }
        let w = UsageWindow(key: windowKey, label: last.windowLabel, utilization: last.utilization, resetsAt: last.resetsAt)
        return BurnRate.estimate(samples: s, window: w)
    }
}
