import SwiftUI
import AppKit

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
