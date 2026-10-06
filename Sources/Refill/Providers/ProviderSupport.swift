import Foundation

/// Shared helpers for the extra providers (Copilot / Cursor / Gemini).
enum ProviderSupport {
    /// Empty snapshot with an error message; providers never throw.
    static func failed(id: String, provider: String, name: String, _ message: String) -> AccountSnapshot {
        AccountSnapshot(id: id, provider: provider, name: name, email: nil, plan: nil,
                        windows: [], updatedAt: Date(), error: message)
    }

    /// Perform a request with a hard timeout. Returns (data, status).
    static func send(_ req: URLRequest, timeout: TimeInterval = 10) async throws -> (Data, Int) {
        var r = req
        r.timeoutInterval = timeout
        let (data, resp) = try await URLSession.shared.data(for: r)
        return (data, (resp as? HTTPURLResponse)?.statusCode ?? 0)
    }

    /// Run an executable and return stdout (nil on failure / non-zero exit / timeout).
    static func run(_ path: String, _ args: [String], timeout: TimeInterval = 10, allowNonZero: Bool = false) async -> String? {
        guard FileManager.default.isExecutableFile(atPath: path) else { return nil }
        return await Task.detached { () -> String? in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = args
            let out = Pipe()
            p.standardOutput = out
            p.standardError = FileHandle.nullDevice
            do { try p.run() } catch { return nil }
            let killer = DispatchWorkItem { if p.isRunning { p.terminate() } }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killer)
            let data = out.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            killer.cancel()
            guard allowNonZero || p.terminationStatus == 0 else { return nil }
            return String(data: data, encoding: .utf8)
        }.value
    }

    static func first(executable names: [String], in dirs: [String]) -> String? {
        for d in dirs {
            for n in names {
                let p = d + "/" + n
                if FileManager.default.isExecutableFile(atPath: p) { return p }
            }
        }
        return nil
    }

    static func json(_ data: Data) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    static func num(_ v: Any?) -> Double? {
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s) }
        return nil
    }

    static func clamp(_ v: Double) -> Double { min(100, max(0, v)) }

    static func exists(_ path: String) -> Bool { FileManager.default.fileExists(atPath: path) }

    /// Decode the payload (2nd segment) of a JWT.
    static func jwtPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var b = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b += "=" }
        guard let d = Data(base64Encoded: b) else { return nil }
        return json(d)
    }

    static func flag(_ key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
}
