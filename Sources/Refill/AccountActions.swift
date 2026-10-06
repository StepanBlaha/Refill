import SwiftUI
import AppKit

/// Hide / restore / trash accounts. Hidden ids live in UserDefaults "hiddenAccounts".
@MainActor
enum AccountActions {
    static let key = "hiddenAccounts"

    static var hidden: Set<String> { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }

    static func hide(_ a: AccountSnapshot, monitor: Monitor) {
        UserDefaults.standard.set(Array(hidden.union([a.id])), forKey: key)
        monitor.drop(a.id)
    }

    static func unhide(_ id: String, monitor: Monitor) {
        UserDefaults.standard.set(Array(hidden.subtracting([id])), forKey: key)
        Task { await monitor.refresh() }
    }

    /// Extra Claude, Codex and Gemini profiles. The default folder for each is never trashed.
    static func profileDir(_ a: AccountSnapshot) -> URL? {
        let home = Paths.home.path
        switch a.provider {
        case "claude":
            guard a.id.hasPrefix("claude:") else { return nil }
            let path = String(a.id.dropFirst("claude:".count))
            guard path != home + "/.claude" else { return nil }
            return URL(fileURLWithPath: path)
        case "codex":
            guard a.id.hasPrefix("codex:"), a.id != "codex:default" else { return nil }
            return URL(fileURLWithPath: String(a.id.dropFirst("codex:".count)))
        case "gemini":
            guard a.id.hasPrefix("gemini:"), a.id != "gemini:default" else { return nil }
            return URL(fileURLWithPath: String(a.id.dropFirst("gemini:".count)))
        default:
            return nil
        }
    }

    static func rename(_ a: AccountSnapshot, monitor: Monitor) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Rename account"
        alert.informativeText = "Shown in the menu, the notch, the dashboard and notifications. Leave it blank to use the email or folder name."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = AccountNames.custom(a.id) ?? ""
        field.placeholderString = a.email ?? a.name
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        AccountNames.set(a.id, field.stringValue)
        monitor.relabel()
    }

    static func trashProfile(_ a: AccountSnapshot, monitor: Monitor) {
        guard let dir = profileDir(a) else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        let tool = a.provider.capitalized
        alert.messageText = "Move \(dir.lastPathComponent) to the Trash?"
        alert.informativeText = "This signs \(a.title) out of that \(tool) profile on this Mac. You can restore the folder from the Trash. The account itself is not affected."
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try FileManager.default.trashItem(at: dir, resultingItemURL: nil)
            monitor.drop(a.id)
        } catch {
            let e = NSAlert(error: error); e.runModal()
        }
    }
}

/// Shared menu items for an account (context menu and "⋯" button).
struct AccountMenuItems: View {
    let account: AccountSnapshot
    @EnvironmentObject var monitor: Monitor

    var body: some View {
        Button("Refresh") { Task { await monitor.refresh() } }
        Button("Rename…") { AccountActions.rename(account, monitor: monitor) }
        Divider()
        Button("Hide from Refill") { AccountActions.hide(account, monitor: monitor) }
        if AccountActions.profileDir(account) != nil {
            Button("Move profile to Trash…", role: .destructive) { AccountActions.trashProfile(account, monitor: monitor) }
        }
    }
}
