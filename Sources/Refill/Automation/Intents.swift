import AppIntents
import Foundation

/// Set by the app at launch so intents can reach the running Monitor.
@MainActor
enum AutomationBridge {
    static weak var monitor: Monitor?
}

enum ProviderOption: String, AppEnum {
    case claude, codex, any
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Provider"
    static var caseDisplayRepresentations: [ProviderOption: DisplayRepresentation] = [
        .claude: "Claude", .codex: "Codex", .any: "Any"
    ]
    var key: String? { self == .any ? nil : rawValue }
}

enum WindowOption: String, AppEnum {
    case session, week
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Window"
    static var caseDisplayRepresentations: [WindowOption: DisplayRepresentation] = [
        .session: "Session (5h)", .week: "Week"
    ]
    var key: String { self == .session ? "five_hour" : "seven_day" }
}

struct GetRemainingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Remaining Usage"
    static var description = IntentDescription("Percent of your Claude or Codex limit that is left.")

    @Parameter(title: "Provider", default: .claude) var provider: ProviderOption
    @Parameter(title: "Window", default: .session) var window: WindowOption
    @Parameter(title: "Account email") var account: String?

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let left = StatusReader.remaining(provider: provider.key, window: window.key, account: account) ?? -1
        let text = StatusReader.summary(provider: provider.key, window: window.key, account: account)
        return .result(value: left, dialog: IntentDialog(stringLiteral: text))
    }
}

struct GetStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Refill Status"
    static var description = IntentDescription("Full status as JSON.")
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: StatusReader.rawJSON())
    }
}

struct NextRefillIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Refill Time"
    static var description = IntentDescription("When the next limit window resets.")
    @Parameter(title: "Provider", default: .any) var provider: ProviderOption

    func perform() async throws -> some IntentResult & ReturnsValue<Date> & ProvidesDialog {
        guard let d = StatusReader.nextRefill(provider: provider.key) else {
            throw $provider.needsValueError("No upcoming refill known. Is Refill running?")
        }
        return .result(value: d, dialog: "Next refill in \(shortDuration(d.timeIntervalSinceNow))")
    }
}

struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Usage"
    static var description = IntentDescription("Re-poll Claude and Codex usage now.")
    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let m = AutomationBridge.monitor else { return .result(dialog: "Refill isn't running.") }
        await m.refresh()
        return .result(dialog: "Refreshed.")
    }
}

struct TestSignalIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Test Signal"
    static var description = IntentDescription("Fire a test refill signal to all enabled integrations.")
    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let m = AutomationBridge.monitor else { return .result(dialog: "Refill isn't running.") }
        m.sendTest()
        return .result(dialog: "Test signal sent.")
    }
}

struct RefillShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GetRemainingIntent(),
                    phrases: ["How much Claude is left in \(.applicationName)",
                              "How much usage is left in \(.applicationName)"],
                    shortTitle: "Usage Left", systemImageName: "gauge.with.dots.needle.67percent")
        AppShortcut(intent: NextRefillIntent(),
                    phrases: ["When does \(.applicationName) refill", "Next refill in \(.applicationName)"],
                    shortTitle: "Next Refill", systemImageName: "clock.arrow.circlepath")
        AppShortcut(intent: RefreshIntent(),
                    phrases: ["Refresh \(.applicationName)"],
                    shortTitle: "Refresh", systemImageName: "arrow.clockwise")
        AppShortcut(intent: TestSignalIntent(),
                    phrases: ["Test \(.applicationName) signal"],
                    shortTitle: "Test Signal", systemImageName: "bolt")
    }
}
