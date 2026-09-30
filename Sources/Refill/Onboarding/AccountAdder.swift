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
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("refill-add-\(name).command")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch { return "Couldn't write the login script: \(error.localizedDescription)" }
        NSWorkspace.shared.open(url)
        return "Terminal opened. Type /login there, then quit and hit refresh."
    }
}
