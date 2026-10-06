import XCTest
@testable import Refill

final class CodexDiscoveryTests: XCTestCase {
    let home = "/Users/me"

    func testDefaultHomeKeepsLegacyId() {
        let homes = CodexProvider.discover(home: home, codexHomeEnv: nil, extraDirs: [], directoryNames: [])
        XCTAssertEqual(homes.map(\.id), ["codex:default"])
        XCTAssertEqual(homes[0].path, home + "/.codex")
    }

    func testCodexHomeEnvAndSiblingFolders() {
        let homes = CodexProvider.discover(
            home: home, codexHomeEnv: "/tmp/codex-env",
            extraDirs: ["~/clients/codex"],
            directoryNames: [".codex", ".codex-work", ".codex_school", "notes"])
        XCTAssertEqual(homes.map(\.id), [
            "codex:default",
            "codex:" + home + "/.codex-work",
            "codex:" + home + "/.codex_school",
            "codex:" + home + "/clients/codex",
            "codex:/tmp/codex-env",
        ])
        let env = try? XCTUnwrap(homes.first { $0.path == "/tmp/codex-env" })
        XCTAssertEqual(env?.fromEnv, true)
        XCTAssertEqual(env?.isDefault, false)
        let extra = try? XCTUnwrap(homes.first { $0.path == home + "/clients/codex" })
        XCTAssertEqual(extra?.userListed, true)
    }

    func testCodexHomePointingAtDefaultDoesNotDuplicate() {
        let homes = CodexProvider.discover(home: home, codexHomeEnv: "~/.codex", extraDirs: [home + "/.codex"], directoryNames: [])
        XCTAssertEqual(homes.count, 1)
        XCTAssertEqual(homes[0].id, "codex:default")
        XCTAssertTrue(homes[0].fromEnv)
        XCTAssertTrue(homes[0].userListed)
    }

    func testNormalizeCollapsesDotDots() {
        XCTAssertEqual(CodexProvider.normalize(path: home + "/../me/.codex-work", home: home), home + "/.codex-work")
    }
}

final class CopilotAccountTests: XCTestCase {
    func testParseAuthStatus() {
        let text = """
        github.com
          ✓ Logged in to github.com account alice (keyring)
          - Active account: true
          - Token: gho_secret

          ✓ Logged in to github.com account bob (keyring)
          - Active account: false

        ghe.example.com
          ✓ Logged in to ghe.example.com account carol (keyring)
          - Active account: true
        """
        let parsed = CopilotProvider.parseAuthStatus(text)
        XCTAssertEqual(parsed.map(\.login), ["alice", "bob"])
        XCTAssertEqual(parsed.map(\.active), [true, false])
    }

    func testAnchorKeepsDefaultId() {
        let rows = CopilotProvider.assign(logins: [
            GhLogin(login: "alice", active: false),
            GhLogin(login: "bob", active: true),
        ], anchor: "alice")
        XCTAssertEqual(rows.accounts.map(\.id), ["copilot:default", "copilot:bob"])
        XCTAssertEqual(rows.accounts.map(\.login), ["alice", "bob"])
        XCTAssertEqual(rows.anchor, "alice")
    }

    func testActiveBecomesDefaultWithoutAnchor() {
        let rows = CopilotProvider.assign(logins: [
            GhLogin(login: "bob", active: false),
            GhLogin(login: "alice", active: true),
        ], anchor: nil)
        XCTAssertEqual(rows.accounts.map(\.login), ["alice", "bob"])
        XCTAssertEqual(rows.accounts.map(\.id), ["copilot:default", "copilot:bob"])
        XCTAssertEqual(rows.anchor, "alice")
    }

    func testLoginNamedDefaultDoesNotCollide() {
        let rows = CopilotProvider.assign(logins: [
            GhLogin(login: "alice", active: true),
            GhLogin(login: "default", active: false),
        ], anchor: "alice")
        XCTAssertEqual(rows.accounts.map(\.id), ["copilot:default", "copilot:login:default"])
    }
}

final class GeminiDiscoveryTests: XCTestCase {
    let home = "/Users/me"

