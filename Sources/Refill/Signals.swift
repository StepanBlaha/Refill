import AppKit
import UserNotifications

/// Every way a reset gets broadcast. All sinks are best-effort and independent.
enum Signals {
    /// Posted as cz.stepanblaha.refill.<kind> (reset / warning / empty / test).
    static func distributedName(_ k: EventKind) -> Notification.Name { .init("cz.stepanblaha.refill.\(k.rawValue)") }

    static func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func fire(_ e: RefillEvent, settings: Prefs) {
        if settings.notify { notify(e, withSound: false) }
        if settings.sound {
            let name = e.kind == .reset || e.kind == .test ? settings.soundName : (e.kind == .empty ? "Basso" : "Tink")
            NSSound(named: NSSound.Name(name))?.play()
        }
        broadcast(e)
        appendLog(e)
        if settings.hook { runHook(e) }
        Integrations.dispatch(e)
    }

    static func notify(_ e: RefillEvent, withSound: Bool) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let c = UNMutableNotificationContent()
        c.title = e.title
        c.body = e.message
        if withSound { c.sound = .default }
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    static func env(_ e: RefillEvent) -> [String: String] {
        [
            "REFILL_KIND": e.kind.rawValue,
            "REFILL_TITLE": e.title,
            "REFILL_MESSAGE": e.message,
            "REFILL_COLOR": e.kind.hex,
            "REFILL_PROVIDER": e.provider,
            "REFILL_ACCOUNT_ID": e.accountId,
            "REFILL_ACCOUNT": e.accountName,
            "REFILL_WINDOW": e.window,
            "REFILL_WINDOW_LABEL": e.windowLabel,
            "REFILL_UTILIZATION": String(Int(e.utilization)),
            "REFILL_RESETS_AT": e.resetsAt.map { ISO8601DateFormatter().string(from: $0) } ?? "",
            "REFILL_REASON": e.reason,
        ]
    }

    /// Other macOS apps (Brink, scripts via `swift`/PyObjC, Hammerspoon…) can listen.
    static func broadcast(_ e: RefillEvent) {
        DistributedNotificationCenter.default().postNotificationName(
            distributedName(e.kind), object: e.accountId, userInfo: env(e), deliverImmediately: true)
    }

    static func appendLog(_ e: RefillEvent) {
        Paths.ensure()
        guard var line = try? JSONEncoder.refillCompact.encode(e) else { return }
        line.append(0x0A)
        if let h = try? FileHandle(forWritingTo: Paths.eventsFile) {
            _ = try? h.seekToEnd(); try? h.write(contentsOf: line); try? h.close()
        } else {
            try? line.write(to: Paths.eventsFile)
        }
    }

    /// ~/.config/refill/on-reset — any executable. Event JSON on stdin + REFILL_* env.
    static func runHook(_ e: RefillEvent) {
        let path = Paths.hook.path
        guard FileManager.default.isExecutableFile(atPath: path) else { return }
        let json = (try? JSONEncoder.refillCompact.encode(e)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        DispatchQueue.global().async { _ = Shell.run(path, [], stdin: json + "\n", env: env(e)) }
    }

    static func installSampleHook() {
        Paths.ensure()
        guard !FileManager.default.fileExists(atPath: Paths.hook.path) else { return }
        let sample = """
        #!/bin/zsh
        # Refill hook. Runs on every event: reset, warning, empty, test.
        # Env: REFILL_KIND REFILL_TITLE REFILL_MESSAGE REFILL_COLOR REFILL_PROVIDER
        #      REFILL_ACCOUNT REFILL_WINDOW REFILL_WINDOW_LABEL REFILL_UTILIZATION
        #      REFILL_RESETS_AT REFILL_REASON
        # Stdin: event JSON.
        #
        # Ideas:
        #   say "$REFILL_ACCOUNT is back"
        #   osascript -e 'tell application "Music" to play'
        #   cd ~/project && claude -p "continue the plan in TODO.md" &
        #   curl -s -X POST https://ntfy.sh/my-topic -d "$REFILL_ACCOUNT refilled"

        #   [[ $REFILL_KIND == reset ]] && say "$REFILL_ACCOUNT is back"

        echo "$(date) $REFILL_KIND $REFILL_ACCOUNT $REFILL_WINDOW_LABEL" >> ~/.config/refill/hook.log
        """
        try? sample.write(to: Paths.hook, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: Paths.hook.path)
    }
}

extension JSONEncoder {
    static let refillCompact: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}
