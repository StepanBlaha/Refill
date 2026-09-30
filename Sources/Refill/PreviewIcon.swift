import SwiftUI
import AppKit

/// `Refill --render-icon <path>`: renders the 1024x1024 app icon (Drip on ink squircle, lime glow), then exits.
/// Call `PreviewIcon.runIfRequested()` at the top of RefillApp.init().
@MainActor
enum PreviewIcon {
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render-icon") else { return }
        run(path: args.dropFirst(i + 1).first ?? "icon-1024.png")
    }

    static func run(path: String) {
        let r = ImageRenderer(content: IconView())
        r.scale = 1
        if let tiff = r.nsImage?.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
        }
        exit(0)
    }

    /// macOS icon grid: 824pt squircle centered in a 1024 canvas.
    struct IconView: View {
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 185, style: .continuous)
                    .fill(RadialGradient(colors: [Color(hex: 0x1B2010), Theme.ink], center: .center,
                                         startRadius: 20, endRadius: 520))
                    .overlay(RoundedRectangle(cornerRadius: 185, style: .continuous)
                        .strokeBorder(Theme.lime.opacity(0.25), lineWidth: 4))
                    .frame(width: 824, height: 824)
                Circle().fill(RadialGradient(colors: [Theme.lime.opacity(0.3), .clear], center: .center,
                                             startRadius: 0, endRadius: 320))
                    .frame(width: 640, height: 640)
                Drip(mood: .happy, size: 520)
            }            .frame(width: 1024, height: 1024)
        }
    }
}
