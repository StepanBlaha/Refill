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

    /// Extra Claude profiles (~/.claude-*) only; the default ~/.claude is never trashed.
    static func profileDir(_ a: AccountSnapshot) -> URL? {
        guard a.provider == "claude", a.id.hasPrefix("claude:") else { return nil }
        let path = String(a.id.dropFirst("claude:".count))
        guard path != Paths.home.path + "/.claude" else { return nil }
        return URL(fileURLWithPath: path)
    }

    static func trashProfile(_ a: AccountSnapshot, monitor: Monitor) {
        guard let dir = profileDir(a) else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Move \(dir.lastPathComponent) to the Trash?"
        alert.informativeText = "This signs \(a.email ?? a.name) out of that Claude profile on this Mac. You can restore the folder from the Trash. Your Claude account itself is not affected."
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
        Divider()
        Button("Hide from Refill") { AccountActions.hide(account, monitor: monitor) }
        if AccountActions.profileDir(account) != nil {
            Button("Move profile to Trash…", role: .destructive) { AccountActions.trashProfile(account, monitor: monitor) }
        }
    }
}
