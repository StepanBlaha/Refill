import SwiftUI
import AppKit

@MainActor
final class NotchModel: ObservableObject {
    @Published var event: RefillEvent?
    @Published var expanded = false
    @Published var hovering = false
    /// Height of the open banner, measured from the message so it can grow.
    @Published var contentHeight: CGFloat = NotchMetrics.minHeight
    /// Banner width, clamped to the screen in NotchController.
    @Published var bannerWidth: CGFloat = NotchMetrics.width
    var notchWidth: CGFloat = 170
    var notchHeight: CGFloat = 10
}

enum NotchMetrics {
    static let bodyWidth: CGFloat = 380
    static let flare: CGFloat = 12
    static let width: CGFloat = bodyWidth + flare * 2
    /// Short messages keep the original banner. Longer ones grow past this.
    static let minHeight: CGFloat = 86
}

private struct NotchHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct NotchView: View {
    @ObservedObject var model: NotchModel
    @Environment(\.dynamicTypeSize) private var dynamicType
    private var reduce: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    /// Larger text sizes scale the banner instead of overflowing a fixed 86pt frame.
    private var typeScale: CGFloat {
        switch dynamicType {
        case .xSmall: return 0.9
        case .small: return 0.95
        case .medium, .large: return 1
        case .xLarge: return 1.12
        case .xxLarge: return 1.24
        case .xxxLarge: return 1.38
        case .accessibility1: return 1.55
        case .accessibility2: return 1.75
        case .accessibility3: return 1.95
        case .accessibility4: return 2.15
        case .accessibility5: return 2.35
        @unknown default: return 1
        }
    }

    private func mood(_ k: EventKind) -> Voice.Mood {
        switch k { case .reset, .test: return .party; case .warning: return .sweaty; case .empty: return .asleep }
    }

    var body: some View {
        let open = model.expanded
        let shapeH = reduce || open ? max(NotchMetrics.minHeight, model.contentHeight) : model.notchHeight
        let shape = NotchShape(
            width: reduce || open ? model.bannerWidth : model.notchWidth + NotchMetrics.flare * 2,
            height: shapeH,
            flare: NotchMetrics.flare)
        ZStack(alignment: .top) {
            Color.black
            if let e = model.event {
                banner(e, open: open)
                    .opacity(open ? 1 : 0)
                    .animation(.easeInOut(duration: reduce ? 0.25 : 0.2).delay(open && !reduce ? 0.12 : 0), value: open)
            }
        }
        .frame(width: model.bannerWidth, height: shapeH, alignment: .top)
        .clipShape(shape)
        .frame(width: model.bannerWidth, height: shapeH + 8, alignment: .top)
        .opacity(reduce ? (open ? 1 : 0) : 1)
        .animation(reduce ? .easeInOut(duration: 0.25) : .spring(response: 0.5, dampingFraction: 0.72), value: open)
        .animation(.easeOut(duration: 0.2), value: model.contentHeight)
        .onHover { model.hovering = $0 }
    }

    private func banner(_ e: RefillEvent, open: Bool) -> some View {
        let c = Theme.color(e.kind)
        return ZStack(alignment: .bottom) {
            HStack(alignment: .center, spacing: 12) {
                Drip(mood: mood(e.kind), size: 58 * min(typeScale, 1.35))
                    .offset(y: open ? 0 : 64)
                    .animation(reduce ? nil : .spring(response: 0.55, dampingFraction: 0.5).delay(0.15), value: open)
                VStack(alignment: .leading, spacing: 3) {
                    Text(e.title.softWrapped)
                        .font(Theme.rounded(15 * typeScale, .heavy))
                        .foregroundStyle(c)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(e.message.softWrapped)
                        .font(.system(size: 12 * typeScale))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, NotchMetrics.flare + 16)
            .padding(.trailing, NotchMetrics.flare + 16)
            .padding(.vertical, 14)
            LinearGradient(colors: [.clear, c, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 2)
                .padding(.horizontal, 40)
        }
        .frame(width: model.bannerWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { g in
                Color.clear.preference(key: NotchHeightKey.self, value: g.size.height)
            }
        }
        .onPreferenceChange(NotchHeightKey.self) { h in
            guard h > 1 else { return }
            let next = max(NotchMetrics.minHeight, ceil(h))
            if abs(model.contentHeight - next) > 0.5 { model.contentHeight = next }
        }
    }
}
