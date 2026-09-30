import SwiftUI
import AppKit

@MainActor
final class NotchModel: ObservableObject {
    @Published var event: RefillEvent?
    @Published var expanded = false
    @Published var hovering = false
    var notchWidth: CGFloat = 170
    var notchHeight: CGFloat = 10
}

enum NotchMetrics {
    static let bodyWidth: CGFloat = 380
    static let flare: CGFloat = 12
    static let width: CGFloat = bodyWidth + flare * 2
    static let height: CGFloat = 86
    static let panelHeight: CGFloat = 100
}

struct NotchView: View {
    @ObservedObject var model: NotchModel
    private var reduce: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private func mood(_ k: EventKind) -> Voice.Mood {
        switch k { case .reset, .test: return .party; case .warning: return .sweaty; case .empty: return .asleep }
    }

    var body: some View {
        let open = model.expanded
        let shape = NotchShape(
            width: reduce || open ? NotchMetrics.width : model.notchWidth + NotchMetrics.flare * 2,
            height: reduce || open ? NotchMetrics.height : model.notchHeight,
            flare: NotchMetrics.flare)
        ZStack(alignment: .top) {
            Color.black
            if let e = model.event {
                let c = Theme.color(e.kind)
                ZStack {
                    HStack(spacing: 12) {
                        Drip(mood: mood(e.kind), size: 58)
                            .offset(y: open ? 8 : 70)
                            .animation(reduce ? nil : .spring(response: 0.55, dampingFraction: 0.5).delay(0.15), value: open)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(e.title).font(Theme.rounded(15, .heavy)).foregroundStyle(c).lineLimit(1)
                            Text(e.message).font(.system(size: 12)).foregroundStyle(Theme.muted)
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, NotchMetrics.flare + 18)
                    .padding(.trailing, NotchMetrics.flare + 20)
                    .padding(.top, 6)
                    VStack {
                        Spacer()
                        LinearGradient(colors: [.clear, c, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(height: 2)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(width: NotchMetrics.width, height: NotchMetrics.height)
                .opacity(open ? 1 : 0)
                .animation(.easeInOut(duration: reduce ? 0.25 : 0.2).delay(open && !reduce ? 0.12 : 0), value: open)
            }
        }
        .frame(width: NotchMetrics.width, height: NotchMetrics.height, alignment: .top)
        .clipShape(shape)
        .frame(width: NotchMetrics.width, height: NotchMetrics.panelHeight, alignment: .top)
        .opacity(reduce ? (open ? 1 : 0) : 1)
        .animation(reduce ? .easeInOut(duration: 0.25) : .spring(response: 0.5, dampingFraction: 0.72), value: open)
        .onHover { model.hovering = $0 }
    }
}
