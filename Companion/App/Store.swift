import SwiftUI
import UserNotifications

struct WireWindow: Decodable, Identifiable {
    let key: String
    let label: String
    let utilization: Double
    let resetsAt: Date?
    let observedAt: Date?
    let stale: Bool
    var id: String { key }
    var remaining: Double? { stale ? nil : max(0, min(100, 100 - utilization)) }

    enum CodingKeys: String, CodingKey {
        case key, label, utilization, resetsAt, observedAt, stale
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? key
        utilization = try c.decode(Double.self, forKey: .utilization)
        resetsAt = try c.decodeIfPresent(Date.self, forKey: .resetsAt)
        observedAt = try c.decodeIfPresent(Date.self, forKey: .observedAt)
        stale = try c.decodeIfPresent(Bool.self, forKey: .stale) ?? false
    }
}

struct WireAccount: Decodable, Identifiable {
    let id: String
    let provider: String
    let name: String
    let email: String?
    let label: String?
    let plan: String?
    let error: String?
    let windows: [WireWindow]

    var title: String {
        if let label = label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty { return label }
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty { return email }
        return name
    }
}

struct WireStatus: Decodable {
    let updatedAt: Date?
    let accounts: [WireAccount]
}

struct WireEvent: Decodable, Identifiable {
    let kind: EventKind
    let accountName: String
    let windowLabel: String
    let title: String
    let message: String
    let detectedAt: Date
    var id: String { "\(kind.rawValue)|\(accountName)|\(windowLabel)|\(detectedAt.timeIntervalSince1970)" }
}

private let wireDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .custom { dec in
        let s = try dec.singleValueContainer().decode(String.self)
        guard let date = parseISODate(s) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad date \(s)"))
        }
        return date
    }
    return d
}()

@MainActor
final class Store: ObservableObject {
    @AppStorage("macHost") var host: String = "" { willSet { objectWillChange.send() } }
    @AppStorage("ntfyTopic") var ntfyTopic: String = "" { willSet { objectWillChange.send() } }
    @Published var status: WireStatus?
    @Published var events: [WireEvent] = []
    @Published var error: String?
    @Published var loading = false
    @Published var lastFetch: Date?
    @Published var recentReset = false

    private var timer: Timer?
    private var seenEventIDs: Set<String>?

    var baseURL: URL? {
        var h = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.isEmpty { return nil }
        if !h.contains("://") { h = "http://" + h }
        guard var c = URLComponents(string: h) else { return nil }
        if c.port == nil { c.port = 7788 }
        c.path = ""
        return c.url
    }

    /// Lowest remaining % across all 5h windows.
    var lowestRemaining: Double? {
        let accounts = status?.accounts ?? []
        let live = accounts.flatMap { $0.windows }.filter { !$0.stale }
        let five = live.filter { $0.key.contains("5h") || $0.label.lowercased().contains("5") }
        let pool = five.isEmpty ? live : five
        return pool.compactMap { $0.remaining }.min()
    }

    var mood: Voice.Mood { Voice.mood(remaining: lowestRemaining, recentReset: recentReset) }

    func startPolling() {
        stopPolling()
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    func stopPolling() { timer?.invalidate(); timer = nil }

    func fetch<T: Decodable>(_ path: String, from base: URL) async throws -> T {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.timeoutInterval = 6
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try wireDecoder.decode(T.self, from: data)
    }

    /// Returns nil on success or a human-readable error.
    func test(host candidate: String) async -> String? {
        let saved = host
        host = candidate
        defer { host = saved }
        guard let base = baseURL else { return "That doesn't look like a host." }
        do { let _: WireStatus = try await fetch("status", from: base); return nil }
        catch { return "Can't reach \(candidate). Is \"Visible on Wi-Fi\" on and are you on the same network?" }
    }

    func refresh() async {
        guard let base = baseURL else { return }
        loading = true
        defer { loading = false }
        do {
            let s: WireStatus = try await fetch("status", from: base)
            let e: [WireEvent] = (try? await fetch("events", from: base)) ?? events
            status = s; error = nil; lastFetch = Date()
            ingest(e)
        } catch {
            self.error = "Can't reach your Mac. Same Wi-Fi? Visible on Wi-Fi on?"
        }
    }

    private func ingest(_ incoming: [WireEvent]) {
        events = incoming.sorted { $0.detectedAt > $1.detectedAt }
        let ids = Set(events.map(\.id))
        defer { seenEventIDs = ids }
        guard let seen = seenEventIDs else { return } // first load: don't notify history
        let fresh = events.filter { !seen.contains($0.id) && $0.kind == .reset }
        guard !fresh.isEmpty else { return }
        recentReset = true
        Task { try? await Task.sleep(for: .seconds(600)); recentReset = false }
        for ev in fresh { notify(ev) }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(_ ev: WireEvent) {
        let c = UNMutableNotificationContent()
        c.title = ev.title; c.body = ev.message; c.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: ev.id, content: c, trigger: nil))
    }
}
