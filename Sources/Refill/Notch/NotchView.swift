import SwiftUI
import AppKit

@MainActor
final class NotchModel: ObservableObject {
    @Published var event: RefillEvent?
    @Published var expanded = false
    @Published var hovering = false
    @Published var layout: NotchBannerLayout = NotchLayout.resolve(.studio)
}

struct NotchView: View {
    @ObservedObject var model: NotchModel
    @Environment(\.dynamicTypeSize) private var dynamicType
    @Environment(\.accessibilityReduceMotion) private var reduce

    private func mood(_ k: EventKind) -> Voice.Mood {
        switch k { case .reset, .test: return .party; case .warning: return .sweaty; case .empty: return .asleep }
    }

    /// Larger type tightens into the band. The pill does not grow to fit it.
    private func fontSize(band: CGFloat) -> CGFloat {
        let scaled: CGFloat
        switch dynamicType {
        case .xSmall: scaled = 11
        case .small: scaled = 11.5
        case .medium, .large: scaled = 12
        case .xLarge: scaled = 13
        case .xxLarge: scaled = 14
        case .xxxLarge: scaled = 15
        default: scaled = 16
        }
        return min(scaled, max(11, band * 0.42))
    }

    var body: some View {
        let layout = model.layout
        let open = model.expanded
        let shapeW = open ? layout.openSize.width : layout.closedSize.width
        let shapeH = open ? layout.openSize.height : layout.closedSize.height
        let shapeY = open ? layout.openOffset : 0
        let panelW = layout.panelFrame.width
        let panelH = layout.panelFrame.height

        ZStack(alignment: .topLeading) {
            placedShape(width: shapeW, height: shapeH, y: shapeY, panelW: panelW, panelH: panelH)
            if let e = model.event {
                banner(e, layout: layout)
                    .opacity(open ? 1 : 0)
                    .animation(.easeInOut(duration: reduce ? 0.2 : 0.16).delay(open && !reduce ? 0.1 : 0), value: open)
            }
        }
        .frame(width: panelW, height: panelH, alignment: .topLeading)
        .animation(reduce ? .easeInOut(duration: 0.25) : .spring(response: 0.5, dampingFraction: 0.72), value: open)
        .onHover { model.hovering = $0 }
    }

    /// Centered on the panel and dropped `y` points from the top, so the wings grow out of the housing.
    private func placedShape(width: CGFloat, height: CGFloat, y: CGFloat, panelW: CGFloat, panelH: CGFloat) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            NotchShape(width: width, height: height, flare: NotchMetrics.flare)
                .fill(Color.black)
                .frame(width: width, height: height)
            Spacer(minLength: 0)
        }
        .frame(width: panelW, height: height, alignment: .center)
        .offset(y: y)
        .frame(width: panelW, height: panelH, alignment: .top)
    }

    private func banner(_ e: RefillEvent, layout: NotchBannerLayout) -> some View {
        let font = fontSize(band: layout.openSize.height)
        return ZStack(alignment: .topLeading) {
            Drip(mood: mood(e.kind), size: layout.iconFrame.width)
                .frame(width: layout.iconFrame.width, height: layout.iconFrame.height)
                .clipped()
                .offset(x: layout.iconFrame.minX, y: layout.iconFrame.minY)
            line(e, font: font)
                .lineLimit(1)
                .truncationMode(.tail)
                .allowsTightening(true)
                .frame(width: layout.textFrame.width, height: layout.textFrame.height, alignment: .leading)
                .clipped()
                .offset(x: layout.textFrame.minX, y: layout.textFrame.minY)
            if layout.openSize.height >= 30, layout.textFrame.maxY + 4 <= layout.openOffset + layout.openSize.height {
                LinearGradient(colors: [.clear, Theme.color(e.kind), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: layout.textFrame.width, height: 2)
                    .offset(x: layout.textFrame.minX, y: layout.textFrame.maxY + 1)
            }
        }
        .frame(width: layout.panelFrame.width, height: layout.panelFrame.height, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(e.title). \(e.message)")
    }

    private func line(_ e: RefillEvent, font: CGFloat) -> Text {
        let title = Text(e.title).font(Theme.rounded(font, .heavy)).foregroundStyle(Theme.color(e.kind))
        let message = e.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return title }
        return title + Text("  \(message)").font(.system(size: font)).foregroundStyle(Theme.muted)
    }
}
