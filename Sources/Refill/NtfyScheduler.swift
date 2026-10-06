import CryptoKit
import Foundation

extension Notification.Name {
    static let refillIntegrationsChanged = Notification.Name("cz.stepanblaha.refill.integrationsChanged")
}

/// One ntfy message reserved for an account window. Republishing the same
/// message id replaces the pending push. Credentials stay in integrations.json.
struct NtfyBooking: Codable, Equatable {
    var sinkId: String
    var messageId: String
    var accountId: String
    var windowKey: String
    var deliverAt: Date
    var resetsAt: Date
    var title: String
    var message: String
    var server: String
    var topic: String
}

struct NtfyCandidate: Equatable {
    var booking: NtfyBooking
}

/// Pre-schedules ntfy reset pushes so they arrive while the Mac sleeps or is off.
enum NtfyScheduler {
    /// ntfy.sh accepts delays from 10 seconds to 3 days. Stay inside that.
    static let minDelay: TimeInterval = 10
    static let maxAhead: TimeInterval = 3 * 24 * 3600 - 600
    static let afterReset: TimeInterval = 30
    /// Don't DELETE a push that is about to fire.
    static let imminent: TimeInterval = 45
    private static let lock = NSLock()

    static func messageId(accountId: String, windowKey: String) -> String {
        let digest = SHA256.hash(data: Data("\(accountId)|\(windowKey)".utf8))
        let hex = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        return "refill-" + hex
    }

    static func candidates(accounts: [AccountSnapshot], sinks: [Sink], now: Date,
                           maxAhead: TimeInterval = NtfyScheduler.maxAhead,
                           isQuiet: (Date) -> Bool) -> [NtfyCandidate] {
        let ntfy = sinks.filter { $0.kind == .ntfy && $0.enabled && $0.onReset && !$0.v("topic").isEmpty }
        var out: [NtfyCandidate] = []
        for sink in ntfy {
            let server = sink.v("server").isEmpty ? "https://ntfy.sh" : sink.v("server")
            for account in accounts {
                for window in account.windows {
                    guard !window.stale, window.utilization > 0, let resets = window.resetsAt else { continue }
                    let ahead = resets.timeIntervalSince(now)
                    guard ahead > 0, ahead <= maxAhead else { continue }
                    let deliver = resets.addingTimeInterval(afterReset)
                    guard deliver.timeIntervalSince(now) >= minDelay else { continue }
                    if isQuiet(deliver) { continue }
                    out.append(NtfyCandidate(booking: NtfyBooking(
                        sinkId: sink.id.uuidString, messageId: messageId(accountId: account.id, windowKey: window.key),
                        accountId: account.id, windowKey: window.key, deliverAt: deliver, resetsAt: resets,
                        title: "Refilled", message: "\(account.title): \(window.label) is full again.",
                        server: server, topic: sink.v("topic"))))
                }
            }
        }
        return out
    }

    /// What to publish, what to delete, and the bookings that should remain on disk.
    static func diff(desired: [NtfyCandidate], previous: [NtfyBooking], now: Date) -> (post: [NtfyBooking], cancel: [NtfyBooking], keep: [NtfyBooking]) {
        var prevByKey: [String: NtfyBooking] = [:]
        for b in previous { prevByKey[key(b)] = b }
        var seen = Set<String>()
        var post: [NtfyBooking] = []
        var keep: [NtfyBooking] = []
        for c in desired {
            let k = key(c.booking)
            seen.insert(k)
            if let old = prevByKey[k], equivalent(old, c.booking) {
                keep.append(old)
            } else {
                post.append(c.booking)
                keep.append(c.booking)
            }
        }
        var cancel: [NtfyBooking] = []
        for (k, old) in prevByKey where !seen.contains(k) {
            if old.deliverAt.timeIntervalSince(now) > imminent { cancel.append(old) }
            else { keep.append(old) }
        }
        return (post, cancel, keep)
    }

    static func sync(accounts: [AccountSnapshot]) async {
        let now = Date()
        let prefs = Prefs.current
        let sinks = Integrations.load()
        let desired = candidates(accounts: accounts, sinks: sinks, now: now) { deliver in
            guard prefs.quiet, prefs.quietMutesPush else { return false }
            let hour = Calendar.current.component(.hour, from: deliver)
            return ResetDetector.isQuiet(hour: hour, from: prefs.quietFrom, to: prefs.quietTo)
        }
        lock.lock()
        let previous = loadUnlocked()
        lock.unlock()
        let plan = diff(desired: desired, previous: previous, now: now)
        var stored = previous.filter { old in !plan.cancel.contains(where: { key($0) == key(old) }) }
        for booking in plan.cancel {
            _ = await send(cancelRequest(booking, sinks: sinks))
            stored.removeAll { key($0) == key(booking) }
        }
        lock.lock()
        saveUnlocked(stored)
        lock.unlock()
        let active = sinks.filter { $0.kind == .ntfy && $0.enabled }
        for booking in plan.post {
            guard let sink = active.first(where: { $0.id.uuidString == booking.sinkId }),
                  publishRequest(sink, booking) != nil else { continue }
            let status = await send(publishRequest(sink, booking))
            guard status.hasPrefix("OK") else { continue }
            stored.removeAll { key($0) == key(booking) }
            stored.append(booking)
            lock.lock()
            saveUnlocked(stored)
            lock.unlock()
        }
    }

