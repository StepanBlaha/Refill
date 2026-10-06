import Foundation
import CryptoKit

/// One Codex CLI home. The default `~/.codex` keeps the id `codex:default`
/// so history, hide and fired alerts from older Refill builds still match.
struct CodexHome: Equatable {
    var path: String
    var isDefault: Bool
    var fromEnv: Bool
    var userListed: Bool

    var id: String { isDefault ? "codex:default" : "codex:" + path }
    var sessionsURL: URL { URL(fileURLWithPath: path).appendingPathComponent("sessions", isDirectory: true) }
    var authFile: URL { URL(fileURLWithPath: path).appendingPathComponent("auth.json") }
    var fallbackName: String {
        isDefault ? "Codex" : "Codex · " + (path as NSString).lastPathComponent
    }
}

/// Where a ChatGPT login was read. A refresh is written back to the same place.
enum CodexAuthSource: Equatable {
    case file(URL)
    case keychain(account: String)
}

struct CodexLogin {
    var raw: [String: Any]
    var source: CodexAuthSource
    var accessToken: String
    var refreshToken: String?
    var accountId: String?
    var email: String?
    var fedramp: Bool
}

enum CodexError: Error {
    case unauthorized
    case expired
    case badResponse
    case http(Int)
}

/// Live Codex usage from the ChatGPT login already stored for that home.
///
/// The CLI's usage request is `GET {base}/wham/usage` when the base is the
/// ChatGPT API (`codex-rs/backend-client/src/client/rate_limit_resets.rs`,
/// `rate_limit_status_url`, `PathStyle::ChatGptApi`). ChatGPT login uses
/// `https://chatgpt.com/backend-api`, so the call is
/// `GET https://chatgpt.com/backend-api/wham/usage`.
/// Headers match `Client::headers` in `codex-rs/backend-client/src/client.rs`:
/// `Authorization: Bearer`, `ChatGPT-Account-ID`, `User-Agent: codex-cli`,
/// and `X-OpenAI-Fedramp: true` only for a fedramp account.
///
/// An expired access token is refreshed with
/// `POST https://auth.openai.com/oauth/token`
/// (`codex-rs/login/src/auth/manager.rs`: `REFRESH_TOKEN_URL`, client id
/// `app_EMoamEEZ73f0CkXaXp7hrann`, grant `refresh_token`).
///
/// Session rollouts under `<CODEX_HOME>/sessions` are only a fallback.
/// Codex still writes those at `sessions/YYYY/MM/DD/rollout-*.jsonl`
/// (`codex-rs/rollout/src/recorder.rs`). `archived_sessions` is where a
/// thread moves after archive (`codex-rs/thread-store/src/local/archive_thread.rs`),
/// and `~/Library/Logs/com.openai.codex` is app logs, not quota. Neither is
/// a live reading, so discovery stays on `sessions/`.
enum CodexProvider {
    static let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
    static let refreshURL = URL(string: "https://auth.openai.com/oauth/token")!
    static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    static let keychainService = "Codex Auth"

    static func discover(home: String, codexHomeEnv: String?, extraDirs: [String], directoryNames: [String]) -> [CodexHome] {
        let defaultPath = normalize(path: home + "/.codex", home: home)
        var byPath: [String: CodexHome] = [
            defaultPath: CodexHome(path: defaultPath, isDefault: true, fromEnv: false, userListed: false),
        ]
        func add(_ raw: String, fromEnv: Bool, userListed: Bool) {
            let p = normalize(path: raw, home: home)
            guard !p.isEmpty else { return }
            if var existing = byPath[p] {
                existing.fromEnv = existing.fromEnv || fromEnv
                existing.userListed = existing.userListed || userListed
                byPath[p] = existing
                return
            }
            byPath[p] = CodexHome(path: p, isDefault: false, fromEnv: fromEnv, userListed: userListed)
        }
        if let env = codexHomeEnv?.trimmingCharacters(in: .whitespacesAndNewlines), !env.isEmpty {
            add(env, fromEnv: true, userListed: false)
        }
        for name in directoryNames where name.hasPrefix(".codex-") || name.hasPrefix(".codex_") {
            add(home + "/" + name, fromEnv: false, userListed: false)
        }
        for extra in extraDirs { add(extra, fromEnv: false, userListed: true) }
        let rest = byPath.values.filter { !$0.isDefault }.sorted { $0.path < $1.path }
        return [byPath[defaultPath]!] + rest
    }

