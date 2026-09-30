import SwiftUI
import AppKit

/// `Refill --render-icon <path>`: renders the 1024x1024 app icon (flat Drip on black squircle), then exits.
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
                RoundedRectangle(cornerRadius: 185, style: .continuous).fill(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 185, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 6))
                    .frame(width: 824, height: 824)
                Drip(mood: .happy, size: 560, level: 72)
            }            .frame(width: 1024, height: 1024)
        }
    }
}
