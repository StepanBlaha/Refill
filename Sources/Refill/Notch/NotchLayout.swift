import CoreGraphics

/// Screen geometry the notch banner can lay out from, without touching `NSScreen`.
/// Coordinates are AppKit's: origin at the bottom left, `y` growing upward.
struct DisplayGeometry: Equatable {
    var frame: CGRect
    var visibleFrame: CGRect
    var safeAreaTop: CGFloat
    var auxiliaryTopLeft: CGRect?
    var auxiliaryTopRight: CGRect?
    var isMain: Bool

    /// Menu bar thickness from the visible frame, else the housing inset, else the classic 24pt bar.
    var menuBarHeight: CGFloat {
        let gap = frame.maxY - visibleFrame.maxY
        if gap >= 20 && gap <= 64 { return gap }
        if safeAreaTop >= 20 && safeAreaTop <= 64 { return safeAreaTop }
        return NotchMetrics.fallbackMenuBar
    }

    /// The camera housing, derived from `safeAreaInsets.top` and the gap between the auxiliary areas.
    /// Nil when this display has no notch. A zero rect from the Objective-C bridge counts as absent.
    var notchRect: CGRect? {
        guard safeAreaTop > 0,
              let left = DisplayGeometry.usableArea(auxiliaryTopLeft),
              let right = DisplayGeometry.usableArea(auxiliaryTopRight) else { return nil }
        // Both lobes have to sit on the top edge; otherwise they are not the housing's neighbours.
        guard abs(left.maxY - frame.maxY) <= 1.5, abs(right.maxY - frame.maxY) <= 1.5 else { return nil }
        let width = right.minX - left.maxX
        guard width > 1, width < frame.width else { return nil }
        return CGRect(x: left.maxX, y: frame.maxY - safeAreaTop, width: width, height: safeAreaTop)
    }

    var hasNotch: Bool { notchRect != nil }

    static func usableArea(_ rect: CGRect?) -> CGRect? {
        guard let rect, !rect.isNull, !rect.isInfinite,
              rect.width.isFinite, rect.height.isFinite,
              rect.width > 1, rect.height > 1 else { return nil }
        return rect
    }
}

/// Sizes that keep the open pill about as tall as the menu bar. Text truncates inside them.
enum NotchMetrics {
    static let flare: CGFloat = 12
    /// Each lobe beside the housing. Symmetric, so the silhouette stays centered on the camera as it grows.
    static let ear: CGFloat = 128
    /// Narrower than this and a lobe cannot hold an icon or a truncated word.
    static let minEar: CGFloat = 72
    /// Keep the Apple menu and the status items outside the pill.
    static let edgeReserve: CGFloat = 72
    /// Clearance between content and the camera housing.
    static let housingGap: CGFloat = 8
    static let rowPad: CGFloat = 6
    static let compactText: CGFloat = 148
    static let stub = CGSize(width: 112, height: 6)
    /// Transparent slop under the curve so the window does not clip it. Not part of the pill.
    static let lip: CGFloat = 2
    static let fallbackMenuBar: CGFloat = 24

    static var compactWidth: CGFloat {
        flare + rowPad + 22 + housingGap + compactText + rowPad + flare
    }

    static func iconSize(band: CGFloat) -> CGFloat { min(22, max(14, band - 10)) }

    /// One text line, never taller than the band it has to live in.
    static func compactBand(_ screen: DisplayGeometry) -> CGFloat {
        min(36, max(24, screen.menuBarHeight.rounded()))
    }
}

/// Where the open pill draws. `panelFrame` and `notchRect` are AppKit screen coordinates.
/// `iconFrame` and `textFrame` are in the panel, origin at the top left (SwiftUI).
struct NotchBannerLayout: Equatable {
    enum Placement: Equatable {
        /// Icon in the left lobe, text in the right, housing between them.
        case flank(ear: CGFloat, notch: CGFloat)
        /// No housing. One compact row at the top centre.
        case center
        /// The whole pill, content included, sits strictly below the obscured band.
        case below(clearance: CGFloat)
    }