    /// `~` expands against `home` so tests don't depend on the machine's real home.
    static func normalize(path: String, home: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let expanded: String
        if trimmed == "~" { expanded = home }
        else if trimmed.hasPrefix("~/") { expanded = home + String(trimmed.dropFirst(1)) }
        else { expanded = trimmed }
        return (expanded as NSString).standardizingPath
    }

    static func present(extraDirs: [String]) -> [CodexHome] {
        let fm = FileManager.default
        let home = Paths.home.path
        let names = (try? fm.contentsOfDirectory(atPath: home)) ?? []
        let env = ProcessInfo.processInfo.environment["CODEX_HOME"]
        return discover(home: home, codexHomeEnv: env, extraDirs: extraDirs, directoryNames: names)
            .filter { fm.fileExists(atPath: $0.path) }
    }

    static var isInstalled: Bool { !present(extraDirs: []).isEmpty }

    /// Same switch as Claude. Off means Refill never rotates a Codex refresh token.
    static var mayRefresh: Bool { UserDefaults.standard.object(forKey: "refreshTokens") as? Bool ?? true }

    static func fetch(_ home: CodexHome) async -> AccountSnapshot {
        let now = Date()
        var snap = AccountSnapshot(id: home.id, provider: "codex", name: home.fallbackName,
                                   email: nil, plan: nil, windows: [], updatedAt: now)
        if var login = loadAuth(home) {
            do {
                if accessTokenExpired(login.accessToken, now: now) {
                    guard mayRefresh else { throw CodexError.expired }
                    login = try await refresh(login)
                }
                let data: Data
                do {
                    data = try await usageData(login)
                } catch CodexError.unauthorized {
                    guard mayRefresh else { throw CodexError.expired }
                    login = try await refresh(login)
                    data = try await usageData(login)
                }
                let parsed = try parseUsageResponse(data, now: now)
                snap.plan = parsed.plan
                snap.email = login.email
                snap.windows = parsed.windows
                snap.updatedAt = now
                return snap
            } catch {
                let fallback = snapshotFromLogs(home, now: now)
                if !fallback.windows.isEmpty { return fallback }
                snap.error = message(for: error)
                return snap
            }
        }
        let fallback = snapshotFromLogs(home, now: now)
        if !fallback.windows.isEmpty { return fallback }
        snap.error = "No Codex login. Run codex login in this home."
        return snap
    }

    static func message(for error: Error) -> String {
        switch error {
        case CodexError.expired, CodexError.unauthorized:
            return "Login expired. Run codex login in this home."
        default:
            return "Couldn't reach Codex usage."
        }
    }

    // MARK: Live usage

    /// ChatGPT usage JSON, either the flat body Codex's curl shows
    /// (`rate_limit.primary_window`) or the decoded wrapper
    /// (`rate_limits.rate_limit`). `additional_rate_limits` are model buckets
    /// and never replace the plan windows.
    static func parseUsageResponse(_ data: Data, now: Date) throws -> (plan: String?, windows: [UsageWindow]) {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let picked = rateLimitBody(in: obj) else { throw CodexError.badResponse }
        let plan = string(picked.body["plan_type"]) ?? string(obj["plan_type"])
        var windows: [UsageWindow] = []
        if let primary = picked.rate["primary_window"] as? [String: Any],
           let window = liveWindow(key: "primary", dict: primary, now: now) {
            windows.append(window)
        }
        if let secondary = picked.rate["secondary_window"] as? [String: Any],
           let window = liveWindow(key: "secondary", dict: secondary, now: now) {
            windows.append(window)
        }
        guard !windows.isEmpty else { throw CodexError.badResponse }
        return (plan, windows)
    }