    func testDefaultAndNestedCliHome() {
        let files: Set<String> = [
            home + "/.gemini/oauth_creds.json",
            home + "/.gemini-accounts/work/.gemini/oauth_creds.json",
            home + "/.gemini-school/oauth_creds.json",
        ]
        let dirs: Set<String> = [
            home + "/.gemini",
            home + "/.gemini-accounts/work",
            home + "/.gemini-accounts/work/.gemini",
            home + "/.gemini-school",
        ]
        let found = GeminiProvider.discover(
            home: home, cliHomeEnv: home + "/.gemini-accounts/work", extraDirs: ["~/other/gemini"],
            directoryNames: [".gemini", ".gemini-school", ".gemini-accounts"],
            accountHomes: [home + "/.gemini-accounts/work"],
            files: files, dirs: dirs)
        XCTAssertEqual(found.first?.id, "gemini:default")
        XCTAssertTrue(found.contains { $0.credsDir == home + "/.gemini-accounts/work/.gemini" && $0.fromEnv && $0.userListed })
        XCTAssertTrue(found.contains { $0.credsDir == home + "/.gemini-school" && !$0.isDefault })
        XCTAssertTrue(found.contains { $0.credsDir == home + "/other/gemini" && $0.userListed })
        XCTAssertEqual(Set(found.map(\.credsDir)).count, found.count)
    }

    func testCliHomeEqualToDefaultIsOneAccount() {
        let files: Set<String> = [home + "/.gemini/oauth_creds.json"]
        let dirs: Set<String> = [home + "/.gemini"]
        let found = GeminiProvider.discover(
            home: home, cliHomeEnv: home, extraDirs: [], directoryNames: [],
            accountHomes: [], files: files, dirs: dirs)
        XCTAssertEqual(found.map(\.id), ["gemini:default"])
        XCTAssertTrue(found[0].fromEnv)
    }
}

final class DisplayNameTests: XCTestCase {
    func testTitleOrder() {
        var a = AccountSnapshot(id: "codex:default", provider: "codex", name: "Codex", email: "a@b.c",
                                plan: nil, windows: [], updatedAt: Date())
        XCTAssertEqual(a.title, "a@b.c")
        XCTAssertEqual(a.detail, "Codex")
        a.label = "Work"
        XCTAssertEqual(a.title, "Work")
        XCTAssertTrue(a.detail.contains("a@b.c"))
        XCTAssertTrue(a.detail.contains("Codex"))
        a.label = "   "
        XCTAssertEqual(a.title, "a@b.c")
        a.email = " "
        a.label = nil
        XCTAssertEqual(a.title, "Codex")
    }

    func testHiddenFallback() {
        XCTAssertEqual(AccountNames.fallback("codex:default"), "Codex")
        XCTAssertEqual(AccountNames.fallback("codex:/Users/me/.codex-work"), "Codex · .codex-work")
        XCTAssertEqual(AccountNames.fallback("copilot:octocat"), "Copilot · octocat")
        XCTAssertEqual(AccountNames.fallback("gemini:/Users/me/.gemini-accounts/work/.gemini"), "Gemini · .gemini")
        XCTAssertEqual(AccountNames.fallback("cursor:default"), "Cursor")
    }
}

