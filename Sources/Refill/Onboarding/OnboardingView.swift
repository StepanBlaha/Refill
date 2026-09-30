import SwiftUI
import AppKit

enum Onboarding {
    static var isDone: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingDone") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingDone") }
    }
    @MainActor private static var window: NSWindow?

    @MainActor static func showIfNeeded(monitor: Monitor) { if !isDone { show(monitor: monitor) } }

    @MainActor static func show(monitor: Monitor) {
        if let w = window { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
                         styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.isMovableByWindowBackground = true
        w.backgroundColor = NSColor(Theme.ink)
        w.appearance = NSAppearance(named: .darkAqua)
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: OnboardingView(monitor: monitor) { [weak w] in w?.close() })
        w.center()
        window = w
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { _ in
            Task { @MainActor in Onboarding.window = nil }
        }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }
}

struct OnboardingView: View {
    @ObservedObject var monitor: Monitor
    var close: () -> Void
    @State private var step = 0
    static let count = 6

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch step {
                case 0: WelcomeStep()
                case 1: AccountsStep(monitor: monitor)
                case 2: NotificationsStep()
                case 3: PhoneStep(monitor: monitor)
                case 4: LightsStep()
                default: DoneStep()
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .padding(.top, 28)
        .frame(width: 560, height: 520)
        .background(Theme.ink)
        .foregroundStyle(Theme.text)
    }

    private var footer: some View {
        HStack {
            OBPill(label: "Back", symbol: "chevron.left") { go(step - 1) }
                .opacity(step == 0 ? 0 : 1).disabled(step == 0)
            Spacer()
            HStack(spacing: 7) {
                ForEach(0..<Self.count, id: \.self) { i in
                    Capsule().fill(i == step ? Theme.lime : Theme.line).frame(width: i == step ? 20 : 7, height: 7)
                }
            }
            Spacer()
            if step == Self.count - 1 {
                OBPill(label: "Finish", symbol: "checkmark", prominent: true) { Onboarding.isDone = true; close() }
            } else {
                OBPill(label: step == 0 ? "Let's go" : (skippable ? "Skip" : "Next"), symbol: "chevron.right",
                       prominent: !skippable) { go(step + 1) }
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 20)
    }

    private var skippable: Bool { step == 3 || step == 4 }
    private func go(_ s: Int) { withAnimation(.spring(duration: 0.4)) { step = max(0, min(Self.count - 1, s)) } }
}

/// Private pill styled like MenuView's Pill.
struct OBPill: View {
    let label: String
    var symbol: String? = nil
    var prominent = false
    let action: () -> Void
    @State private var hover = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol).font(.system(size: 11, weight: .bold)) }
                Text(label)
            }
            .font(Theme.rounded(13, .semibold))
            .foregroundStyle(hover || prominent ? Theme.ink : Theme.text)
            .padding(.horizontal, 15).padding(.vertical, 8)
            .background(hover || prominent ? Theme.lime : Theme.panel, in: Capsule())
            .overlay(Capsule().stroke(Theme.line))
            .opacity(hover && prominent ? 0.9 : 1)
        }
        .buttonStyle(.plain).onHover { hover = $0 }
    }
}
