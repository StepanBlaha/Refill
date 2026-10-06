import Foundation

struct Prefs {
    enum K {
        static let notify = "notify", sound = "sound", soundName = "soundName", hook = "hook"
        static let poll = "pollMinutes", codex = "codex", port = "port", lan = "lan"
        static let extraDirs = "extraClaudeDirs", thresholds = "thresholds"
        static let extraCodex = "extraCodexDirs", extraGemini = "extraGeminiDirs"
        static let quiet = "quietHours", quietFrom = "quietFrom", quietTo = "quietTo", quietPush = "quietMutesPush"
    }
    var notify = true, sound = true, soundName = "Glass", hook = true, lan = false
    var pollMinutes = 5.0, codex = true, port = 7788, extraDirs: [String] = []
    var extraCodex: [String] = [], extraGemini: [String] = []
    var thresholds: [Double] = [80, 95]
    var quiet = false, quietFrom = 22, quietTo = 8, quietMutesPush = false

    /// Quiet hours: no sounds (lights and hooks still run).
    var isQuietNow: Bool {
        guard quiet else { return false }
        return ResetDetector.isQuiet(hour: Calendar.current.component(.hour, from: Date()), from: quietFrom, to: quietTo)
    }

    static var current: Prefs {
        let d = UserDefaults.standard
        var p = Prefs()
        p.notify = d.object(forKey: K.notify) as? Bool ?? p.notify
        p.sound = d.object(forKey: K.sound) as? Bool ?? p.sound
        p.soundName = d.string(forKey: K.soundName) ?? p.soundName
        p.hook = d.object(forKey: K.hook) as? Bool ?? p.hook
        p.lan = d.bool(forKey: K.lan)
        p.quiet = d.bool(forKey: K.quiet)
        p.quietFrom = d.object(forKey: K.quietFrom) as? Int ?? 22
        p.quietTo = d.object(forKey: K.quietTo) as? Int ?? 8
        p.quietMutesPush = d.bool(forKey: K.quietPush)
        p.thresholds = (d.string(forKey: K.thresholds) ?? "80, 95").split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }.filter { $0 > 0 && $0 < 100 }
        p.pollMinutes = max(1, d.object(forKey: K.poll) as? Double ?? p.pollMinutes)
        p.codex = d.object(forKey: K.codex) as? Bool ?? p.codex
        p.port = d.object(forKey: K.port) as? Int ?? p.port
        p.extraDirs = lines(d, K.extraDirs)
        p.extraCodex = lines(d, K.extraCodex)
        p.extraGemini = lines(d, K.extraGemini)
        return p
    }

    static func lines(_ d: UserDefaults, _ key: String) -> [String] {
        (d.string(forKey: key) ?? "").split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

private struct SavedState: Codable {
    var accounts: [AccountSnapshot]
    var fired: [String]
    var events: [RefillEvent]
}

@MainActor
final class Monitor: ObservableObject {
    @Published private(set) var accounts: [AccountSnapshot] = []
    @Published private(set) var events: [RefillEvent] = []
    @Published private(set) var refreshing = false
    @Published private(set) var lastRefresh: Date?

    private var fired = Set<String>()
    private var lastFetch = Date.distantPast
    private var timer: Timer?
    private var server: StatusServer?

    /// Side-effect-free instance for PreviewRender.
    init(preview: [AccountSnapshot]) { accounts = preview }

    init() {
        Paths.ensure()
        load()
        Signals.installSampleHook()
        Signals.requestNotificationPermission()
        let s = StatusServer { [weak self] in
            MainActor.assumeIsolated { (self?.statusData() ?? Data("{}".utf8), self?.eventsData() ?? Data("[]".utf8)) }
        }
        s.start(port: UInt16(Prefs.current.port), lan: Prefs.current.lan)
        server = s
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NotificationCenter.default.addObserver(forName: .refillIntegrationsChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await NtfyScheduler.sync(accounts: self.accounts)
            }
        }
        Task { await refresh() }
    }

    /// Lowest remaining % across 5h windows: what the menu bar tank and Drip react to.
    var lowestRemaining: Double? {
        accounts.flatMap(\.windows)
            .filter { ($0.key == "five_hour" || $0.key == "primary") && !$0.stale }
            .compactMap(\.percentLeft).min()
    }

    var recentReset: Bool {
        guard let e = events.last, e.kind == .reset || e.kind == .test else { return false }
        return Date().timeIntervalSince(e.detectedAt) < 600
    }

    var mood: Voice.Mood { Voice.mood(remaining: lowestRemaining, recentReset: recentReset) }

    func tick() {
        checkScheduled()
        if Date().timeIntervalSince(lastFetch) >= Prefs.current.pollMinutes * 60 {
            Task { await refresh() }
        }
    }

    /// Fires as soon as a known resets_at passes — works even if the network/token is dead.
    private func checkScheduled() {
        for a in accounts {
            for w in ResetDetector.scheduledResets(a.windows) { fire(a, w, kind: .reset, reason: "scheduled") }
        }
    }

    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        let prefs = Prefs.current
        let userDirs = Set(prefs.extraDirs.map { ($0 as NSString).expandingTildeInPath })
        var fresh: [AccountSnapshot] = []
        let hidden = AccountActions.hidden
        for p in ClaudeProvider.discover(extraDirs: prefs.extraDirs) where !hidden.contains(p.id) {
            let s = await ClaudeProvider.fetch(p)
            // Auto-discovered ~/.claude-* dirs that aren't logged in are noise.
            if !p.isDefault, !userDirs.contains(p.configDir), s.windows.isEmpty, s.error != nil { continue }
            fresh.append(s)
        }
        if prefs.codex {
            for h in CodexProvider.present(extraDirs: prefs.extraCodex) where !hidden.contains(h.id) {
                let s = await CodexProvider.fetch(h)
                // Auto-discovered ~/.codex-* homes with no sessions are noise.
                if !h.isDefault, !h.userListed, !h.fromEnv, s.windows.isEmpty, s.error != nil { continue }
                fresh.append(s)
            }
        }
        for p in AppHooks.providers { fresh += await p() }
        fresh.removeAll { hidden.contains($0.id) }
        fresh = labeled(fresh)

        for i in fresh.indices {
            guard let old = accounts.first(where: { $0.id == fresh[i].id }) else { continue }
            if fresh[i].windows.isEmpty, fresh[i].error != nil {
                fresh[i].windows = old.windows      // keep last known so scheduled detection still works
                continue
            }
            for c in ResetDetector.crossings(old: old.windows, new: fresh[i].windows, thresholds: prefs.thresholds) {
                fire(fresh[i], c.window, kind: c.threshold >= 100 ? .empty : .warning, reason: "threshold", tag: "t\(Int(c.threshold))")
            }
            for ow in ResetDetector.observedResets(old: old.windows, new: fresh[i].windows) {
                fire(old, ow, kind: .reset, reason: "observed")
            }
        }
        accounts = fresh
        AppHooks.onRefresh.forEach { $0(fresh) }
        lastFetch = Date()
        lastRefresh = lastFetch
        persist()
        let scheduled = accounts
        Task { await NtfyScheduler.sync(accounts: scheduled) }
    }

    private func fire(_ a: AccountSnapshot, _ w: UsageWindow, kind: EventKind, reason: String, tag: String = "") {
        guard let r = w.resetsAt else { return }
        // resets_at jitters by seconds between calls; bucket to 10 min for dedupe.
        guard let key = ResetDetector.key(accountId: a.id, window: w, kind: kind, tag: tag),
              fired.insert(key).inserted else { return }
        let who = a.title
        let (title, msg) = Voice.line(for: kind, account: who, window: w.label, used: w.utilization,
                                      resetsIn: r.timeIntervalSinceNow)
        emit(RefillEvent(kind: kind, provider: a.provider, accountId: a.id, accountName: who,
                         window: w.key, windowLabel: w.label, utilization: w.utilization, resetsAt: r,
                         detectedAt: Date(), reason: reason, title: title, message: msg))
        if reason == "scheduled" {
            Task { try? await Task.sleep(for: .seconds(45)); await refresh() }
        }
    }

    func sendTest() {
        let (t, m) = Voice.line(for: .test, account: "", window: "", used: 0, resetsIn: nil)
        emit(RefillEvent(kind: .test, provider: "test", accountId: "test", accountName: "Refill",
                         window: "five_hour", windowLabel: "5h session", utilization: 100, resetsAt: nil,
                         detectedAt: Date(), reason: "test", title: t, message: m))
    }

    /// Test one integration without broadcasting everywhere.
    func testSink(_ s: Sink) async -> String {
        let (t, m) = Voice.line(for: .test, account: "", window: "", used: 0, resetsIn: nil)
        return await Integrations.send(s, RefillEvent(kind: .test, provider: "test", accountId: "test",
            accountName: "Refill", window: "five_hour", windowLabel: "5h session", utilization: 100,
            resetsAt: nil, detectedAt: Date(), reason: "test", title: t, message: m))
    }

    private func emit(_ e: RefillEvent) {
        events.append(e)
        if events.count > 100 { events.removeFirst(events.count - 100) }
        Signals.fire(e, settings: Prefs.current)
        AppHooks.onEvent.forEach { $0(e) }
        persist()
    }

    /// Drop an account from the live list right away (the next refresh skips it too).
    func drop(_ id: String) {
        accounts.removeAll { $0.id == id }
        persist()
        AppHooks.onRefresh.forEach { $0(accounts) }
        let left = accounts
        Task { await NtfyScheduler.sync(accounts: left) }
    }

    /// Apply renamed labels without a network refresh.
    func relabel() {
        accounts = labeled(accounts)
        persist()
        SharedStatus.write(accounts, lastEvent: events.last)
        let labeledAccounts = accounts
        Task { await NtfyScheduler.sync(accounts: labeledAccounts) }
    }

    private func labeled(_ list: [AccountSnapshot]) -> [AccountSnapshot] {
        list.map { var a = $0; a.label = AccountNames.custom(a.id); return a }
    }

    func restartServer() { server?.start(port: UInt16(Prefs.current.port), lan: Prefs.current.lan) }

    // MARK: Persistence + status outputs

    func statusData() -> Data {
        struct Status: Codable { let updatedAt: Date?; let accounts: [AccountSnapshot]; let lastEvent: RefillEvent? }
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
        accounts = labeled(st.accounts)
        fired = Set(st.fired)
        events = st.events
    }
}
