import AppKit
import UserNotifications

/// Every way a reset gets broadcast. All sinks are best-effort and independent.
enum Signals {
    static let distributedName = Notification.Name("cz.stepanblaha.refill.reset")

    static func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func fire(_ e: ResetEvent, settings: Prefs) {
        if settings.notify { notify(e, withSound: false) }
        if settings.sound { NSSound(named: NSSound.Name(settings.soundName))?.play() }
        broadcast(e)
        appendLog(e)
        if settings.hook { runHook(e) }
        if !settings.webhookURL.isEmpty { postWebhook(e, url: settings.webhookURL) }
    }

    static func notify(_ e: ResetEvent, withSound: Bool) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let c = UNMutableNotificationContent()
        c.title = "\(e.accountName) refilled"
        c.body = "\(e.windowLabel) limit reset (was \(Int(e.previousUtilization))%). Go build."
        if withSound { c.sound = .default }
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    static func env(_ e: ResetEvent) -> [String: String] {
        [
            "REFILL_PROVIDER": e.provider,
            "REFILL_ACCOUNT_ID": e.accountId,
            "REFILL_ACCOUNT": e.accountName,
            "REFILL_WINDOW": e.window,
            "REFILL_WINDOW_LABEL": e.windowLabel,
            "REFILL_PREVIOUS_UTILIZATION": String(Int(e.previousUtilization)),
            "REFILL_RESETS_AT": ISO8601DateFormatter().string(from: e.resetsAt),
            "REFILL_REASON": e.reason,
        ]
    }

    /// Other macOS apps (Brink, scripts via `swift`/PyObjC, Hammerspoon…) can listen.
    static func broadcast(_ e: ResetEvent) {
        DistributedNotificationCenter.default().postNotificationName(
            distributedName, object: e.accountId, userInfo: env(e), deliverImmediately: true)
    }

    static func appendLog(_ e: ResetEvent) {
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
    static func runHook(_ e: ResetEvent) {
        let path = Paths.hook.path
        guard FileManager.default.isExecutableFile(atPath: path) else { return }
        let json = (try? JSONEncoder.refillCompact.encode(e)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        DispatchQueue.global().async { _ = Shell.run(path, [], stdin: json + "\n", env: env(e)) }
    }

    static func postWebhook(_ e: ResetEvent, url: String) {
        guard let u = URL(string: url) else { return }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder.refillCompact.encode(e)
        URLSession.shared.dataTask(with: req).resume()
    }

    static func installSampleHook() {
        Paths.ensure()
        guard !FileManager.default.fileExists(atPath: Paths.hook.path) else { return }
        let sample = """
        #!/bin/zsh
        # Refill reset hook. Runs on every detected limit reset.
        # Env: REFILL_PROVIDER REFILL_ACCOUNT REFILL_WINDOW REFILL_WINDOW_LABEL
        #      REFILL_PREVIOUS_UTILIZATION REFILL_RESETS_AT REFILL_REASON
        # Stdin: event JSON.
        #
        # Ideas:
        #   say "$REFILL_ACCOUNT is back"
        #   osascript -e 'tell application "Music" to play'
        #   cd ~/project && claude -p "continue the plan in TODO.md" &
        #   curl -s -X POST https://ntfy.sh/my-topic -d "$REFILL_ACCOUNT refilled"

        echo "$(date) $REFILL_ACCOUNT $REFILL_WINDOW_LABEL reset" >> ~/.config/refill/hook.log
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
