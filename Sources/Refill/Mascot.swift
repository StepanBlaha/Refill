import SwiftUI

/// Drip: the droplet who lives in your menu bar. Mood follows your fuel.
struct DropletShape: Shape {
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
    @State private var bob = false

    var body: some View {
        ZStack {
            DropletShape()
                .fill(LinearGradient(colors: [bodyColor, bodyColor.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .shadow(color: bodyColor.opacity(0.45), radius: size * 0.18)
            Ellipse().fill(.white.opacity(0.35))
                .frame(width: size * 0.14, height: size * 0.22)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.2, y: size * 0.02)
            Canvas { ctx, s in face(ctx, s) }
            if mood == .asleep {
                Text("z").font(Theme.rounded(size * 0.26, .heavy)).foregroundStyle(Theme.muted)
                    .offset(x: size * 0.42, y: -size * 0.38 + (bob ? -3 : 1)).opacity(bob ? 1 : 0.4)
            }
            if mood == .sweaty {
                DropletShape().fill(Color(hex: 0x7CC7FF))
                    .frame(width: size * 0.12, height: size * 0.17)
                    .offset(x: size * 0.36, y: -size * 0.08 + (bob ? 2 : 0))
            }
            if mood == .party {
                ForEach(0..<3) { i in
                    Image(systemName: "sparkle").font(.system(size: size * 0.18, weight: .bold))
                        .foregroundStyle(Theme.lime)
                        .offset(x: [-0.5, 0.5, 0.42][i] * size, y: [-0.3, -0.42, 0.2][i] * size)
                        .scaleEffect(bob ? 1.1 : 0.7)
                }
            }
        }
        .frame(width: size * 0.82, height: size)
        .offset(y: bob ? -(mood == .party ? size * 0.1 : 1.5) : 1.5)
        .animation(.easeInOut(duration: mood == .party ? 0.35 : 1.6).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
        .accessibilityLabel("Drip, feeling \(String(describing: mood))")
    }

    var bodyColor: Color {
        switch mood {
        case .happy, .party: return Theme.lime
        case .focused: return Theme.amber
        case .sweaty: return Theme.coral
        case .asleep: return Theme.muted
        }
    }

    private func face(_ ctx: GraphicsContext, _ s: CGSize) {
        let w = s.width, eyeY = s.height * 0.6, dx = w * 0.17, ink = GraphicsContext.Shading.color(Theme.ink)
        let lw = max(1.4, w * 0.055)
        func stroke(_ p: Path) { ctx.stroke(p, with: ink, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)) }
        let eyes = [w / 2 - dx, w / 2 + dx]
        let mouthY = eyeY + w * 0.17
        switch mood {
        case .happy, .focused, .sweaty:
            let r = w * (mood == .sweaty ? 0.075 : 0.065)
            for x in eyes {
                let rect = mood == .focused ? CGRect(x: x - r, y: eyeY - r * 0.55, width: r * 2, height: r * 1.1)
                                            : CGRect(x: x - r, y: eyeY - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: ink)
            }
            var m = Path()
            switch mood {
            case .happy:
                m.addArc(center: CGPoint(x: w / 2, y: mouthY - w * 0.05), radius: w * 0.1,
                         startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            case .focused:
                m.move(to: CGPoint(x: w / 2 - w * 0.07, y: mouthY)); m.addLine(to: CGPoint(x: w / 2 + w * 0.07, y: mouthY))
            default:
                m.addEllipse(in: CGRect(x: w / 2 - w * 0.04, y: mouthY - w * 0.03, width: w * 0.08, height: w * 0.08))
                var brows = Path()
                brows.move(to: CGPoint(x: eyes[0] - w * 0.07, y: eyeY - w * 0.12)); brows.addLine(to: CGPoint(x: eyes[0] + w * 0.05, y: eyeY - w * 0.16))
                brows.move(to: CGPoint(x: eyes[1] + w * 0.07, y: eyeY - w * 0.12)); brows.addLine(to: CGPoint(x: eyes[1] - w * 0.05, y: eyeY - w * 0.16))
                stroke(brows)
            }
            stroke(m)
        case .asleep:
            for x in eyes {
                var e = Path()
                e.addArc(center: CGPoint(x: x, y: eyeY - w * 0.04), radius: w * 0.06,
                         startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                stroke(e)
            }
            var p = Path()
            p.move(to: CGPoint(x: w / 2 - w * 0.04, y: mouthY)); p.addLine(to: CGPoint(x: w / 2 + w * 0.04, y: mouthY))
            stroke(p)
        case .party:
            var p = Path()
            for x in eyes {
                p.move(to: CGPoint(x: x - w * 0.06, y: eyeY + w * 0.02))
                p.addLine(to: CGPoint(x: x, y: eyeY - w * 0.05))
                p.addLine(to: CGPoint(x: x + w * 0.06, y: eyeY + w * 0.02))
            }
            stroke(p)
            var m = Path()
            m.move(to: CGPoint(x: w / 2 - w * 0.13, y: mouthY - w * 0.04))
            m.addQuadCurve(to: CGPoint(x: w / 2 + w * 0.13, y: mouthY - w * 0.04), control: CGPoint(x: w / 2, y: mouthY + w * 0.2))
            m.closeSubpath()
            ctx.fill(m, with: ink)
        }
    }
}
