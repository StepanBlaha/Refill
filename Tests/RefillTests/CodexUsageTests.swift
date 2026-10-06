import XCTest
@testable import Refill

/// Codex session logs store `used_percent` as the share already consumed.
/// The menu, dashboard, widgets and notifications show percent left as `100 - utilization`.
final class CodexUsageTests: XCTestCase {
    /// Fixed clock for the samples. Assertions compare against this, not `Date()`.
    let now = Date(timeIntervalSince1970: 1_791_331_200)

    func testOfficialRolloutSampleIsConsumedNotRemaining() throws {
        let line = #"{"timestamp":"2025-01-03T12:00:00.000Z","ordinal":7,"type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":null,"limit_name":null,"primary":{"used_percent":0.0,"window_minutes":60,"resets_at":1800000000},"secondary":{"used_percent":12.5,"window_minutes":10080,"resets_at":1800100000},"credits":null,"individual_limit":null,"spend_control_reached":null,"plan_type":null,"rate_limit_reached_type":null}}}"#
        let snap = try fetch(files: [("rollout-official.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 12.5, accuracy: 0.001)
        XCTAssertEqual(100 - week.utilization, 87.5, accuracy: 0.001)
        let session = try XCTUnwrap(snap.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.utilization, 0, accuracy: 0.001)
    }

    func testWeeklyCapStaysUsedWhenResetTimeIsPast() throws {
        // 1600000000 is 2020-09-13. 2000000000 is 2033-05-18. Both stay on the
        // intended side of the clock the test compares against.
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","plan_type":"plus","primary":{"used_percent":40.0,"window_minutes":300,"resets_at":2000000000},"secondary":{"used_percent":100.0,"window_minutes":10080,"resets_at":1600000000}}}}"#
        let snap = try fetch(files: [("rollout-capped.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertEqual(100 - week.utilization, 0, accuracy: 0.001)
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
        XCTAssertLessThan(try XCTUnwrap(week.resetsAt), now)
        let session = try XCTUnwrap(snap.windows.first { $0.key == "primary" })
        XCTAssertEqual(session.label, "5h session")
        XCTAssertEqual(session.utilization, 40, accuracy: 0.001)
        XCTAssertEqual(100 - session.utilization, 60, accuracy: 0.001)
        XCTAssertEqual(session.resetsAt, Date(timeIntervalSince1970: 2_000_000_000))
        XCTAssertGreaterThan(try XCTUnwrap(session.resetsAt), now)
        XCTAssertEqual(snap.plan, "plus")
    }

    func testNegativeResetDelayDoesNotRefillTheWeek() throws {
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":100,"window_minutes":10080,"resets_in_seconds":-30}}}}"#
        let snap = try fetch(files: [("rollout-delay.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertEqual(100 - week.utilization, 0, accuracy: 0.001)
        XCTAssertLessThan(try XCTUnwrap(week.resetsAt), now)
    }

    func testPlanLimitWinsOverANewerModelBucket() throws {
        let plan = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","primary":{"used_percent":40.0,"window_minutes":300,"resets_at":1800000000},"secondary":{"used_percent":100.0,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let model = #"{"timestamp":"2026-10-05T12:05:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex_other","primary":{"used_percent":5.0,"window_minutes":300,"resets_at":1800000000},"secondary":{"used_percent":0.0,"window_minutes":10080,"resets_at":1800100000}}}}"#
        let snap = try fetch(files: [("rollout-mixed.jsonl", plan + "\n" + model, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertEqual(100 - week.utilization, 0, accuracy: 0.001)
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
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
    }

    func testOpenAPIWindowFields() throws {
        let line = #"{"timestamp":"2026-10-05T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":null,"rate_limits":{"limit_id":"codex","secondary":{"used_percent":100,"limit_window_seconds":604800,"reset_at":1600000000000,"reset_after_seconds":999}}}}"#
        let snap = try fetch(files: [("rollout-openapi.jsonl", line, now)])
        let week = try XCTUnwrap(snap.windows.first { $0.key == "secondary" })
        XCTAssertEqual(week.label, "Week")
        XCTAssertEqual(week.utilization, 100, accuracy: 0.001)
        XCTAssertEqual(week.resetsAt, Date(timeIntervalSince1970: 1_600_000_000))
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
        return CodexProvider.fetch(home)
    }
}