    static func rateLimitBody(in obj: [String: Any]) -> (body: [String: Any], rate: [String: Any])? {
        func pick(_ body: [String: Any]) -> [String: Any]? {
            guard let rate = body["rate_limit"] as? [String: Any] else { return nil }
            if rate["primary_window"] is [String: Any] || rate["secondary_window"] is [String: Any] {
                return rate
            }
            return nil
        }
        if let rate = pick(obj) { return (obj, rate) }
        if let nested = obj["rate_limits"] as? [String: Any], let rate = pick(nested) {
            return (nested, rate)
        }
        return nil
    }

    static func liveWindow(key: String, dict: [String: Any], now: Date) -> UsageWindow? {
        guard let used = ProviderSupport.num(dict["used_percent"]) else { return nil }
        return UsageWindow(key: key, label: label(windowMinutes(dict)),
                           utilization: ProviderSupport.clamp(used),
                           resetsAt: resetDate(dict, eventTime: now),
                           observedAt: nil, stale: false)
    }

    static func usageData(_ login: CodexLogin) async throws -> Data {
        var req = URLRequest(url: usageURL)
        req.setValue("Bearer \(login.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("codex-cli", forHTTPHeaderField: "User-Agent")
        if let account = login.accountId, !account.isEmpty {
            req.setValue(account, forHTTPHeaderField: "ChatGPT-Account-ID")
        }
        if login.fedramp {
            req.setValue("true", forHTTPHeaderField: "X-OpenAI-Fedramp")
        }
        let (data, code) = try await ProviderSupport.send(req, timeout: 15)
        if code == 401 { throw CodexError.unauthorized }
        guard code == 200 else { throw CodexError.http(code) }
        return data
    }

    // MARK: Login

    /// `auth.json` first. If Codex stored the login in the keychain instead
    /// (service `Codex Auth`, account `cli|<16 hex>` from
    /// `compute_store_key` in `codex-rs/login/src/auth/storage.rs`), read that.
    /// The first keychain read can prompt.
    static func loadAuth(_ home: CodexHome) -> CodexLogin? {
        if let data = try? Data(contentsOf: home.authFile),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let login = session(from: obj, source: .file(home.authFile)) {
            return login
        }
        let account = storeKey(path: home.path)
        let r = Shell.run("/usr/bin/security", ["find-generic-password", "-s", keychainService, "-a", account, "-w"])
        guard r.status == 0,
              let data = r.out.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let login = session(from: obj, source: .keychain(account: account)) else { return nil }
        return login
    }

    static func session(from raw: [String: Any], source: CodexAuthSource) -> CodexLogin? {
        guard let tokens = raw["tokens"] as? [String: Any],
              let access = string(tokens["access_token"]) else { return nil }
        let who = identity(accessToken: access, tokens: tokens)
        return CodexLogin(raw: raw, source: source, accessToken: access,
                          refreshToken: string(tokens["refresh_token"]),
                          accountId: who.accountId, email: who.email, fedramp: who.fedramp)
    }

    /// `tokens.account_id`, else the access token's
    /// `https://api.openai.com/auth`.chatgpt_account_id. Email is optional.
    static func identity(accessToken: String, tokens: [String: Any]) -> (accountId: String?, email: String?, fedramp: Bool) {
        let payload = ProviderSupport.jwtPayload(accessToken)
        let auth = payload?["https://api.openai.com/auth"] as? [String: Any]
        let profile = payload?["https://api.openai.com/profile"] as? [String: Any]
        let account = string(tokens["account_id"]) ?? string(auth?["chatgpt_account_id"])
        let fedramp = (auth?["chatgpt_account_is_fedramp"] as? Bool) ?? false
        return (account, string(profile?["email"]), fedramp)
    }

    /// True only when the JWT `exp` is present and already past. A token
    /// without `exp` is used as-is and refreshed only after HTTP 401.
    static func accessTokenExpired(_ token: String, now: Date) -> Bool {
        guard let payload = ProviderSupport.jwtPayload(token),
              let exp = ProviderSupport.num(payload["exp"]) else { return false }
        return exp <= now.timeIntervalSince1970
    }

    /// Merge a refresh response into the auth JSON. Unknown keys stay.
    /// `id_token` is replaced only when it is already a string (Codex sometimes
    /// stores parsed claims instead).
    static func applyRefresh(_ raw: [String: Any], response: [String: Any], now: Date) -> [String: Any] {
        var raw = raw
        var tokens = raw["tokens"] as? [String: Any] ?? [:]
        if let access = string(response["access_token"]) { tokens["access_token"] = access }
        if let refresh = string(response["refresh_token"]) { tokens["refresh_token"] = refresh }
        if let id = string(response["id_token"]), tokens["id_token"] is String || tokens["id_token"] == nil {
            tokens["id_token"] = id
        }
        raw["tokens"] = tokens
        raw["last_refresh"] = iso8601(now)
        return raw
    }

    static func refresh(_ login: CodexLogin) async throws -> CodexLogin {
        guard let rt = login.refreshToken else { throw CodexError.expired }
        var req = URLRequest(url: refreshURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "client_id": clientID, "grant_type": "refresh_token", "refresh_token": rt,
        ])
        let (data, code) = try await ProviderSupport.send(req, timeout: 15)
        guard code == 200, let obj = ProviderSupport.json(data), string(obj["access_token"]) != nil else {
            throw CodexError.expired
        }
        let updated = applyRefresh(login.raw, response: obj, now: Date())
        guard let next = session(from: updated, source: login.source) else { throw CodexError.expired }
        writeAuth(next)
        return next
    }

