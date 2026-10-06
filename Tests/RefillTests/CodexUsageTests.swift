import XCTest
import CryptoKit
@testable import Refill

/// Codex `used_percent` is the share already consumed.
/// A live reading shows percent left as `100 - utilization`.
/// A session log whose reset time has already passed is stale: percent left is nil.
final class CodexUsageTests: XCTestCase {
    /// Fixed clock for the samples. Assertions compare against this, not `Date()`.
    let now = Date(timeIntervalSince1970: 1_791_331_200)

    func testOfficialRolloutSampleIsConsumedNotRemaining() throws {
        let line = #"{"timestamp":"2025-01-03T12:00:00.000Z","ordinal":7,"type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":null,"limit_name":null,"primary":{"used_percent":0.0,"window_minutes":60,"resets_at":1800000000},"secondary":{"used_percent":12.5,"window_minutes":10080,"resets_at":1800100000},"credits":null,"individual_limit":null,"spend_control_reached":null,"plan_type":null,"rate_limit_reached_type":null}}}"#
        let snap = try fetch(files: [("rollout-official.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 12.5, accuracy: 0.001)
        XCTAssertFalse(week.stale)
        XCTAssertEqual(week.percentLeft!, 87.5, accuracy: 0.001)
        let session = try XCTUnwrap(snap.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.utilization, 0, accuracy: 0.001)
        XCTAssertFalse(session.stale)
        XCTAssertEqual(session.percentLeft!, 100, accuracy: 0.001)
    }

    func testWeeklyCapStaysUsedWhenResetTimeIsPast() throws {
        // 1600000000 is 2020-09-13. 2000000000 is 2033-05-18. Both stay on the
        // intended side of the clock the test compares against.
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","plan_type":"plus","primary":{"used_percent":40.0,"window_minutes":300,"resets_at":2000000000},"secondary":{"used_percent":100.0,"window_minutes":10080,"resets_at":1600000000}}}}"#
        let snap = try fetch(files: [("rollout-capped.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertTrue(week.stale)
        XCTAssertNil(week.percentLeft)
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
        XCTAssertLessThan(try XCTUnwrap(week.resetsAt), now)
        let session = try XCTUnwrap(snap.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.label, "5h session")
        XCTAssertEqual(session.utilization, 40, accuracy: 0.001)
        XCTAssertFalse(session.stale)
        XCTAssertEqual(session.percentLeft!, 60, accuracy: 0.001)
        XCTAssertEqual(session.resetsAt, Date(timeIntervalSince1970: 2_000_000_000))
        XCTAssertGreaterThan(try XCTUnwrap(session.resetsAt), now)
        XCTAssertEqual(snap.plan, "plus")
    }

    func testNegativeResetDelayDoesNotRefillTheWeek() throws {
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":100,"window_minutes":10080,"resets_in_seconds":-30}}}}"#
        let snap = try fetch(files: [("rollout-delay.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertTrue(week.stale)
        XCTAssertNil(week.percentLeft)
        XCTAssertLessThan(try XCTUnwrap(week.resetsAt), now)
    }

    func testPlanLimitWinsOverANewerModelBucket() throws {
        let plan = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","primary":{"used_percent":40.0,"window_minutes":300,"resets_at":1800000000},"secondary":{"used_percent":100.0,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let model = #"{"timestamp":"2026-10-05T12:05:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex_other","primary":{"used_percent":5.0,"window_minutes":300,"resets_at":1800000000},"secondary":{"used_percent":0.0,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let snap = try fetch(files: [("rollout-mixed.jsonl", plan + "\n" + model, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertFalse(week.stale)
        XCTAssertEqual(week.percentLeft!, 0, accuracy: 0.001)
        let session = try XCTUnwrap(snap.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.utilization, 40, accuracy: 0.001)
    }

    func testNewestPlanLineStillWins() throws {
        let earlier = #"{"timestamp":"2026-10-05T11:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":10,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let later = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":80,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let snap = try fetch(files: [("rollout-plan.jsonl", earlier + "\n" + later, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 80, accuracy: 0.001)
    }

    func testNewestRolloutFileWins() throws {
        let stale = #"{"timestamp":"2026-10-01T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":0,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let fresh = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":100,"window_minutes":10080,"resets_at":1600000000}}}}"#
        let snap = try fetch(files: [
            ("rollout-old.jsonl", stale, now.addingTimeInterval(-86_400)),
            ("rollout-new.jsonl", fresh, now),
        ])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertTrue(week.stale)
        XCTAssertNil(week.percentLeft)
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
    }

    func testOpenAPIWindowFields() throws {
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":100,"limit_window_seconds":604800,"reset_at":1600000000000,"reset_after_seconds":999}}}}"#
        let snap = try fetch(files: [("rollout-openapi.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertTrue(week.stale)
        XCTAssertNil(week.percentLeft)
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
    }

    /// The owner's 12-day-old rollout: week used 5%, both resets already past.
    /// That must not draw as 95% left or as a full tank.
    func testOwnerSeptemberLogIsStale() throws {
        let line = #"{"timestamp":"2026-09-24T09:58:56Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","plan_type":null,"primary":{"used_percent":31,"window_minutes":300,"resets_at":1790260549},"secondary":{"used_percent":5,"window_minutes":10080,"resets_at":1790847349}}}}"#
        let snap = try fetch(files: [("rollout-2026-09-24T09-58-56-owner.jsonl", line, now.addingTimeInterval(-12 * 86400))])
        let seen = parseISODate("2026-09-24T09:58:56Z")
        for key in ["primary", "secondary"] {
            let window = try XCTUnwrap(snap.windows.first { $0.key == key })
            XCTAssertTrue(window.stale, key)
            XCTAssertNil(window.percentLeft, key)
            XCTAssertEqual(window.observedAt, seen)
        }
        XCTAssertEqual(snap.windows.first { $0.key == "secondary" }?.utilization, 5, accuracy: 0.001)
        XCTAssertEqual(snap.windows.first { $0.key == "primary" }?.utilization, 31, accuracy: 0.001)
        XCTAssertNil(snap.plan)
    }

    func testPastResetAtZeroUsedIsNotAFullTank() throws {
        let line = #"{"timestamp":"2026-09-24T09:58:56Z","type":"event_msg","payload":{"type":"token_count","rate_limits":{"limit_id":"codex","secondary":{"used_percent":0,"window_minutes":10080,"resets_at":1790847349}}}}"#
        let snap = try fetch(files: [("rollout-empty-past.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 0, accuracy: 0.001)
        XCTAssertTrue(week.stale)
        XCTAssertNil(week.percentLeft)
    }

    func testLiveUsageShowsAnEmptyWeekAsZeroLeft() throws {
        let json = """
        {"plan_type":"plus","rate_limit":{"allowed":true,"limit_reached":true,"primary_window":{"used_percent":31,"limit_window_seconds":18000,"reset_after_seconds":1000,"reset_at":2000000000},"secondary_window":{"used_percent":100,"limit_window_seconds":604800,"reset_after_seconds":2000,"reset_at":2000003600}},"credits":{"has_credits":false,"balance":"0"},"additional_rate_limits":[{"limit_name":"codex_other","metered_feature":"codex_other","rate_limit":{"primary_window":{"used_percent":0,"limit_window_seconds":18000,"reset_at":2000000000,"reset_after_seconds":1}}}]}
        """
        let parsed = try CodexProvider.parseUsageResponse(Data(json.utf8), now: now)
        XCTAssertEqual(parsed.plan, "plus")
        XCTAssertEqual(parsed.windows.count, 2)
        let week = try XCTUnwrap(parsed.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertEqual(week.percentLeft!, 0, accuracy: 0.001)
        XCTAssertFalse(week.stale)
        let session = try XCTUnwrap(parsed.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.label, "5h session")
        XCTAssertEqual(session.utilization, 31, accuracy: 0.001)
        XCTAssertEqual(session.percentLeft!, 69, accuracy: 0.001)
        XCTAssertFalse(session.stale)
    }

    func testWrappedUsageIgnoresModelBuckets() throws {
        let json = """
        {"rate_limits":{"plan_type":"pro","rate_limit":{"primary_window":{"used_percent":10,"limit_window_seconds":18000,"reset_at":2000000000,"reset_after_seconds":1}}},"additional_rate_limits":[{"rate_limit":{"primary_window":{"used_percent":0,"limit_window_seconds":18000,"reset_at":2000000000,"reset_after_seconds":1}}}]}
        """
        let parsed = try CodexProvider.parseUsageResponse(Data(json.utf8), now: now)
        XCTAssertEqual(parsed.plan, "pro")
        XCTAssertEqual(parsed.windows.count, 1)
        XCTAssertEqual(parsed.windows[0].utilization, 10, accuracy: 0.001)
        XCTAssertEqual(parsed.windows[0].percentLeft!, 90, accuracy: 0.001)
    }

    func testPrimaryWindowCanBeTheWeek() throws {
        let json = #"{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":100,"limit_window_seconds":604800,"reset_at":2000000000,"reset_after_seconds":1},"secondary_window":null}}"#
        let parsed = try CodexProvider.parseUsageResponse(Data(json.utf8), now: now)
        XCTAssertEqual(parsed.windows.count, 1)
        XCTAssertEqual(parsed.windows[0].key, "primary")
        XCTAssertEqual(parsed.windows[0].label, "Week")
        XCTAssertEqual(parsed.windows[0].percentLeft!, 0, accuracy: 0.001)
        XCTAssertFalse(parsed.windows[0].stale)
    }

    func testLiveZeroUsedWithPastResetIsAFullTank() throws {
        let json = #"{"plan_type":"plus","rate_limit":{"primary_window":{"used_percent":0,"limit_window_seconds":18000,"reset_after_seconds":0,"reset_at":1600000000}}}"#
        let parsed = try CodexProvider.parseUsageResponse(Data(json.utf8), now: now)
        let session = try XCTUnwrap(parsed.windows.first)
        XCTAssertFalse(session.stale)
        XCTAssertEqual(session.percentLeft!, 100, accuracy: 0.001)
    }

    func testApplyRefreshKeepsUnknownKeysAndClaimShapedIdToken() throws {
        let raw: [String: Any] = [
            "auth_mode": "chatgpt",
            "OPENAI_API_KEY": NSNull(),
            "agent_identity": ["kept": true],
            "tokens": [
                "id_token": ["email": "kept@example.com"],
                "access_token": "old-access",
                "refresh_token": "old-refresh",
                "account_id": "acct_1",
            ],
        ]
        let response = [
            "access_token": "new-access",
            "refresh_token": "new-refresh",
            "id_token": "should-not-replace-claims",
        ]
        let updated = CodexProvider.applyRefresh(raw, response: response, now: now)
        XCTAssertEqual(updated["auth_mode"] as? String, "chatgpt")
        XCTAssertNotNil(updated["OPENAI_API_KEY"])
        XCTAssertNotNil(updated["agent_identity"])
        let tokens = try XCTUnwrap(updated["tokens"] as? [String: Any])
        XCTAssertEqual(tokens["access_token"] as? String, "new-access")
        XCTAssertEqual(tokens["refresh_token"] as? String, "new-refresh")
        XCTAssertEqual(tokens["account_id"] as? String, "acct_1")
        XCTAssertEqual((tokens["id_token"] as? [String: Any])?["email"] as? String, "kept@example.com")
        XCTAssertEqual(updated["last_refresh"] as? String, "2026-10-07T00:00:00Z")
    }

    func testApplyRefreshReplacesStringIdToken() {
        let raw: [String: Any] = ["tokens": ["id_token": "old", "access_token": "a", "refresh_token": "r"]]
        let updated = CodexProvider.applyRefresh(raw, response: ["access_token": "b", "id_token": "new"], now: now)
        let tokens = updated["tokens"] as? [String: Any]
        XCTAssertEqual(tokens?["id_token"] as? String, "new")
        XCTAssertEqual(tokens?["refresh_token"] as? String, "r")
    }

    func testAccessTokenExpiryAndAccountId() {
        let future = jwt(["exp": now.addingTimeInterval(3600).timeIntervalSince1970,
                          "https://api.openai.com/auth": ["chatgpt_account_id": "from-jwt", "chatgpt_account_is_fedramp": true],
                          "https://api.openai.com/profile": ["email": "ada@example.com"]])
        XCTAssertFalse(CodexProvider.accessTokenExpired(future, now: now))
        let past = jwt(["exp": now.addingTimeInterval(-10).timeIntervalSince1970])
        XCTAssertTrue(CodexProvider.accessTokenExpired(past, now: now))
        XCTAssertFalse(CodexProvider.accessTokenExpired("not-a-jwt", now: now))
        let who = CodexProvider.identity(accessToken: future, tokens: ["account_id": "from-file"])
        XCTAssertEqual(who.accountId, "from-file")
        XCTAssertEqual(who.email, "ada@example.com")
        XCTAssertTrue(who.fedramp)
        let fromJWT = CodexProvider.identity(accessToken: future, tokens: [:])
        XCTAssertEqual(fromJWT.accountId, "from-jwt")
    }

    func testStoreKeyMatchesCodexShape() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("refill-codex-key-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let key = CodexProvider.storeKey(path: root.path)
        let canonical = root.resolvingSymlinksInPath().path
        let digest = SHA256.hash(data: Data(canonical.utf8))
        let hex = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(key, "cli|" + hex)
        XCTAssertEqual(key.count, 4 + 16)
    }

    func testSavedWindowWithoutStaleStillDecodes() throws {
        let json = #"{"key":"primary","label":"5h session","utilization":31,"resetsAt":"2033-05-18T03:33:20Z"}"#
        let window = try JSONDecoder.refill.decode(UsageWindow.self, from: Data(json.utf8))
        XCTAssertFalse(window.stale)
        XCTAssertNil(window.observedAt)
        XCTAssertEqual(window.percentLeft!, 69, accuracy: 0.001)
    }

    private func jwt(_ payload: [String: Any]) -> String {
        func part(_ obj: [String: Any]) -> String {
            let data = try! JSONSerialization.data(withJSONObject: obj)
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return part(["alg": "none"]) + "." + part(payload) + ".sig"
    }

    private func fetch(files: [(String, String, Date)]) throws -> AccountSnapshot {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("refill-codex-\(UUID().uuidString)", isDirectory: true)
        let sessions = root.appendingPathComponent("sessions/2026/10/06", isDirectory: true)
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        for (name, body, mtime) in files {
            let url = sessions.appendingPathComponent(name)
            try body.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.modificationDate: mtime], ofItemAtPath: url.path)
        }
        let home = CodexHome(path: root.path, isDefault: true, fromEnv: false, userListed: false)
        return CodexProvider.snapshotFromLogs(home, now: now)
    }
}