    var placement: Placement
    var closedSize: CGSize
    var openSize: CGSize
    /// How far the open pill sits below the top of the panel. Zero when it hangs from the screen edge.
    var openOffset: CGFloat
    var panelFrame: CGRect
    var notchRect: CGRect?
    var iconFrame: CGRect
    var textFrame: CGRect

    func globalFrame(_ panelLocal: CGRect) -> CGRect {
        CGRect(x: panelFrame.minX + panelLocal.minX,
               y: panelFrame.maxY - panelLocal.maxY,
               width: panelLocal.width,
               height: panelLocal.height)
    }

    func panelLocal(_ global: CGRect) -> CGRect {
        CGRect(x: global.minX - panelFrame.minX,
               y: panelFrame.maxY - global.maxY,
               width: global.width,
               height: global.height)
    }
}

enum NotchLayout {
    /// The display under the pointer, else the main display, else the first one.
    static func select(_ screens: [DisplayGeometry], cursor: CGPoint?) -> DisplayGeometry? {
        if let cursor, let hit = screens.first(where: { contains($0.frame, cursor) }) { return hit }
        if let main = screens.first(where: \.isMain) { return main }
        return screens.first
    }

    static func resolve(_ screen: DisplayGeometry) -> NotchBannerLayout {
        if let notch = screen.notchRect {
            return flankOrDrop(screen, notch: notch)
        }
        if screen.safeAreaTop > 0 {
            return drop(screen, clearance: screen.safeAreaTop, anchorX: screen.frame.midX, housing: nil)
        }
        return center(screen)
    }

    private static func flankOrDrop(_ screen: DisplayGeometry, notch: CGRect) -> NotchBannerLayout {
        let side = min(notch.minX - screen.frame.minX, screen.frame.maxX - notch.maxX)
        let ear = min(NotchMetrics.ear, (side - NotchMetrics.edgeReserve)).rounded(.down)
        let icon = NotchMetrics.iconSize(band: notch.height)
        let width = ear * 2 + notch.width
        let rawX = notch.midX - width / 2
        let fits = ear + 0.01 >= NotchMetrics.minEar
            && notch.height >= icon + 6
            && rawX >= screen.frame.minX
            && rawX + width <= screen.frame.maxX
        guard fits else {
            return drop(screen, clearance: notch.height, anchorX: notch.midX, housing: notch)
        }
        let panel = CGRect(x: rawX.rounded(),
                           y: screen.frame.maxY - notch.height - NotchMetrics.lip,
                           width: width,
                           height: notch.height + NotchMetrics.lip)
        let notchX = notch.minX - panel.minX
        let iconX = notchX - NotchMetrics.housingGap - icon
        let textX = notchX + notch.width + NotchMetrics.housingGap
        let textW = panel.width - NotchMetrics.flare - NotchMetrics.rowPad - textX
        guard iconX >= NotchMetrics.flare, textW >= 24 else {
            return drop(screen, clearance: notch.height, anchorX: notch.midX, housing: notch)
        }
        let textH = min(16, notch.height - 6)
        return NotchBannerLayout(
            placement: .flank(ear: ear, notch: notch.width),
            closedSize: CGSize(width: notch.width, height: notch.height),
            openSize: CGSize(width: width, height: notch.height),
            openOffset: 0,
            panelFrame: panel,
            notchRect: notch,
            iconFrame: CGRect(x: iconX, y: (notch.height - icon) / 2, width: icon, height: icon),
            textFrame: CGRect(x: textX, y: (notch.height - textH) / 2, width: textW, height: textH))
    }

    private static func center(_ screen: DisplayGeometry) -> NotchBannerLayout {
        let band = NotchMetrics.compactBand(screen)
        let width = fittedWidth(NotchMetrics.compactWidth, screen)
        let x = fittedX(screen.frame.midX, width: width, screen: screen)
        let panel = CGRect(x: x, y: screen.frame.maxY - band - NotchMetrics.lip,
                           width: width, height: band + NotchMetrics.lip)
        let (icon, text) = row(width: width, height: band, y: 0)
        return NotchBannerLayout(
            placement: .center,
            closedSize: NotchMetrics.stub,
            openSize: CGSize(width: width, height: band),
            openOffset: 0,
            panelFrame: panel,
            notchRect: nil,
            iconFrame: icon,
            textFrame: text)
    }

