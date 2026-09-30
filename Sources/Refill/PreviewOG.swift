import SwiftUI
import AppKit

/// `Refill --render-og <path>`: 1200x630 social banner (flat, Brink style), then exits.
@MainActor
enum PreviewOG {
    static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render-og") else { return }
        let m = Monitor(preview: PreviewRender.sampleAccounts())
        let r = ImageRenderer(content: Banner().environmentObject(m).environment(\.colorScheme, .dark))
        r.scale = 1
        if let tiff = r.nsImage?.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: args.dropFirst(i + 1).first ?? "og.png"))
        }
        exit(0)
    }

    struct Banner: View {
        @EnvironmentObject var monitor: Monitor

        var body: some View {
            HStack(alignment: .center, spacing: 56) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 18) {
                        Drip(mood: .happy, size: 76, level: 72)
                        Text("Refill").font(.system(size: 60, weight: .semibold)).tracking(-1.2).foregroundStyle(Theme.text)
                    }
                    Text("Your AI limits, watched.\nKnow the second they refill.")
                        .font(.system(size: 40, weight: .semibold)).tracking(-0.8).lineSpacing(4)
                        .foregroundStyle(Theme.text)
                    Text("Claude, Codex, Copilot, Cursor and Gemini in your menu bar. Alerts on your Mac, phone and room lights.")
                        .font(.system(size: 21)).foregroundStyle(Theme.muted).lineSpacing(3)
                        .frame(maxWidth: 560, alignment: .leading)
                    HStack(spacing: 10) {
                        chip("Free", accent: true); chip("Open source"); chip("macOS 14+")
                    }
                    .padding(.top, 6)
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(monitor.accounts.prefix(2)) { AccountCard(account: $0) }
                }
                .padding(14)
                .frame(width: 380)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line))
            }
            .padding(.horizontal, 72)
            .frame(width: 1200, height: 630)
            .background(Color.black)
        }

        func chip(_ t: String, accent: Bool = false) -> some View {
            Text(t).font(.system(size: 17, weight: .medium))
                .foregroundStyle(accent ? Color.black : Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(accent ? Theme.accent : Theme.raised, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}
