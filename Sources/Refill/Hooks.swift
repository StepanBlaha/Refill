import Foundation

/// Extension seams. Feature modules register here from AppBootstrap; Monitor calls them.
@MainActor
enum AppHooks {
    /// Every emitted event (after built-in signals ran).
    static var onEvent: [(RefillEvent) -> Void] = []
    /// After every refresh with the full account list.
    static var onRefresh: [([AccountSnapshot]) -> Void] = []
    /// Extra providers (Copilot, Cursor, Gemini…). Each returns zero or more snapshots.
    static var providers: [() async -> [AccountSnapshot]] = []
}
