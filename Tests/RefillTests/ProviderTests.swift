import XCTest
@testable import Refill

final class ProviderTests: XCTestCase {
    func testCopilotParse() throws {
        let json = """
        {"copilot_plan":"individual_pro","quota_reset_date":"2026-10-01",
         "quota_snapshots":{
          "premium_interactions":{"percent_remaining":75.5,"unlimited":false},
          "chat":{"percent_remaining":100,"unlimited":true},
          "completions":{"percent_remaining":40,"unlimited":false}}}
        """
        let s = try XCTUnwrap(CopilotProvider.parse(Data(json.utf8)))
        XCTAssertEqual(s.plan, "individual_pro")
        XCTAssertEqual(s.windows.map(\.label), ["Premium requests", "Completions"])
        XCTAssertEqual(s.windows[0].utilization, 24.5, accuracy: 0.001)
        XCTAssertEqual(s.windows[1].utilization, 60, accuracy: 0.001)
        XCTAssertNotNil(s.windows[0].resetsAt)
        XCTAssertNil(s.error)
    }

    func testCopilotTokenFromConfig() {
        let d = Data(#"{"github.com:Iv1.abc":{"user":"x","oauth_token":"tok123"}}"#.utf8)
        XCTAssertEqual(CopilotProvider.token(fromConfig: d), "tok123")
    }

    func testCursorParse() throws {
        let json = """
        {"billingCycleStart":"2026-09-01T00:00:00.000Z","billingCycleEnd":"2026-10-01T00:00:00.000Z",
         "membershipType":"pro",
         "individualUsage":{"plan":{"used":1000,"limit":2000,"autoPercentUsed":10,"apiPercentUsed":30,"totalPercentUsed":20},
                            "onDemand":{"used":50,"limit":1000}}}
        """
        let s = try XCTUnwrap(CursorProvider.parse(Data(json.utf8)))
        XCTAssertEqual(s.plan, "pro")
        XCTAssertEqual(s.windows.map(\.key), ["monthly", "auto", "api", "on_demand"])
        XCTAssertEqual(s.windows[0].utilization, 20)
        XCTAssertEqual(s.windows[3].utilization, 5)
        XCTAssertNotNil(s.windows[0].resetsAt)
    }

    func testCursorFallbackToRatio() throws {
        let json = #"{"individualUsage":{"plan":{"used":500,"limit":2000}}}"#
        let s = try XCTUnwrap(CursorProvider.parse(Data(json.utf8)))
        XCTAssertEqual(s.windows.first?.utilization, 25)
    }

    func testCursorCookie() {
        func b64(_ s: String) -> String {
            Data(s.utf8).base64EncodedString().replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        }
        let jwt = "\(b64("{}")).\(b64(#"{"sub":"auth0|User_ABC"}"#)).sig"
        XCTAssertEqual(CursorProvider.cookieHeader(accessToken: jwt),
                       "WorkosCursorSessionToken=user_abc%3A%3A\(jwt)")
        XCTAssertNil(CursorProvider.cookieHeader(accessToken: "garbage"))
    }

    func testGeminiQuotaGroupsByFamily() throws {
        let json = """
        {"buckets":[
         {"modelId":"gemini-2.5-pro","remainingFraction":0.75,"resetTime":"2026-10-01T10:00:00Z","tokenType":"REQUESTS"},
         {"modelId":"gemini-2.5-flash","remainingFraction":0.9,"resetTime":"2026-10-01T10:00:00Z"},
         {"modelId":"gemini-2.5-flash-lite","remainingFraction":1.0,"resetTime":"2026-10-01T10:00:00Z"},
         {"modelId":"gemini-3-pro-preview","remainingFraction":0.5,"resetTime":"2026-10-01T11:00:00Z"}]}
        """
        let s = try XCTUnwrap(GeminiProvider.parseQuota(Data(json.utf8)))
        XCTAssertEqual(s.windows.map(\.label), ["Pro", "Flash", "Flash Lite"])
        XCTAssertEqual(s.windows[0].utilization, 50, accuracy: 0.001)
        XCTAssertEqual(s.windows[1].utilization, 10, accuracy: 0.001)
        XCTAssertEqual(s.windows[2].utilization, 0, accuracy: 0.001)
    }

    func testGeminiLoadAndClientExtraction() throws {
        let load = #"{"cloudaicompanionProject":"proj-1","currentTier":{"id":"free-tier","name":"Gemini Code Assist"}}"#
        let info = try XCTUnwrap(GeminiProvider.parseLoad(Data(load.utf8)))
        XCTAssertEqual(info.project, "proj-1")
        XCTAssertEqual(info.plan, "Gemini Code Assist")
        let js = "const OAUTH_CLIENT_ID = 'abc-123.apps.example.com';\nconst OAUTH_CLIENT_SECRET = 'S3cret_-x';"
        let c = try XCTUnwrap(GeminiProvider.extractClient(from: js))
        XCTAssertEqual(c.0, "abc-123.apps.example.com")
        XCTAssertEqual(c.1, "S3cret_-x")
    }
}
