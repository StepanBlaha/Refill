import SwiftUI

// Copy of Sources/Refill/Theme.swift without the AppKit TankIcon (iOS target).
extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

/// Brink-style tokens: pure black surface, white text, one green accent. No glow.
enum Theme {
    static let ink = Color.black
    static let panel = Color(hex: 0x1C1C1E)
    static let raised = Color(hex: 0x2C2C2E)
    static let line = Color.white.opacity(0.1)
    static let text = Color.white
    static let muted = Color(hex: 0x808080)
    static let tertiary = Color.white.opacity(0.32)
    static let hover = Color.white.opacity(0.16)
    /// The accent. Historical name kept so feature modules compile unchanged.
    static let lime = Color(hex: 0x30D158)
    static let accent = lime
    static let amber = Color(hex: 0xFF9F0A)
    static let coral = Color(hex: 0xFF453A)

    static let radius: CGFloat = 4
    static let panelRadius: CGFloat = 8

    static func level(used: Double) -> Color { used >= 90 ? coral : used >= 70 ? amber : lime }

    static func color(_ k: EventKind) -> Color {
        switch k { case .reset, .test: return lime; case .warning: return amber; case .empty: return coral }
    }

    /// SF Pro, like Brink. (Name kept for existing call sites.)
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight == .heavy || weight == .black ? .semibold : weight)
    }

    /// SF Pro with tabular digits.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight == .bold ? .semibold : weight).monospacedDigit()
    }

    static var unfold: Animation { .spring(response: 0.62, dampingFraction: 0.72) }
    static var contents: Animation { .spring(response: 0.48, dampingFraction: 0.8) }
}
