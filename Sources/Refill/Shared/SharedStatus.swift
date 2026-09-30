import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// App <-> widget bridge. The app writes a JSON snapshot into the app-group container; widgets read it.
/// Compiled into both the Refill app target and the RefillWidgets extension.
struct SharedPayload: Codable {
    var accounts: [AccountSnapshot]
    var lastEvent: RefillEvent?
    var writtenAt: Date
}

enum SharedStatus {
    static let group = "FW5CYB98R7.cz.stepanblaha.refill"
    static let fileName = "widget-status.json"

    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent(fileName)
    }

    /// Call from the app whenever accounts refresh or an event fires.
    static func write(_ accounts: [AccountSnapshot], lastEvent: RefillEvent?) {
        guard let url = fileURL else { return }
        let payload = SharedPayload(accounts: accounts, lastEvent: lastEvent, writtenAt: Date())
        if let data = try? JSONEncoder.refill.encode(payload) {
            try? data.write(to: url, options: .atomic)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func read() -> SharedPayload? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.refill.decode(SharedPayload.self, from: data)
    }
}
