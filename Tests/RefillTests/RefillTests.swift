import XCTest
@testable import Refill

final class ResetDetectorTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func w(_ u: Double, _ resetIn: TimeInterval?, key: String = "five_hour") -> UsageWindow {
        UsageWindow(key: key, label: "5h", utilization: u, resetsAt: resetIn.map { now.addingTimeInterval($0) })
    }

    func testObservedResetWhenResetTimeJumpsAndUsageDrops() {
        let r = ResetDetector.observedResets(old: [w(80, -60)], new: [w(3, 5 * 3600)], now: now)
        XCTAssertEqual(r.count, 1)
    }

    func testNoResetOnJitter() {
        // resets_at moved by a few seconds, usage grew: same window.
        XCTAssertTrue(ResetDetector.observedResets(old: [w(40, 3600)], new: [w(42, 3605)], now: now).isEmpty)
    }

    func testNoResetForUnusedWindow() {
        XCTAssertTrue(ResetDetector.observedResets(old: [w(0, -60)], new: [w(0, 3600)], now: now).isEmpty)
    }

    func testResetWhenNewWindowHasNoResetYet() {
        // After a reset the 5h window has no resets_at until first use.
        XCTAssertEqual(ResetDetector.observedResets(old: [w(90, -30)], new: [w(0, nil)], now: now).count, 1)
    }

    func testScheduled() {
        XCTAssertEqual(ResetDetector.scheduledResets([w(50, -1), w(50, 60), w(0, -1), w(10, nil)], now: now).count, 1)
    }

    func testCrossingsIncludeEmptyAndOnlyUpward() {
        let c = ResetDetector.crossings(old: [w(70, 60)], new: [w(100, 60)], thresholds: [80, 95])
        XCTAssertEqual(c.map(\.threshold), [80, 95, 100])
        XCTAssertTrue(ResetDetector.crossings(old: [w(96, 60)], new: [w(10, 60)], thresholds: [80, 95]).isEmpty)
        XCTAssertTrue(ResetDetector.crossings(old: [], new: [w(99, 60)], thresholds: [80]).isEmpty, "no alert on first sight")
    }

    func testDedupeKeyBucketsJitter() {
        let a = ResetDetector.key(accountId: "a", window: w(1, 100), kind: .reset)
        let b = ResetDetector.key(accountId: "a", window: w(1, 103), kind: .reset)
        XCTAssertNotNil(a); XCTAssertEqual(a, b)
        XCTAssertNil(ResetDetector.key(accountId: "a", window: w(1, nil), kind: .reset))
    }

    func testQuietHoursAcrossMidnight() {
        XCTAssertTrue(ResetDetector.isQuiet(hour: 23, from: 22, to: 8))
        XCTAssertTrue(ResetDetector.isQuiet(hour: 3, from: 22, to: 8))
        XCTAssertFalse(ResetDetector.isQuiet(hour: 12, from: 22, to: 8))
        XCTAssertTrue(ResetDetector.isQuiet(hour: 14, from: 13, to: 15))
    }
}

final class ParsingTests: XCTestCase {
    func testClaudeUsageParsing() throws {
        let json = """
        {"five_hour":{"utilization":12.0,"resets_at":"2026-09-29T20:20:00.123+00:00"},
         "seven_day":{"utilization":70,"resets_at":"2026-10-01T08:00:00Z"},
         "seven_day_opus":null,
         "nimbus_quill":{"utilization":0,"resets_at":null},
         "extra_usage":{"is_enabled":false}}
        """
        let ws = try ClaudeProvider.parseUsage(Data(json.utf8))
        XCTAssertEqual(ws.map(\.key), ["five_hour", "seven_day"])
        XCTAssertEqual(ws[0].utilization, 12)
        XCTAssertNotNil(ws[0].resetsAt)
        XCTAssertEqual(ws[1].label, "Week")
    }

    func testISODates() {
        XCTAssertNotNil(parseISODate("2026-09-29T20:20:00Z"))
        XCTAssertNotNil(parseISODate("2026-09-29T20:20:00.5+02:00"))
        XCTAssertNil(parseISODate("nope"))
    }

    func testCodexLabels() {
        XCTAssertEqual(CodexProvider.label(300), "5h session")
        XCTAssertEqual(CodexProvider.label(10080), "Week")
        XCTAssertEqual(CodexProvider.label(2880), "2d")
    }
}

final class IntegrationTests: XCTestCase {
    let e = RefillEvent(kind: .reset, provider: "claude", accountId: "a", accountName: "me@x.cz", window: "five_hour",
                        windowLabel: "5h session", utilization: 90, resetsAt: nil, detectedAt: Date(),
                        reason: "test", title: "Refilled", message: "5h is fresh")

    func testWebhookTemplate() throws {
        let s = Sink(kind: .webhook, values: ["url": "https://example.com/h", "headers": "X-Key: 1",
                                              "body": #"{"c":"{{color}}","m":"{{message}}","r":{{r}}}"#])
        let req = try XCTUnwrap(try Integrations.request(s, e))
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "X-Key"), "1")
        XCTAssertEqual(String(data: req.httpBody!, encoding: .utf8), ##"{"c":"#C8FF4D","m":"5h is fresh","r":200}"##)
    }

    func testNtfyUsesJSONPublish() throws {
        let s = Sink(kind: .ntfy, values: ["topic": "refill-abc"])
        let req = try XCTUnwrap(try Integrations.request(s, e))
        XCTAssertEqual(req.url?.absoluteString, "https://ntfy.sh")
        let body = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
        XCTAssertEqual(body["topic"] as? String, "refill-abc")
        XCTAssertEqual(body["title"] as? String, "Refilled")
    }

    func testMissingFieldsReturnNil() throws {
        XCTAssertNil(try Integrations.request(Sink(kind: .telegram), e))
        XCTAssertNil(try Integrations.request(Sink(kind: .hue, values: ["bridge": "1.2.3.4"]), e))
    }

    func testHueUsesGroupAction() throws {
        let s = Sink(kind: .hue, values: ["bridge": "10.0.0.2", "user": "u", "group": "3"])
        let req = try XCTUnwrap(try Integrations.request(s, e))
        XCTAssertEqual(req.httpMethod, "PUT")
        XCTAssertEqual(req.url?.absoluteString, "http://10.0.0.2/api/u/groups/3/action")
    }

    func testQuietMutesOnlyPush() {
        XCTAssertTrue(Integrations.pushKinds.contains(.ntfy))
        XCTAssertFalse(Integrations.pushKinds.contains(.hue))
        XCTAssertFalse(Integrations.pushKinds.contains(.homeAssistant))
    }
}
