import SwiftUI

/// Drip, redrawn flat: a small glass tank with a face. The liquid is your real
/// remaining quota; the face is the mood. No gradients, no glow.
struct DropletShape: Shape {   // kept for callers that draw small drops (sweat, icons)
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height, cy = h - w / 2
        var p = Path()
        p.move(to: CGPoint(x: w / 2, y: 0))
        p.addCurve(to: CGPoint(x: w, y: cy), control1: CGPoint(x: w * 0.62, y: h * 0.18),
                   control2: CGPoint(x: w, y: cy - w * 0.3))
        p.addArc(center: CGPoint(x: w / 2, y: cy), radius: w / 2, startAngle: .degrees(0),
                 endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: 0, y: cy - w * 0.3),
                   control2: CGPoint(x: w * 0.38, y: h * 0.18))
        p.closeSubpath()
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}

struct Drip: View {
    var mood: Voice.Mood
    var size: CGFloat = 44
    /// Remaining % (0-100). Nil = pick a level that fits the mood.
    var level: Double? = nil
    @State private var hop = false

    private var fill: Double {
        if let level { return max(0.04, min(1, level / 100)) }
        switch mood {
        case .party: return 1
        case .happy: return 0.8
        case .focused: return 0.45
        case .sweaty: return 0.16
        case .asleep: return 0.04
        }
    }

    private var liquid: Color {
        switch mood {
        case .sweaty: return Theme.coral
        case .asleep: return Theme.tertiary
        case .focused: return Theme.amber
        default: return Theme.lime
        }
    }

    var body: some View {
        let w = size * 0.74, h = size * 0.86, r = w * 0.26, lw = max(1.2, size * 0.045)
        VStack(spacing: size * 0.02) {
            RoundedRectangle(cornerRadius: size * 0.03).fill(Theme.tertiary)
                .frame(width: w * 0.38, height: size * 0.08)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(Theme.panel)
                Rectangle().fill(liquid).frame(height: h * fill)
                    .animation(Theme.unfold, value: fill)
                Canvas { ctx, s in face(ctx, s) }
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(Theme.tertiary, lineWidth: lw))
            .overlay(alignment: .topTrailing) {
                if mood == .asleep {
                    Text("z").font(.system(size: size * 0.24, weight: .semibold)).foregroundStyle(Theme.muted)
                        .offset(x: size * 0.2, y: -size * 0.16)
                }
            }
        }
        .frame(width: size, height: size)
        .offset(y: mood == .party && hop ? -size * 0.08 : 0)
        .animation(mood == .party ? .spring(response: 0.3, dampingFraction: 0.5).repeatCount(5) : .default, value: hop)
        .onAppear { hop = mood == .party }
        .onChange(of: mood) { _, m in hop = m == .party }
        .accessibilityLabel("Drip, \(String(describing: mood))")
    }

    private func face(_ ctx: GraphicsContext, _ s: CGSize) {
        let w = s.width, eyeY = s.height * 0.4, dx = w * 0.18
        // Eyes sit on the glass or in the liquid; flip color for contrast.
        let submerged = fill > 1 - 0.4 - 0.08
        let ink = GraphicsContext.Shading.color(submerged ? .black : .white)
        let lw = max(1.3, w * 0.06)
        func stroke(_ p: Path) { ctx.stroke(p, with: ink, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)) }
        let eyes = [w / 2 - dx, w / 2 + dx]
        let mouthY = eyeY + w * 0.2
        let er = w * 0.065

        switch mood {
        case .happy, .sweaty:
            for x in eyes { ctx.fill(Path(ellipseIn: CGRect(x: x - er, y: eyeY - er, width: er * 2, height: er * 2)), with: ink) }
            var m = Path()
            if mood == .happy {
                m.move(to: CGPoint(x: w / 2 - w * 0.1, y: mouthY - w * 0.02))
                m.addQuadCurve(to: CGPoint(x: w / 2 + w * 0.1, y: mouthY - w * 0.02), control: CGPoint(x: w / 2, y: mouthY + w * 0.08))
            } else {
                m.move(to: CGPoint(x: w / 2 - w * 0.08, y: mouthY + w * 0.02))
                m.addQuadCurve(to: CGPoint(x: w / 2 + w * 0.08, y: mouthY + w * 0.02), control: CGPoint(x: w / 2, y: mouthY - w * 0.06))
            }
            stroke(m)
        case .focused:
            var p = Path()
            for x in eyes { p.move(to: CGPoint(x: x - er, y: eyeY)); p.addLine(to: CGPoint(x: x + er, y: eyeY)) }
            p.move(to: CGPoint(x: w / 2 - w * 0.06, y: mouthY)); p.addLine(to: CGPoint(x: w / 2 + w * 0.06, y: mouthY))
            stroke(p)
        case .asleep:
            for x in eyes {
                var e = Path()
                e.move(to: CGPoint(x: x - er * 1.2, y: eyeY))
                e.addQuadCurve(to: CGPoint(x: x + er * 1.2, y: eyeY), control: CGPoint(x: x, y: eyeY + er * 1.4))
                stroke(e)
            }
        case .party:
            var p = Path()
            for x in eyes {
                p.move(to: CGPoint(x: x - er * 1.2, y: eyeY + er * 0.6))
                p.addLine(to: CGPoint(x: x, y: eyeY - er * 0.6))
                p.addLine(to: CGPoint(x: x + er * 1.2, y: eyeY + er * 0.6))
            }
            stroke(p)
            var m = Path()
            m.move(to: CGPoint(x: w / 2 - w * 0.12, y: mouthY - w * 0.03))
            m.addQuadCurve(to: CGPoint(x: w / 2 + w * 0.12, y: mouthY - w * 0.03), control: CGPoint(x: w / 2, y: mouthY + w * 0.14))
            m.closeSubpath()
            ctx.fill(m, with: ink)
        }
    }
}
