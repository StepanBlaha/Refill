import Foundation

/// Gemini CLI quota through Code Assist (cloudcode-pa). Uses ~/.gemini/oauth_creds.json;
/// refreshes in memory when expired (never written back). The OAuth client id/secret
/// are the public gemini-cli ones, discovered at runtime from the installed CLI
/// (or GEMINI_OAUTH_CLIENT_ID / GEMINI_OAUTH_CLIENT_SECRET) rather than embedded.
enum GeminiProvider {
    static let id = "gemini:default"
    static let creds = Paths.home.appendingPathComponent(".gemini/oauth_creds.json")
    static let base = "https://cloudcode-pa.googleapis.com/v1internal"

    static var isInstalled: Bool { ProviderSupport.exists(creds.path) }

    static func fetch() async -> AccountSnapshot {
        func fail(_ m: String) -> AccountSnapshot { ProviderSupport.failed(id: id, provider: "gemini", name: "Gemini", m) }
        guard let d = try? Data(contentsOf: creds), let c = ProviderSupport.json(d) else { return fail("No Gemini CLI login") }
        var access = c["access_token"] as? String
        let expiry = (ProviderSupport.num(c["expiry_date"])).map { Date(timeIntervalSince1970: $0 / 1000) }
        let email = (c["id_token"] as? String).flatMap { ProviderSupport.jwtPayload($0)?["email"] as? String }
        if access == nil || (expiry ?? .distantPast) < Date().addingTimeInterval(60) {
            guard let refresh = c["refresh_token"] as? String else { return fail("Gemini token expired") }
            guard let fresh = await refreshToken(refresh) else { return fail("Gemini token refresh failed (run `gemini` once)") }
            access = fresh
        }
        guard let token = access else { return fail("No Gemini access token") }
        do {
            let load = try await post("loadCodeAssist", token: token,
                                      body: #"{"metadata":{"ideType":"GEMINI_CLI","pluginType":"GEMINI"}}"#)
            let info = load.flatMap { parseLoad($0) }
            let body = info?.project.map { #"{"project": "\#($0)"}"# } ?? "{}"
            guard let quota = try await post("retrieveUserQuota", token: token, body: body) else {
                return fail("Quota request failed")
            }
            guard var snap = parseQuota(quota) else { return fail("Unexpected response") }
            snap.email = email
            snap.plan = info?.plan
            return snap
        } catch {
            return fail(error.localizedDescription)
        }
    }

    static func post(_ method: String, token: String, body: String) async throws -> Data? {
        var req = URLRequest(url: URL(string: "\(base):\(method)")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data(body.utf8)
        let (data, status) = try await ProviderSupport.send(req)
        return status == 200 ? data : nil
    }

    static func refreshToken(_ refresh: String) async -> String? {
        guard let (cid, secret) = await oauthClient() else { return nil }
        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var allowed = CharacterSet.alphanumerics; allowed.insert(charactersIn: "-._~")
        func enc(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s }
        let form = [("client_id", cid), ("client_secret", secret), ("refresh_token", refresh), ("grant_type", "refresh_token")]
        req.httpBody = Data(form.map { "\($0.0)=\(enc($0.1))" }.joined(separator: "&").utf8)
        guard let (data, s) = try? await ProviderSupport.send(req), s == 200 else { return nil }
        return ProviderSupport.json(data)?["access_token"] as? String
    }

    // MARK: client discovery

    static func oauthClient() async -> (String, String)? {
        let env = ProcessInfo.processInfo.environment
        if let i = env["GEMINI_OAUTH_CLIENT_ID"], let s = env["GEMINI_OAUTH_CLIENT_SECRET"], !i.isEmpty, !s.isEmpty { return (i, s) }
        for path in await candidateScripts() {
            if let text = try? String(contentsOfFile: path, encoding: .utf8), let c = extractClient(from: text) { return c }
        }
        return nil
    }

    static func candidateScripts() async -> [String] {
        let rel = "node_modules/@google/gemini-cli-core/dist/src/code_assist/oauth2.js"
        var roots = ["/opt/homebrew/lib/node_modules/@google/gemini-cli", "/usr/local/lib/node_modules/@google/gemini-cli",
                     "/opt/homebrew/opt/gemini-cli/libexec/lib/node_modules/@google/gemini-cli"]
        if let p = ProcessInfo.processInfo.environment["GEMINI_OAUTH2_JS_PATH"] { return [p] }
        if let bin = ProviderSupport.first(executable: ["gemini"], in: ["/opt/homebrew/bin", "/usr/local/bin"] +
                                           [Paths.home.path + "/.npm-global/bin"]) {
            let real = URL(fileURLWithPath: bin).resolvingSymlinksInPath()
            roots.insert(real.deletingLastPathComponent().deletingLastPathComponent().path, at: 0)
            roots.insert(real.deletingLastPathComponent().path, at: 1)
        }
        var out: [String] = []
        for r in roots {
            out.append("\(r)/\(rel)")
            out.append("\(r)/../gemini-cli-core/dist/src/code_assist/oauth2.js")
            if let files = try? FileManager.default.contentsOfDirectory(atPath: "\(r)/bundle") {
                out += files.filter { $0.hasSuffix(".js") }.map { "\(r)/bundle/\($0)" }
            }
        }
        return out.filter { ProviderSupport.exists($0) }
    }

    static func extractClient(from js: String) -> (String, String)? {
        func grab(_ pattern: String) -> String? {
            guard let re = try? NSRegularExpression(pattern: pattern),
                  let m = re.firstMatch(in: js, range: NSRange(js.startIndex..., in: js)),
                  m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: js) else { return nil }
            return String(js[r])
        }
        guard let id = grab(#"OAUTH_CLIENT_ID\s*=\s*['"]([\w\-\.]+)['"]"#),
              let secret = grab(#"OAUTH_CLIENT_SECRET\s*=\s*['"]([\w\-]+)['"]"#) else { return nil }
        return (id, secret)
    }

    // MARK: parsing (pure)

    static func parseLoad(_ data: Data) -> (project: String?, plan: String?)? {
        guard let j = ProviderSupport.json(data) else { return nil }
        var project = j["cloudaicompanionProject"] as? String
        if let o = j["cloudaicompanionProject"] as? [String: Any] { project = o["id"] as? String ?? o["projectId"] as? String }
        let plan = (j["paidTier"] as? [String: Any])?["name"] as? String
            ?? (j["currentTier"] as? [String: Any])?["name"] as? String
            ?? (j["currentTier"] as? [String: Any])?["id"] as? String
        return (project, plan)
    }

    /// Family for a model id: "flash-lite", "flash", "pro" (else nil).
    static func family(_ model: String) -> (key: String, label: String)? {
        let m = model.lowercased()
        if m.contains("flash-lite") { return ("flash_lite", "Flash Lite") }
        if m.contains("flash") { return ("flash", "Flash") }
        if m.contains("pro") { return ("pro", "Pro") }
        return nil
    }

    static func parseQuota(_ data: Data, now: Date = Date()) -> AccountSnapshot? {
        guard let j = ProviderSupport.json(data), let buckets = j["buckets"] as? [[String: Any]] else { return nil }
        // Most-used bucket per family wins.
        var best: [String: (label: String, used: Double, reset: Date?)] = [:]
        for b in buckets {
            guard let model = b["modelId"] as? String, let fam = family(model),
                  let frac = ProviderSupport.num(b["remainingFraction"]) else { continue }
            let used = ProviderSupport.clamp((1 - frac) * 100)
            if best[fam.key] == nil || used > best[fam.key]!.used {
                best[fam.key] = (fam.label, used, parseISODate(b["resetTime"] as? String))
            }
        }
        let order = ["pro", "flash", "flash_lite"]
        let windows = order.compactMap { k in best[k].map { UsageWindow(key: k, label: $0.label, utilization: $0.used, resetsAt: $0.reset) } }
        var snap = AccountSnapshot(id: id, provider: "gemini", name: "Gemini", email: nil, plan: nil, windows: windows, updatedAt: now)
        if windows.isEmpty { snap.error = "No quota buckets" }
        return snap
    }
}