    static func writeAuth(_ login: CodexLogin) {
        guard JSONSerialization.isValidJSONObject(login.raw),
              let data = try? JSONSerialization.data(withJSONObject: login.raw, options: [.prettyPrinted, .sortedKeys]) else { return }
        switch login.source {
        case .file(let url):
            try? data.write(to: url, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        case .keychain(let account):
            let hex = data.map { String(format: "%02x", $0) }.joined()
            _ = Shell.run("/usr/bin/security", ["-i"],
                          stdin: "add-generic-password -U -a \"\(account)\" -s \"\(keychainService)\" -X \(hex)\n")
        }
    }

    /// `cli|` plus the first 16 hex chars of SHA-256 of the canonical home path.
    static func storeKey(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let canonical = url.resolvingSymlinksInPath().path
        let digest = SHA256.hash(data: Data(canonical.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "cli|" + String(hex.prefix(16))
    }

    // MARK: Session-log fallback

    /// Newest rollout under `sessions/`. A window whose reset time has already
    /// passed is marked stale: the percent is kept for history, but surfaces
    /// show "—" instead of treating the ended window as full.
    static func snapshotFromLogs(_ home: CodexHome, now: Date) -> AccountSnapshot {
        var snap = AccountSnapshot(id: home.id, provider: "codex", name: home.fallbackName,
                                   email: nil, plan: nil, windows: [], updatedAt: now)
        guard let file = newestRollout(in: home.sessionsURL) else {
            snap.error = "No Codex sessions yet"
            return snap
        }
        guard let (limits, stamp) = lastRateLimits(in: file) else {
            snap.error = "No rate-limit data in latest session"
            return snap
        }
        snap.plan = string(limits["plan_type"])
        snap.updatedAt = stamp
        snap.windows = windows(from: limits, eventTime: stamp, now: now, live: false)
        return snap
    }

    /// `used_percent` is the share already consumed, same as Claude's `utilization`.
    /// A live response is never stale, even when `reset_at` is already past:
    /// the server just confirmed the number. A log window is stale once that
    /// reset time has passed.
    static func windows(from limits: [String: Any], eventTime: Date, now: Date = Date(), live: Bool = false) -> [UsageWindow] {
        var out: [UsageWindow] = []
        for key in ["primary", "secondary"] {
            guard let w = limits[key] as? [String: Any],
                  let used = ProviderSupport.num(w["used_percent"]) else { continue }
            let reset = resetDate(w, eventTime: eventTime)
            let stale = !live && reset.map { $0 <= now } == true
            out.append(UsageWindow(key: key, label: label(windowMinutes(w)),
                                   utilization: ProviderSupport.clamp(used),
                                   resetsAt: reset,
                                   observedAt: live ? nil : eventTime,
                                   stale: stale))
        }
        return out
    }

    static func windowMinutes(_ w: [String: Any]) -> Int {
        if let mins = ProviderSupport.num(w["window_minutes"]), mins > 0 { return Int(mins.rounded()) }
        if let secs = ProviderSupport.num(w["limit_window_seconds"]), secs > 0 {
            return Int((secs + 59) / 60)
        }
        return 0
    }

    static func resetDate(_ w: [String: Any], eventTime: Date) -> Date? {
        if let raw = ProviderSupport.num(w["resets_at"]) ?? ProviderSupport.num(w["reset_at"]) {
            let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
            return Date(timeIntervalSince1970: seconds)
        }
        if let delay = ProviderSupport.num(w["resets_in_seconds"]) ?? ProviderSupport.num(w["reset_after_seconds"]) {
            return eventTime.addingTimeInterval(delay)
        }
        return nil
    }

    static func label(_ mins: Int) -> String {
        switch mins {
        case 300: return "5h session"
        case 10080: return "Week"
        case 0: return "Window"
        default: return mins % 1440 == 0 ? "\(mins / 1440)d" : "\(mins / 60)h"
        }
    }

    static func newestRollout(in sessions: URL) -> URL? {
        guard let e = FileManager.default.enumerator(at: sessions,
                                                     includingPropertiesForKeys: [.contentModificationDateKey]) else { return nil }
        var best: (URL, Date)?
        for case let url as URL in e where url.pathExtension == "jsonl" {
            let d = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if best == nil || d > best!.1 { best = (url, d) }
        }
        return best?.0
    }

    static func lastRateLimits(in file: URL) -> ([String: Any], Date)? {
        guard let h = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? h.close() }
        let size = (try? h.seekToEnd()) ?? 0
        try? h.seek(toOffset: size > 512_000 ? size - 512_000 : 0)
        guard let data = try? h.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }
        return rateLimits(in: text)
    }

    /// Newest plan snapshot (`limit_id` missing or `codex`). A later model
    /// bucket such as `codex_other` does not replace it. If the log has no
    /// plan snapshot, the newest line is used.
    static func rateLimits(in text: String) -> ([String: Any], Date)? {
        var newest: ([String: Any], Date)?
        for line in text.split(separator: "\n").reversed() where line.contains("\"rate_limits\"") {
            guard let j = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let payload = j["payload"] as? [String: Any],
                  let limits = payload["rate_limits"] as? [String: Any] else { continue }
            let parsed = (limits, parseISODate(j["timestamp"] as? String) ?? Date())
            if newest == nil { newest = parsed }
            if isPlanLimit(limits["limit_id"]) { return parsed }
        }
        return newest
    }

    static func isPlanLimit(_ value: Any?) -> Bool {
        guard let value, !(value is NSNull) else { return true }
        guard let raw = value as? String else { return false }
        let id = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return id.isEmpty || id == "codex"
    }

    static func string(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func iso8601(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date)
    }
}
