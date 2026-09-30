import SwiftUI

/// Copilot / Cursor / Gemini, plugged into AppHooks.providers.
enum ExtraProviders {
    struct Entry {
        let key: String, name: String, source: String
        let installed: () -> Bool
        let fetch: () async -> AccountSnapshot
    }

    static let entries: [Entry] = [
        Entry(key: "provider.copilot", name: "GitHub Copilot",
              source: "Reads: `gh auth token` or ~/.config/github-copilot/apps.json",
              installed: { CopilotProvider.isInstalled }, fetch: { await CopilotProvider.fetch() }),
        Entry(key: "provider.cursor", name: "Cursor",
              source: "Reads: Cursor app login in Application Support/Cursor state.vscdb",
              installed: { CursorProvider.isInstalled }, fetch: { await CursorProvider.fetch() }),
        Entry(key: "provider.gemini", name: "Gemini CLI",
              source: "Reads: ~/.gemini/oauth_creds.json",
              installed: { GeminiProvider.isInstalled }, fetch: { await GeminiProvider.fetch() }),
    ]

    /// Runs every installed + enabled provider concurrently, each capped at 10s.
    static func fetchAll() async -> [AccountSnapshot] {
        let active = entries.filter { ProviderSupport.flag($0.key) && $0.installed() }
        return await withTaskGroup(of: (Int, AccountSnapshot).self) { group in
            for (i, e) in active.enumerated() {
                group.addTask { (i, await withTimeout(10, e)) }
            }
            var out: [(Int, AccountSnapshot)] = []
            for await r in group { out.append(r) }
            return out.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    static func withTimeout(_ seconds: Double, _ e: Entry) async -> AccountSnapshot {
        await withTaskGroup(of: AccountSnapshot?.self) { g in
            g.addTask { await e.fetch() }
            g.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            let first = await g.next() ?? nil
            g.cancelAll()
            return first ?? ProviderSupport.failed(id: "\(e.key):timeout", provider: String(e.key.dropFirst(9)),
                                                   name: e.name, "Timed out")
        }
    }

    @MainActor static func register() {
        AppHooks.providers.append { await ExtraProviders.fetchAll() }
    }
}

struct ProvidersPanel: View {
    @AppStorage("provider.copilot") private var copilot = true
    @AppStorage("provider.cursor") private var cursor = true
    @AppStorage("provider.gemini") private var gemini = true

    var body: some View {
        let bindings = [$copilot, $cursor, $gemini]
        Panel(title: "More providers",
              footer: "Read locally on your Mac. Only providers that look installed are queried.") {
            ForEach(Array(ExtraProviders.entries.enumerated()), id: \.offset) { i, e in
                if i > 0 { RowDivider() }
                ToggleRow(title: e.name, subtitle: e.source, isOn: bindings[i])
            }
        }
    }
}
