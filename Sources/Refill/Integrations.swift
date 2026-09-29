import Foundation

/// Outbound integrations: phones, chat, lights, anything with an HTTP endpoint.
/// Stored in ~/.config/refill/integrations.json (chmod 600) so it's scriptable.
enum SinkKind: String, Codable, CaseIterable, Identifiable {
    case ntfy, pushover, telegram, discord, slack, homeAssistant, hue, wled, webhook
    var id: String { rawValue }

    var title: String {
        switch self {
        case .ntfy: return "ntfy (phone push)"
        case .pushover: return "Pushover (phone push)"
        case .telegram: return "Telegram bot"
        case .discord: return "Discord"
        case .slack: return "Slack"
        case .homeAssistant: return "Home Assistant (any lights)"
        case .hue: return "Philips Hue"
        case .wled: return "WLED strip"
        case .webhook: return "Custom webhook"
        }
    }

    var symbol: String {
        switch self {
        case .ntfy, .pushover: return "iphone.gen3"
        case .telegram: return "paperplane.fill"
        case .discord, .slack: return "bubble.left.and.bubble.right.fill"
        case .homeAssistant: return "house.fill"
        case .hue, .wled: return "lightbulb.led.fill"
        case .webhook: return "point.3.connected.trianglepath.dotted"
        }
    }

    struct Field { let key, label, placeholder: String; var secret = false; var multiline = false }