    /// Awake Mac: cancel a still-pending scheduled push and send now.
    /// Asleep-through-delivery: the scheduled push already went out, so skip a second one.
    static func shouldSendImmediate(sink: Sink, event: RefillEvent) -> Bool {
        guard event.kind == .reset, let resets = event.resetsAt else { return true }
        let id = messageId(accountId: event.accountId, windowKey: event.window)
        lock.lock()
        var all = loadUnlocked()
        guard let idx = all.firstIndex(where: {
            $0.sinkId == sink.id.uuidString && $0.messageId == id && abs($0.resetsAt.timeIntervalSince(resets)) < 180
        }) else {
            lock.unlock()
            return true
        }
        let booking = all[idx]
        if booking.deliverAt.timeIntervalSinceNow <= 5 {
            lock.unlock()
            return false
        }
        all.remove(at: idx)
        saveUnlocked(all)
        lock.unlock()
        Task { _ = await send(cancelRequest(booking, sinks: [sink])) }
        return true
    }

    static func publishRequest(_ sink: Sink, _ booking: NtfyBooking) -> URLRequest? {
        guard let url = messageURL(server: booking.server, topic: booking.topic, messageId: booking.messageId) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = Data(booking.message.utf8)
        // Headers stay ASCII. The body carries the account name.
        req.setValue(booking.title, forHTTPHeaderField: "Title")
        req.setValue(String(Int(booking.deliverAt.timeIntervalSince1970)), forHTTPHeaderField: "At")
        req.setValue("zap", forHTTPHeaderField: "Tags")
        req.setValue("4", forHTTPHeaderField: "Priority")
        if !sink.v("token").isEmpty { req.setValue("Bearer \(sink.v("token"))", forHTTPHeaderField: "Authorization") }
        return req
    }

    static func cancelRequest(_ booking: NtfyBooking, sinks: [Sink]) -> URLRequest? {
        guard let url = messageURL(server: booking.server, topic: booking.topic, messageId: booking.messageId) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        if let sink = sinks.first(where: { $0.id.uuidString == booking.sinkId }), !sink.v("token").isEmpty {
            req.setValue("Bearer \(sink.v("token"))", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    static func messageURL(server: String, topic: String, messageId: String) -> URL? {
        var base = server.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty { base = "https://ntfy.sh" }
        while base.hasSuffix("/") { base.removeLast() }
        guard var c = URLComponents(string: base), let scheme = c.scheme, scheme == "http" || scheme == "https" else { return nil }
        func enc(_ s: String) -> String {
            var allowed = CharacterSet.urlPathAllowed
            allowed.remove(charactersIn: "/")
            return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
        }
        var path = c.path
        if path.hasSuffix("/") { path.removeLast() }
        path += "/" + enc(topic) + "/" + enc(messageId)
        c.path = path
        return c.url
    }

    private static func key(_ b: NtfyBooking) -> String { b.sinkId + "|" + b.messageId }

    private static func equivalent(_ a: NtfyBooking, _ b: NtfyBooking) -> Bool {
        a.title == b.title && a.message == b.message && a.topic == b.topic && a.server == b.server
            && abs(a.deliverAt.timeIntervalSince(b.deliverAt)) < 90
            && abs(a.resetsAt.timeIntervalSince(b.resetsAt)) < 90
    }

    private static func send(_ req: URLRequest?) async -> String {
        guard var req else { return "Missing fields" }
        req.timeoutInterval = 10
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if (200..<300).contains(code) { return "OK \(code)" }
            return "HTTP \(code) \(String(data: data, encoding: .utf8)?.prefix(80) ?? "")"
        } catch {
            return error.localizedDescription
        }
    }

    private static func loadUnlocked() -> [NtfyBooking] {
        guard let data = try? Data(contentsOf: Paths.ntfyScheduleFile) else { return [] }
        return (try? JSONDecoder.refill.decode([NtfyBooking].self, from: data)) ?? []
    }

    private static func saveUnlocked(_ bookings: [NtfyBooking]) {
        Paths.ensure()
        guard let data = try? JSONEncoder.refill.encode(bookings) else { return }
        try? data.write(to: Paths.ntfyScheduleFile, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Paths.ntfyScheduleFile.path)
    }
}
