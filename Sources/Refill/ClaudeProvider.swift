import Foundation
import CryptoKit

/// One Claude Code login = one config dir. Default is ~/.claude; extra accounts
/// live in dirs used with CLAUDE_CONFIG_DIR (e.g. ~/.claude-work).
struct ClaudeProfile: Hashable {
    let configDir: String
    let isDefault: Bool

    var id: String { "claude:" + configDir }
    var displayName: String {
        isDefault ? "Claude" : "Claude · " + (configDir as NSString).lastPathComponent
    }

    /// Claude Code suffixes the Keychain service with sha256(configDir)[0..<8]
    /// when CLAUDE_CONFIG_DIR is set.
    var serviceCandidates: [String] {
        if isDefault { return ["Claude Code-credentials"] }
        let home = Paths.home.path
        var variants = [configDir]
        if configDir.hasPrefix(home) { variants.append("~" + configDir.dropFirst(home.count)) }
        variants += variants.map { $0 + "/" }
        return variants.map { v in
            let hex = SHA256.hash(data: Data(v.utf8)).map { String(format: "%02x", $0) }.joined()
            return "Claude Code-credentials-" + hex.prefix(8)
        }
    }

    var accountFile: URL {
        isDefault ? Paths.home.appendingPathComponent(".claude.json")
                  : URL(fileURLWithPath: configDir).appendingPathComponent(".claude.json")
    }
}

struct ClaudeCredentials {
    var raw: [String: Any]          // full keychain JSON, preserved on write-back
    var service: String

    var oauth: [String: Any] { raw["claudeAiOauth"] as? [String: Any] ?? [:] }
    var accessToken: String? { oauth["accessToken"] as? String }
    var refreshToken: String? { oauth["refreshToken"] as? String }
    var plan: String? { oauth["subscriptionType"] as? String }
    var expiresAt: Date? {
        (oauth["expiresAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
    }
}

enum ClaudeError: LocalizedError {
    case noCredentials, http(Int, String), badResponse
    var errorDescription: String? {
        switch self {
        case .noCredentials: return "Not signed in. Run claude and type /login."
        case .http(let c, let b): return "HTTP \(c): \(b.prefix(120))"
        case .badResponse: return "Unexpected response"
        }
    }
}

enum ClaudeProvider {
    static let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let tokenURL = URL(string: "https://console.anthropic.com/v1/oauth/token")!

    static func discover(extraDirs: [String]) -> [ClaudeProfile] {
        let fm = FileManager.default
        let home = Paths.home.path
        var dirs: [String] = []
        if let items = try? fm.contentsOfDirectory(atPath: home) {
            dirs += items.filter { $0.hasPrefix(".claude-") || $0.hasPrefix(".claude_") }
                .map { home + "/" + $0 }
                .filter { var isDir: ObjCBool = false; return fm.fileExists(atPath: $0, isDirectory: &isDir) && isDir.boolValue }
        }
        dirs += extraDirs.map { ($0 as NSString).expandingTildeInPath }
        var seen = Set<String>()
        var out = [ClaudeProfile(configDir: home + "/.claude", isDefault: true)]
        for d in dirs where !d.isEmpty && seen.insert(d).inserted && d != home + "/.claude" {
            out.append(ClaudeProfile(configDir: d, isDefault: false))
        }
        return out
    }

    // MARK: Keychain via /usr/bin/security (Claude Code's own items allow it)

    static func readCredentials(_ p: ClaudeProfile) -> ClaudeCredentials? {
        for svc in p.serviceCandidates {
            let r = Shell.run("/usr/bin/security", ["find-generic-password", "-s", svc, "-w"])
            if r.status == 0, let data = r.out.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return ClaudeCredentials(raw: obj, service: svc)
            }
        }
        // Fallback: plaintext creds file (Linux-style installs)
        let file = URL(fileURLWithPath: p.configDir).appendingPathComponent(".credentials.json")
        if let data = try? Data(contentsOf: file),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return ClaudeCredentials(raw: obj, service: "")
        }
        return nil
    }

