import SwiftUI
import AppKit

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

/// Menu bar glyph: a tiny tank whose liquid level = lowest remaining 5h window.
enum TankIcon {
    static func image(remaining: Double?) -> NSImage {
        let size = NSSize(width: 12, height: 16)
        let img = NSImage(size: size, flipped: false) { _ in
            let body = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: 10, height: 13), xRadius: 3, yRadius: 3)
            body.lineWidth = 1.4
            NSColor.black.setStroke()
            body.stroke()
            NSBezierPath(roundedRect: NSRect(x: 4, y: 14, width: 4, height: 1.8), xRadius: 0.8, yRadius: 0.8).fill()
            let level = CGFloat(max(0, min(100, remaining ?? 100)) / 100)
            if level > 0 {
                NSGraphicsContext.saveGraphicsState()
                body.addClip()
                NSColor.black.setFill()
                NSRect(x: 1, y: 1, width: 10, height: max(1.5, 13 * level)).fill()
                NSGraphicsContext.restoreGraphicsState()
            }
            return true
        }
        img.isTemplate = true
        return img
    }
}
