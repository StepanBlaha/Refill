import Foundation

struct Prefs {
    enum K {
        static let notify = "notify", sound = "sound", soundName = "soundName", hook = "hook"
        static let webhook = "webhookURL", poll = "pollMinutes", codex = "codex", port = "port"
        static let extraDirs = "extraClaudeDirs"
    }
    var notify = true, sound = true, soundName = "Glass", hook = true, webhookURL = ""
    var pollMinutes = 5.0, codex = true, port = 7788, extraDirs: [String] = []

    static var current: Prefs {
        let d = UserDefaults.standard
        var p = Prefs()
        p.notify = d.object(forKey: K.notify) as? Bool ?? p.notify
        p.sound = d.object(forKey: K.sound) as? Bool ?? p.sound
        p.soundName = d.string(forKey: K.soundName) ?? p.soundName
        p.hook = d.object(forKey: K.hook) as? Bool ?? p.hook
        p.webhookURL = d.string(forKey: K.webhook) ?? ""
        p.pollMinutes = max(1, d.object(forKey: K.poll) as? Double ?? p.pollMinutes)
        p.codex = d.object(forKey: K.codex) as? Bool ?? p.codex
        p.port = d.object(forKey: K.port) as? Int ?? p.port
        p.extraDirs = (d.string(forKey: K.extraDirs) ?? "").split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return p
    }
}

private struct SavedState: Codable {
    var accounts: [AccountSnapshot]
    var fired: [String]
    var events: [ResetEvent]
}

@MainActor
final class Monitor: ObservableObject {
    @Published private(set) var accounts: [AccountSnapshot] = []
    @Published private(set) var events: [ResetEvent] = []
    @Published private(set) var refreshing = false
    @Published private(set) var lastRefresh: Date?

    private var fired = Set<String>()
    private var lastFetch = Date.distantPast
    private var timer: Timer?
    private var server: StatusServer?

    init() {
        Paths.ensure()
        load()
        Signals.installSampleHook()
        Signals.requestNotificationPermission()
        let s = StatusServer { [weak self] in
            MainActor.assumeIsolated { (self?.statusData() ?? Data("{}".utf8), self?.eventsData() ?? Data("[]".utf8)) }
        }
        s.start(port: UInt16(Prefs.current.port))
        server = s
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        Task { await refresh() }
    }

    /// Highest 5h-window usage across accounts, for the menu bar label.
    var headline: Int? {
        accounts.flatMap(\.windows).filter { $0.key == "five_hour" || $0.key == "primary" }
            .map { Int($0.utilization.rounded()) }.max()
    }

    func tick() {
        checkScheduled()
        if Date().timeIntervalSince(lastFetch) >= Prefs.current.pollMinutes * 60 {
            Task { await refresh() }
        }
    }

    /// Fires as soon as a known resets_at passes — works even if the network/token is dead.
    private func checkScheduled() {
        let now = Date()
        for a in accounts {
            for w in a.windows where w.utilization > 0 {
                if let r = w.resetsAt, r <= now { fire(a, w, reason: "scheduled") }
            }
        }
    }

    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        let prefs = Prefs.current
        let userDirs = Set(prefs.extraDirs.map { ($0 as NSString).expandingTildeInPath })
        var fresh: [AccountSnapshot] = []
        for p in ClaudeProvider.discover(extraDirs: prefs.extraDirs) {
            let s = await ClaudeProvider.fetch(p)
            // Auto-discovered ~/.claude-* dirs that aren't logged in are noise.
            if !p.isDefault, !userDirs.contains(p.configDir), s.windows.isEmpty, s.error != nil { continue }
            fresh.append(s)
        }
        if prefs.codex, CodexProvider.isInstalled { fresh.append(CodexProvider.fetch()) }

        for i in fresh.indices {
            guard let old = accounts.first(where: { $0.id == fresh[i].id }) else { continue }
            if fresh[i].windows.isEmpty, fresh[i].error != nil {
                fresh[i].windows = old.windows      // keep last known so scheduled detection still works
                continue
            }
            for ow in old.windows where ow.utilization > 0 {
                guard let oldReset = ow.resetsAt,
                      let nw = fresh[i].windows.first(where: { $0.key == ow.key }) else { continue }
                let moved = nw.resetsAt.map { $0 > oldReset.addingTimeInterval(600) } ?? (oldReset < Date())
                if moved && nw.utilization < ow.utilization { fire(old, ow, reason: "observed") }
            }
        }
        accounts = fresh
        lastFetch = Date()
        lastRefresh = lastFetch
        persist()
    }

    private func fire(_ a: AccountSnapshot, _ w: UsageWindow, reason: String) {
        guard let r = w.resetsAt else { return }
        // resets_at jitters by seconds between calls; bucket to 10 min for dedupe.
        let key = "\(a.id)|\(w.key)|\(Int(r.timeIntervalSince1970 / 600))"
        guard fired.insert(key).inserted else { return }
        let e = ResetEvent(provider: a.provider, accountId: a.id, accountName: a.email ?? a.name,
                           window: w.key, windowLabel: w.label, previousUtilization: w.utilization,
                           resetsAt: r, detectedAt: Date(), reason: reason)
        emit(e)
        if reason == "scheduled" {
            Task { try? await Task.sleep(for: .seconds(45)); await refresh() }
        }
    }

    func sendTest() {
        let e = ResetEvent(provider: "test", accountId: "test", accountName: "Refill test",
                           window: "five_hour", windowLabel: "5h session", previousUtilization: 100,
                           resetsAt: Date(), detectedAt: Date(), reason: "test")
        emit(e)
    }

    private func emit(_ e: ResetEvent) {
        events.append(e)
        if events.count > 100 { events.removeFirst(events.count - 100) }
        Signals.fire(e, settings: Prefs.current)
        persist()
    }

    func restartServer() { server?.start(port: UInt16(Prefs.current.port)) }

    // MARK: Persistence + status outputs

    func statusData() -> Data {
        struct Status: Codable { let updatedAt: Date?; let accounts: [AccountSnapshot]; let lastEvent: ResetEvent? }
        return (try? JSONEncoder.refill.encode(Status(updatedAt: lastRefresh, accounts: accounts, lastEvent: events.last))) ?? Data("{}".utf8)
    }

    func eventsData() -> Data { (try? JSONEncoder.refill.encode(Array(events.suffix(50)))) ?? Data("[]".utf8) }

    private func persist() {
        try? statusData().write(to: Paths.statusFile, options: .atomic)
        let st = SavedState(accounts: accounts, fired: Array(fired.suffix(500)), events: events)
        try? JSONEncoder.refill.encode(st).write(to: Paths.stateFile, options: .atomic)
    }

    private func load() {
        guard let d = try? Data(contentsOf: Paths.stateFile),
              let st = try? JSONDecoder.refill.decode(SavedState.self, from: d) else { return }
        accounts = st.accounts
        fired = Set(st.fired)
        events = st.events
    }
}
