import AppKit

/// Creates a fresh Claude config dir and opens Terminal so the user can /login.
enum AccountAdder {
    /// Letters, digits, dash, underscore only.
    static func sanitize(_ raw: String) -> String {
        String(raw.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }
            .map(Character.init))
    }

    @discardableResult
    static func addClaude(name raw: String) -> String {
        let name = sanitize(raw)
        guard !name.isEmpty else { return "Give the account a name first." }
        let dir = NSHomeDirectory() + "/.claude-" + name
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let script = """
        #!/bin/zsh -l
        clear
        echo "Refill: adding Claude account '\(name)'"
        echo ""
        echo "   1. Type /login and finish signing in"
        echo "   2. Then quit Claude (/exit) and close this window"
        echo ""
        export CLAUDE_CONFIG_DIR="\(dir)"
        claude
        echo ""
        echo "Done. Drip will pick the account up on its next refresh."

        """
        return launch(script, name: "claude-" + name,
                      ok: "Terminal opened. Type /login there, then quit and hit refresh.")
    }

    @discardableResult
    static func addCodex(name raw: String) -> String {
        let name = sanitize(raw)
        guard !name.isEmpty else { return "Give the account a name first." }
        let dir = NSHomeDirectory() + "/.codex-" + name
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        remember(dir, key: Prefs.K.extraCodex)
        let script = """
        #!/bin/zsh -l
        clear
        echo "Refill: adding Codex account '\(name)'"
        echo ""
        echo "   1. Sign in if Codex asks (this runs codex login)"
        echo "   2. When the prompt is up, quit Codex"
        echo "   3. Close this window and refresh Refill"
        echo ""
        export CODEX_HOME="\(dir)"
        mkdir -p "$CODEX_HOME"
        codex login
        echo ""
        echo "Starting Codex once so Refill can read a session log."
        codex
        echo ""
        echo "Done. Drip will pick the account up on its next refresh."

        """
        return launch(script, name: "codex-" + name,
                      ok: "Terminal opened. Sign in, use Codex once, then hit refresh.")
    }

    @discardableResult
    static func addGemini(name raw: String) -> String {
        let name = sanitize(raw)
        guard !name.isEmpty else { return "Give the account a name first." }
        // Gemini CLI joins GEMINI_CLI_HOME with ".gemini", so the parent is the home.
        let dir = NSHomeDirectory() + "/.gemini-accounts/" + name
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let script = """
        #!/bin/zsh -l
        clear
        echo "Refill: adding Gemini account '\(name)'"
        echo ""
        echo "   Sign in when Gemini asks, then exit."
        echo "   Creds are stored in \(dir)/.gemini"
        echo ""
        export GEMINI_CLI_HOME="\(dir)"
        mkdir -p "$GEMINI_CLI_HOME"
        gemini
        echo ""
        echo "Done. Drip will pick the account up on its next refresh."

        """
        return launch(script, name: "gemini-" + name,
                      ok: "Terminal opened. Sign in there, then hit refresh.")
    }

    /// So a new Codex home shows up before its first session log exists.
    private static func remember(_ dir: String, key: String) {
        var lines = UserDefaults.standard.string(forKey: key) ?? ""
        let existing = lines.split(whereSeparator: \.isNewline).map { String($0).trimmingCharacters(in: .whitespaces) }
        guard !existing.contains(dir) else { return }
        if !lines.isEmpty, !lines.hasSuffix("\n") { lines += "\n" }
        lines += dir + "\n"
        UserDefaults.standard.set(lines, forKey: key)
    }

    private static func launch(_ script: String, name: String, ok: String) -> String {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("refill-add-\(name).command")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch { return "Couldn't write the login script: \(error.localizedDescription)" }
        NSWorkspace.shared.open(url)
        return ok
    }
}
