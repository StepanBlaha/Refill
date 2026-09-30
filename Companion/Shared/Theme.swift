import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

enum Theme {
    static let ink = Color(hex: 0x0D0E11)
    static let panel = Color(hex: 0x16181D)
    static let line = Color(hex: 0x262A31)
    static let text = Color(hex: 0xF3F1EA)
    static let muted = Color(hex: 0x8B8F98)
    static let lime = Color(hex: 0xC8FF4D)
    static let amber = Color(hex: 0xFFB547)
    static let coral = Color(hex: 0xFF6B5B)

    static func level(used: Double) -> Color { used >= 90 ? coral : used >= 70 ? amber : lime }

    static func color(_ k: EventKind) -> Color {
        switch k { case .reset, .test: return lime; case .warning: return amber; case .empty: return coral }
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

