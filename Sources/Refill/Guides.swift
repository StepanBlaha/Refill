import Foundation

/// Links into the online setup guides (site/src/app/guides). Anchors match SinkKind raw values.
enum Guides {
    static let base = "https://stepanblaha.github.io/Refill/guides/"
    static func url(_ anchor: String) -> URL { URL(string: base + "#" + anchor)! }
}