    static func writeCredentials(_ c: ClaudeCredentials) {
        guard !c.service.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: c.raw) else { return }
        let hex = data.map { String(format: "%02x", $0) }.joined()
        let user = NSUserName()
        // -X hex via stdin so the secret never shows up in argv
        _ = Shell.run("/usr/bin/security", ["-i"],
                      stdin: "add-generic-password -U -a \"\(user)\" -s \"\(c.service)\" -X \(hex)\n")
    }

    static func refresh(_ c: inout ClaudeCredentials) async throws {
        guard let rt = c.refreshToken else { throw ClaudeError.noCredentials }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "grant_type": "refresh_token", "refresh_token": rt, "client_id": clientId,
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200, let j = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let at = j["access_token"] as? String else {
            throw ClaudeError.http(code, String(data: data, encoding: .utf8) ?? "")
        }
        var o = c.oauth
        o["accessToken"] = at
        if let nrt = j["refresh_token"] as? String { o["refreshToken"] = nrt }
        if let exp = j["expires_in"] as? NSNumber {
            o["expiresAt"] = Int((Date().timeIntervalSince1970 + exp.doubleValue) * 1000)
        }
        c.raw["claudeAiOauth"] = o
        writeCredentials(c)
    }

    // MARK: Usage

    static func fetch(_ p: ClaudeProfile) async -> AccountSnapshot {
        var snap = AccountSnapshot(id: p.id, provider: "claude", name: p.displayName,
                                   email: accountEmail(p), plan: nil, windows: [], updatedAt: Date())
        guard var creds = readCredentials(p), creds.accessToken != nil else {
            snap.error = ClaudeError.noCredentials.localizedDescription
            return snap
        }
        snap.plan = creds.plan
        do {
            if let exp = creds.expiresAt, exp < Date().addingTimeInterval(60) {
                try await refresh(&creds)
            }
            do {
                snap.windows = try await usage(token: creds.accessToken!)
            } catch ClaudeError.http(401, _) {
                try await refresh(&creds)
                snap.windows = try await usage(token: creds.accessToken!)
            }
        } catch {
            snap.error = error.localizedDescription
        }
        return snap
    }

    static func usage(token: String) async throws -> [UsageWindow] {
        var req = URLRequest(url: usageURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw ClaudeError.http(code, String(data: data, encoding: .utf8) ?? "") }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeError.badResponse
        }
        return obj.compactMap { key, value -> UsageWindow? in
            guard let d = value as? [String: Any],
                  let u = (d["utilization"] as? NSNumber)?.doubleValue else { return nil }
            let reset = parseISODate(d["resets_at"] as? String)
            // Unknown/experimental buckets without a reset time are noise.
            if order(key) == 99 && reset == nil { return nil }
            return UsageWindow(key: key, label: label(key), utilization: u,
                               resetsAt: reset)
        }.sorted { order($0.key) < order($1.key) }
    }

    static func accountEmail(_ p: ClaudeProfile) -> String? {
        guard let data = try? Data(contentsOf: p.accountFile),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let acct = j["oauthAccount"] as? [String: Any] else { return nil }
        return acct["emailAddress"] as? String
    }

    static func label(_ key: String) -> String {
        switch key {
        case "five_hour": return "5h session"
        case "seven_day": return "Week"
        case "seven_day_opus": return "Week · Opus"
        case "seven_day_sonnet": return "Week · Sonnet"
        default: return key.replacingOccurrences(of: "_", with: " ")
        }
    }

    static func order(_ key: String) -> Int {
        ["five_hour", "seven_day", "seven_day_sonnet", "seven_day_opus"].firstIndex(of: key) ?? 99
    }
}

enum Shell {
    struct Result { let status: Int32; let out: String }

    static func run(_ path: String, _ args: [String], stdin: String? = nil,
                    env: [String: String]? = nil) -> Result {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        if let env { p.environment = ProcessInfo.processInfo.environment.merging(env) { $1 } }
        let out = Pipe(), inp = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        if stdin != nil { p.standardInput = inp }
        do { try p.run() } catch { return Result(status: -1, out: "") }
        if let stdin {
            inp.fileHandleForWriting.write(Data(stdin.utf8))
            try? inp.fileHandleForWriting.close()
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return Result(status: p.terminationStatus, out: String(data: data, encoding: .utf8) ?? "")
    }
}
