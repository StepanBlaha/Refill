import Foundation

/// Custom display names, keyed by stable account id in UserDefaults.
enum AccountNames {
    static let key = "accountLabels"

    static func all() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    static func custom(_ id: String) -> String? {
        let s = all()[id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }

    /// Empty clears the custom name so the email or folder name shows again.
    static func set(_ id: String, _ raw: String?) {
        var d = all()
        let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if s.isEmpty { d.removeValue(forKey: id) } else { d[id] = s }
        UserDefaults.standard.set(d, forKey: key)
    }

    /// Label for a hidden id, when the live snapshot is gone.
    static func hiddenLabel(_ id: String) -> String {
        custom(id) ?? fallback(id)
    }

    static func fallback(_ id: String) -> String {
        if id == "codex:default" { return "Codex" }
        if id == "copilot:default" { return "Copilot" }
        if id == "cursor:default" { return "Cursor" }
        if id == "gemini:default" { return "Gemini" }
        if id.hasPrefix("claude:") { return "Claude · " + lastComponent(String(id.dropFirst("claude:".count))) }
        if id.hasPrefix("codex:") { return "Codex · " + lastComponent(String(id.dropFirst("codex:".count))) }
        if id.hasPrefix("copilot:") { return "Copilot · " + String(id.dropFirst("copilot:".count)) }
        if id.hasPrefix("gemini:") { return "Gemini · " + lastComponent(String(id.dropFirst("gemini:".count))) }
        if id.hasPrefix("cursor:") { return "Cursor" }
        return id.split(separator: ":").first.map { $0.capitalized } ?? id
    }

    private static func lastComponent(_ path: String) -> String {
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? path : name
    }
}
