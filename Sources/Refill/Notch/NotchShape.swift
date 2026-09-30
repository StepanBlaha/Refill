import SwiftUI

/// Pure-black notch silhouette: concave flares at the top corners (like the hardware notch),
/// convex rounded bottom corners. Width/height animate; it is centered horizontally and pinned
/// to the top of its rect. `width` includes the flares on both sides.
struct NotchShape: Shape {
    var width: CGFloat
    var height: CGFloat
    var flare: CGFloat = 12
    var radius: CGFloat = 24

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(width, height) }
        set { width = newValue.first; height = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let w = max(width, 0), h = max(height, 0)
        let f = max(0, min(flare, h / 2, w / 4))
        let r = max(0, min(radius, (h - f) / 2, (w - 2 * f) / 2))
        let x0 = rect.midX - w / 2, x1 = rect.midX + w / 2
        let y0 = rect.minY, y1 = rect.minY + h
        var p = Path()
        p.move(to: CGPoint(x: x0, y: y0))
        p.addLine(to: CGPoint(x: x1, y: y0))
        // right concave flare: circle centered outside the body at (x1, y0 + f)
        p.addArc(center: CGPoint(x: x1, y: y0 + f), radius: f,
                 startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)
        p.addLine(to: CGPoint(x: x1 - f, y: y1 - r))
        p.addArc(tangent1End: CGPoint(x: x1 - f, y: y1), tangent2End: CGPoint(x: x1 - f - r, y: y1), radius: r)
        p.addLine(to: CGPoint(x: x0 + f + r, y: y1))
        p.addArc(tangent1End: CGPoint(x: x0 + f, y: y1), tangent2End: CGPoint(x: x0 + f, y: y1 - r), radius: r)
        p.addLine(to: CGPoint(x: x0 + f, y: y0 + f))
        p.addArc(center: CGPoint(x: x0, y: y0 + f), radius: f,
                 startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
        p.closeSubpath()
        return p
    }
}