    var fields: [Field] {
        switch self {
        case .ntfy: return [.init(key: "server", label: "Server", placeholder: "https://ntfy.sh"),
                            .init(key: "topic", label: "Topic", placeholder: "refill-stepan-8f3k (make it unguessable)"),
                            .init(key: "token", label: "Access token (optional)", placeholder: "tk_…", secret: true)]
        case .pushover: return [.init(key: "token", label: "App token", placeholder: "a…", secret: true),
                                .init(key: "user", label: "User key", placeholder: "u…", secret: true)]
        case .telegram: return [.init(key: "token", label: "Bot token", placeholder: "123456:ABC…", secret: true),
                                .init(key: "chat", label: "Chat ID", placeholder: "123456789")]
        case .discord: return [.init(key: "url", label: "Webhook URL", placeholder: "https://discord.com/api/webhooks/…", secret: true)]
        case .slack: return [.init(key: "url", label: "Webhook URL", placeholder: "https://hooks.slack.com/services/…", secret: true)]
        case .homeAssistant: return [.init(key: "base", label: "HA URL", placeholder: "http://homeassistant.local:8123"),
                                     .init(key: "hook", label: "Webhook ID", placeholder: "refill")]
        case .hue: return [.init(key: "bridge", label: "Bridge IP", placeholder: "192.168.1.20"),
                           .init(key: "user", label: "API username", placeholder: "from /api pairing", secret: true),
                           .init(key: "group", label: "Group / room ID", placeholder: "0 = all lights")]
        case .wled: return [.init(key: "host", label: "Host", placeholder: "wled.local"),
                            .init(key: "preset", label: "Preset ID for reset (optional)", placeholder: "e.g. 3")]
        case .webhook: return [.init(key: "url", label: "URL", placeholder: "https://…"),
                               .init(key: "method", label: "Method", placeholder: "POST"),
                               .init(key: "headers", label: "Headers (Key: Value per line)", placeholder: "Authorization: Bearer …", secret: false, multiline: true),
                               .init(key: "body", label: "Body template (empty = event JSON)", placeholder: #"{"color":"{{color}}","text":"{{message}}"}"#, multiline: true)]
        }
    }

    var help: String {
        switch self {
        case .ntfy: return "Install the ntfy app (iOS/Android), subscribe to the same topic. Free, no account."
        case .pushover: return "pushover.net: create an app for the token; user key is on your dashboard."
        case .telegram: return "Make a bot via @BotFather, message it once, get chat id from api.telegram.org/bot<token>/getUpdates."
        case .homeAssistant: return "HA automation with a Webhook trigger (ID above). Payload has kind, color, rgb, message: drive any light brand."
        case .hue: return "Press the bridge button, then POST {\"devicetype\":\"refill\"} to http://<bridge>/api to get a username."
        case .wled: return "Reset flashes lime (or runs your preset), warning amber, empty red."
        case .webhook: return "Placeholders: {{kind}} {{title}} {{message}} {{account}} {{window}} {{utilization}} {{color}} {{r}} {{g}} {{b}} {{json}}"
        default: return ""
        }
    }
}

struct Sink: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: SinkKind
    var enabled = true
    var onReset = true, onWarning = true, onEmpty = true
    var values: [String: String] = [:]

    func v(_ k: String) -> String { (values[k] ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }

    func wants(_ k: EventKind) -> Bool {
        guard enabled else { return false }
        switch k { case .reset: return onReset; case .warning: return onWarning; case .empty: return onEmpty; case .test: return true }
    }
}

enum Integrations {
    static func load() -> [Sink] {
        guard let d = try? Data(contentsOf: Paths.integrationsFile) else { return [] }
        return (try? JSONDecoder().decode([Sink].self, from: d)) ?? []
    }

    static func save(_ sinks: [Sink]) {
        Paths.ensure()
        guard let d = try? JSONEncoder.refill.encode(sinks) else { return }
        try? d.write(to: Paths.integrationsFile, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: Paths.integrationsFile.path)
    }

    static func dispatch(_ e: RefillEvent) {
        for s in load() where s.wants(e.kind) { Task { _ = await send(s, e) } }
    }

    /// Returns a short human status ("OK 200" / error) for the Test button.
    static func send(_ s: Sink, _ e: RefillEvent) async -> String {
        do {
            guard var req = try request(s, e) else { return "Missing fields" }
            req.timeoutInterval = 10
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if (200..<300).contains(code) { return "OK \(code)" }
            return "HTTP \(code) \(String(data: data, encoding: .utf8)?.prefix(80) ?? "")"
        } catch {
            return error.localizedDescription
        }
    }

    static func vars(_ e: RefillEvent) -> [String: String] {
        let (r, g, b) = e.kind.rgb
        let json = (try? JSONEncoder.refillCompact.encode(e)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return ["kind": e.kind.rawValue, "title": e.title, "message": e.message, "account": e.accountName,
                "window": e.windowLabel, "utilization": String(Int(e.utilization)), "color": e.kind.hex,
                "r": "\(r)", "g": "\(g)", "b": "\(b)", "json": json]
    }

    private static func json(_ url: String, _ body: Any, method: String = "POST") throws -> URLRequest? {
        guard let u = URL(string: url), u.scheme != nil else { return nil }
        var r = URLRequest(url: u)
        r.httpMethod = method
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: body)
        return r
    }

    private static func form(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    static func request(_ s: Sink, _ e: RefillEvent) throws -> URLRequest? {
        let (r, g, b) = e.kind.rgb
        switch s.kind {
        case .ntfy:
            // JSON publish (UTF-8 safe titles/emoji) to the server root.
            let server = s.v("server").isEmpty ? "https://ntfy.sh" : s.v("server")
            guard !s.v("topic").isEmpty, var req = try json(server, [
                "topic": s.v("topic"), "title": e.title, "message": e.message,
                "tags": [["reset": "zap", "warning": "warning", "empty": "battery", "test": "droplet"][e.kind.rawValue]!],
                "priority": e.kind == .reset ? 4 : 3,
            ]) else { return nil }
            if !s.v("token").isEmpty { req.setValue("Bearer \(s.v("token"))", forHTTPHeaderField: "Authorization") }
            return req
        case .pushover:
            guard !s.v("token").isEmpty, !s.v("user").isEmpty else { return nil }
            var req = URLRequest(url: URL(string: "https://api.pushover.net/1/messages.json")!)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data("token=\(form(s.v("token")))&user=\(form(s.v("user")))&title=\(form(e.title))&message=\(form(e.message))".utf8)
            return req
        case .telegram:
            guard !s.v("token").isEmpty, !s.v("chat").isEmpty else { return nil }
            return try json("https://api.telegram.org/bot\(s.v("token"))/sendMessage",
                            ["chat_id": s.v("chat"), "text": "\(e.title)\n\(e.message)"])
        case .discord:
            return try json(s.v("url"), ["username": "Refill", "embeds": [[
                "title": e.title, "description": e.message, "color": (r << 16) | (g << 8) | b]]])
        case .slack:
            return try json(s.v("url"), ["text": "*\(e.title)*\n\(e.message)"])
        case .homeAssistant:
            guard !s.v("base").isEmpty, !s.v("hook").isEmpty else { return nil }
            var body = vars(e) as [String: Any]
            body["rgb"] = [r, g, b]
            body.removeValue(forKey: "json")
            return try json(s.v("base") + "/api/webhook/" + s.v("hook"), body)
        case .hue:
            guard !s.v("bridge").isEmpty, !s.v("user").isEmpty else { return nil }
            let group = s.v("group").isEmpty ? "0" : s.v("group")
            let xy: [Double] = switch e.kind {
            case .reset, .test: [0.3, 0.6]
            case .warning: [0.55, 0.41]
            case .empty: [0.675, 0.322]
            }
            return try json("http://\(s.v("bridge"))/api/\(s.v("user"))/groups/\(group)/action",
                            ["on": true, "bri": 254, "xy": xy, "alert": e.kind == .warning ? "select" : "lselect"],
                            method: "PUT")
        case .wled:
            guard !s.v("host").isEmpty else { return nil }
            let body: [String: Any] = (e.kind == .reset && Int(s.v("preset")) != nil)
                ? ["on": true, "ps": Int(s.v("preset"))!]
                : ["on": true, "bri": 255, "seg": [["col": [[r, g, b]], "fx": e.kind == .empty ? 0 : 2]]]
            let host = s.v("host").hasPrefix("http") ? s.v("host") : "http://" + s.v("host")
            return try json(host + "/json/state", body)
        case .webhook:
            guard let u = URL(string: s.v("url")), u.scheme != nil else { return nil }
            var req = URLRequest(url: u)
            req.httpMethod = s.v("method").isEmpty ? "POST" : s.v("method").uppercased()
            let vs = vars(e)
            var body = s.v("body").isEmpty ? vs["json"]! : s.v("body")
            for (k, v) in vs where k != "json" { body = body.replacingOccurrences(of: "{{\(k)}}", with: v) }
            body = body.replacingOccurrences(of: "{{json}}", with: vs["json"]!)
            if req.httpMethod != "GET" { req.httpBody = Data(body.utf8) }
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            for line in s.v("headers").split(whereSeparator: \.isNewline) {
                let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 { req.setValue(parts[1], forHTTPHeaderField: parts[0]) }
            }
            return req
        }
    }
}