final class NtfyScheduleTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func account(_ id: String, _ key: String, used: Double, resetsIn: TimeInterval?, label: String = "5h session") -> AccountSnapshot {
        var a = AccountSnapshot(id: id, provider: "codex", name: "Codex", email: "a@b.c", plan: nil,
                                windows: [UsageWindow(key: key, label: label, utilization: used,
                                                      resetsAt: resetsIn.map { now.addingTimeInterval($0) })],
                                updatedAt: now)
        a.label = "Work"
        return a
    }

    func sink() -> Sink {
        Sink(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!, kind: .ntfy,
             values: ["server": "https://ntfy.sh", "topic": "refill-test", "token": "tk_secret"])
    }

    func testSchedulesUsedWindowInsideTheWindow() {
        let s = sink()
        let a = account("codex:default", "primary", used: 40, resetsIn: 2 * 3600)
        let found = NtfyScheduler.candidates(accounts: [a], sinks: [s], now: now, isQuiet: { _ in false })
        XCTAssertEqual(found.count, 1)
        let b = found[0].booking
        XCTAssertEqual(b.accountId, "codex:default")
        XCTAssertEqual(b.windowKey, "primary")
        XCTAssertEqual(b.deliverAt, a.windows[0].resetsAt!.addingTimeInterval(30))
        XCTAssertEqual(b.title, "Refilled")
        XCTAssertEqual(b.message, "Work: 5h session is full again.")
        XCTAssertEqual(b.messageId, NtfyScheduler.messageId(accountId: "codex:default", windowKey: "primary"))
        XCTAssertNotEqual(b.messageId, NtfyScheduler.messageId(accountId: "codex:default", windowKey: "secondary"))
    }

    func testSkipsUnusedFarAndQuiet() {
        let s = sink()
        let accounts = [
            account("codex:default", "primary", used: 0, resetsIn: 3600),
            account("codex:default", "secondary", used: 10, resetsIn: 4 * 24 * 3600),
            account("codex:other", "primary", used: 10, resetsIn: -30),
        ]
        XCTAssertTrue(NtfyScheduler.candidates(accounts: accounts, sinks: [s], now: now, isQuiet: { _ in false }).isEmpty)
        let soon = account("codex:default", "primary", used: 10, resetsIn: 3600)
        XCTAssertTrue(NtfyScheduler.candidates(accounts: [soon], sinks: [s], now: now, isQuiet: { _ in true }).isEmpty)
        var off = sink()
        off.onReset = false
        XCTAssertTrue(NtfyScheduler.candidates(accounts: [soon], sinks: [off], now: now, isQuiet: { _ in false }).isEmpty)
    }

    func testReplaceAndCancel() {
        let s = sink()
        let a = account("codex:default", "primary", used: 40, resetsIn: 2 * 3600)
        let first = NtfyScheduler.candidates(accounts: [a], sinks: [s], now: now, isQuiet: { _ in false })
        let same = NtfyScheduler.diff(desired: first, previous: first.map(\.booking), now: now)
        XCTAssertTrue(same.post.isEmpty)
        XCTAssertTrue(same.cancel.isEmpty)

        let moved = account("codex:default", "primary", used: 40, resetsIn: 5 * 3600)
        let next = NtfyScheduler.candidates(accounts: [moved], sinks: [s], now: now, isQuiet: { _ in false })
        let replaced = NtfyScheduler.diff(desired: next, previous: first.map(\.booking), now: now)
        XCTAssertEqual(replaced.post.count, 1)
        XCTAssertEqual(replaced.post[0].messageId, first[0].booking.messageId)
        XCTAssertTrue(replaced.cancel.isEmpty)

        let gone = NtfyScheduler.diff(desired: [], previous: first.map(\.booking), now: now)
        XCTAssertEqual(gone.cancel.count, 1)
        XCTAssertTrue(gone.post.isEmpty)
    }

    func testImminentBookingIsKept() {
        var booking = NtfyScheduler.candidates(
            accounts: [account("codex:default", "primary", used: 40, resetsIn: 3600)],
            sinks: [sink()], now: now, isQuiet: { _ in false })[0].booking
        booking.deliverAt = now.addingTimeInterval(20)
        let plan = NtfyScheduler.diff(desired: [], previous: [booking], now: now)
        XCTAssertTrue(plan.cancel.isEmpty)
        XCTAssertTrue(plan.keep.contains { $0.messageId == booking.messageId })
    }

    func testPublishUsesAtHeaderAndStablePath() throws {
        let s = sink()
        let b = NtfyScheduler.candidates(
            accounts: [account("codex:default", "primary", used: 12, resetsIn: 3600)],
            sinks: [s], now: now, isQuiet: { _ in false })[0].booking
        let req = try XCTUnwrap(NtfyScheduler.publishRequest(s, b))
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.url?.absoluteString, "https://ntfy.sh/refill-test/\(b.messageId)")
        XCTAssertEqual(req.value(forHTTPHeaderField: "At"), String(Int(b.deliverAt.timeIntervalSince1970)))
        XCTAssertEqual(req.value(forHTTPHeaderField: "Title"), "Refilled")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer tk_secret")
        XCTAssertEqual(String(data: req.httpBody!, encoding: .utf8), b.message)
        let cancel = try XCTUnwrap(NtfyScheduler.cancelRequest(b, sinks: [s]))
        XCTAssertEqual(cancel.httpMethod, "DELETE")
        XCTAssertEqual(cancel.url, req.url)
    }
}