    private static func drop(_ screen: DisplayGeometry, clearance: CGFloat, anchorX: CGFloat, housing: CGRect?) -> NotchBannerLayout {
        let band = NotchMetrics.compactBand(screen)
        let width = fittedWidth(NotchMetrics.compactWidth, screen)
        let x = fittedX(anchorX, width: width, screen: screen)
        let panelH = clearance + band + NotchMetrics.lip
        let panel = CGRect(x: x, y: screen.frame.maxY - panelH, width: width, height: panelH)
        let (icon, text) = row(width: width, height: band, y: clearance)
        let seed = housing.map { CGSize(width: min($0.width, width), height: $0.height) } ?? NotchMetrics.stub
        return NotchBannerLayout(
            placement: .below(clearance: clearance),
            closedSize: seed,
            openSize: CGSize(width: width, height: band),
            openOffset: clearance,
            panelFrame: panel,
            notchRect: housing,
            iconFrame: icon,
            textFrame: text)
    }

    private static func row(width: CGFloat, height: CGFloat, y: CGFloat) -> (CGRect, CGRect) {
        let icon = NotchMetrics.iconSize(band: height)
        let iconX = NotchMetrics.flare + NotchMetrics.rowPad
        let textX = iconX + icon + NotchMetrics.housingGap
        let textW = max(0, width - textX - NotchMetrics.flare - NotchMetrics.rowPad)
        let textH = min(16, max(0, height - 6))
        return (
            CGRect(x: iconX, y: y + (height - icon) / 2, width: icon, height: icon),
            CGRect(x: textX, y: y + (height - textH) / 2, width: textW, height: textH))
    }

    private static func fittedWidth(_ preferred: CGFloat, _ screen: DisplayGeometry) -> CGFloat {
        min(preferred, max(0, screen.frame.width - 16))
    }

    private static func fittedX(_ anchor: CGFloat, width: CGFloat, screen: DisplayGeometry) -> CGFloat {
        let raw = (anchor - width / 2).rounded()
        let lo = screen.frame.minX
        let hi = screen.frame.maxX - width
        guard hi >= lo else { return lo }
        return min(max(raw, lo), hi)
    }

    private static func contains(_ frame: CGRect, _ point: CGPoint) -> Bool {
        point.x >= frame.minX && point.x <= frame.maxX && point.y >= frame.minY && point.y <= frame.maxY
    }
}

extension DisplayGeometry {
    /// 16-inch MacBook Pro, More Space. Safe area 38, auxiliary lobes 918, housing 220×38.
    /// Matches a published `NSScreen` reading (16-inch M4 Pro, September 2026).
    static let macBookPro16 = DisplayGeometry(
        frame: CGRect(x: 0, y: 0, width: 2056, height: 1329),
        visibleFrame: CGRect(x: 0, y: 0, width: 2056, height: 1290),
        safeAreaTop: 38,
        auxiliaryTopLeft: CGRect(x: 0, y: 1291, width: 918, height: 38),
        auxiliaryTopRight: CGRect(x: 1138, y: 1291, width: 918, height: 38),
        isMain: true)

    /// 14-inch class point space: housing about 12% of the width and exactly the menu-bar band.
    static let macBookPro14 = DisplayGeometry(
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950),
        safeAreaTop: 32,
        auxiliaryTopLeft: CGRect(x: 0, y: 950, width: 664, height: 32),
        auxiliaryTopRight: CGRect(x: 848, y: 950, width: 664, height: 32),
        isMain: true)

    static let studio = DisplayGeometry(
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1416),
        safeAreaTop: 0,
        auxiliaryTopLeft: nil,
        auxiliaryTopRight: nil,
        isMain: true)

    /// External panel that is not the origin display and has no housing.
    static let external = DisplayGeometry(
        frame: CGRect(x: 1920, y: -180, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1920, y: -180, width: 1920, height: 1056),
        safeAreaTop: 0,
        auxiliaryTopLeft: nil,
        auxiliaryTopRight: nil,
        isMain: false)
}
