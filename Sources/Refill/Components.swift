import AppKit
import SwiftUI

/// Spacing scale. Every gap in the app is one of these.
enum Space {
    static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 24
}

/// A titled group of rows on a #1C1C1E panel (replaces the light grouped Form).
struct Panel<Content: View>: View {
    var title: String? = nil
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            if let title {
                Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.muted)
                    .padding(.leading, Space.m)
            }
            VStack(spacing: 0) { content }
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.panelRadius, style: .continuous))
            if let footer {
                Text(footer).font(.system(size: 11)).foregroundStyle(Theme.muted)
                    .padding(.horizontal, Space.m).fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }
}

struct Row<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13)).foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Space.m)
            trailing
        }
        .padding(.horizontal, Space.m).padding(.vertical, Space.s)
        .frame(minHeight: 40)
    }
}

struct RowDivider: View {
    var body: some View { Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, Space.m) }
}

struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Row(title: title, subtitle: subtitle) {
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(RefillSwitch())
        }
    }
}

/// Dark inline text field (no light system bezel).
struct DarkField: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.textFieldStyle(.plain).font(.system(size: 13))
            .padding(.horizontal, Space.s).padding(.vertical, 5)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
    }
}

enum ClickFeedback {
    static func cursor(hovering: Bool, enabled: Bool) {
        guard hovering else { NSCursor.arrow.set(); return }
        (enabled ? NSCursor.pointingHand : NSCursor.operationNotAllowed).set()
    }
}

/// Plain dark button; `.prominent` is the one green action on a screen.
struct DarkButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        DarkButtonBody(configuration: configuration, prominent: prominent)
    }
}

private struct DarkButtonBody: View {
    let configuration: ButtonStyleConfiguration
    var prominent: Bool
    @State private var hover = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused

    var body: some View {
        configuration.label.font(.system(size: 12, weight: .medium))
            .foregroundStyle(prominent && enabled ? Color.black : Theme.text)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.radius + 1))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius + 1).stroke(Theme.accent, lineWidth: focused ? 2 : 0))
            .opacity(!enabled ? 0.45 : (prominent && configuration.isPressed ? 0.8 : 1))
            .scaleEffect(configuration.isPressed && enabled ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 1), value: configuration.isPressed)
            .onHover { hover = $0; ClickFeedback.cursor(hovering: $0, enabled: enabled) }
    }

    private var fill: Color {
        if !enabled { return Theme.raised }
        if prominent { return hover && !configuration.isPressed ? Theme.accent.opacity(0.85) : Theme.accent }
        if configuration.isPressed || hover { return Theme.hover }
        return Theme.raised
    }
}

/// Press, focus ring and pointer cursor for controls that draw their own background.
struct PointerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PointerButtonBody(configuration: configuration)
    }
}

private struct PointerButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var enabled
    @Environment(\.isFocused) private var focused

    var body: some View {
        configuration.label
            .opacity(configuration.isPressed && enabled ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && enabled ? 0.97 : 1)
            .overlay(RoundedRectangle(cornerRadius: Theme.radius + 2).stroke(Theme.accent, lineWidth: focused ? 2 : 0))
            .animation(.spring(response: 0.2, dampingFraction: 1), value: configuration.isPressed)
            .onHover { ClickFeedback.cursor(hovering: $0, enabled: enabled) }
    }
}

/// Text-only segmented control: selected = white on raised, others muted.
struct Segmented<T: Hashable>: View {
    let items: [(T, String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.0) { item in
                Button { selection = item.0 } label: {
                    Text(item.1).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selection == item.0 ? Theme.text : Theme.muted)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(selection == item.0 ? Theme.raised : .clear,
                                    in: RoundedRectangle(cornerRadius: Theme.radius))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PointerButtonStyle())
            }
        }
        .padding(2)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.radius + 2))
        .animation(.spring(response: 0.3, dampingFraction: 1), value: selection)
    }
}

extension String {
    /// Inserts break points into long tokens (emails, window names) so a single
    /// word can wrap inside a banner instead of drawing past its edge.
    var softWrapped: String {
        split(separator: " ", omittingEmptySubsequences: false).map { word -> String in
            let w = String(word)
            guard w.count > 24 else { return w }
            var out = ""
            var n = 0
            for ch in w {
                if n == 24 { out.append("\u{200B}"); n = 0 }
                out.append(ch)
                n += 1
            }
            return out
        }.joined(separator: " ")
    }
}

/// Dark menu picker (system menu button, borderless so it doesn't render a light bezel).
struct DarkMenu<T: Hashable>: View {
    let items: [(T, String)]
    @Binding var selection: T

    var body: some View {
        Menu {
            ForEach(items, id: \.0) { i in Button(i.1) { selection = i.0 } }
        } label: {
            HStack(spacing: Space.xs) {
                Text(items.first(where: { $0.0 == selection })?.1 ?? "").font(.system(size: 12))
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, Space.s).padding(.vertical, 4)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
            .contentShape(Rectangle())
        }
        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
        .onHover { ClickFeedback.cursor(hovering: $0, enabled: true) }
    }
}

/// Brand switch: green when on, drawn by us so it looks the same in every window state.
struct RefillSwitch: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        // Label (if any) on the left, like the system switch; labelsHidden() still hides it.
        HStack(spacing: Space.s) {
            configuration.label
            Spacer(minLength: 0)
            knob(configuration)
        }
    }

    private func knob(_ configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule().fill(configuration.isOn ? Theme.accent : Color.white.opacity(0.18))
                    .frame(width: 34, height: 20)
                Circle().fill(Color.white).frame(width: 16, height: 16).padding(2)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
            }
            .animation(.spring(response: 0.25, dampingFraction: 1), value: configuration.isOn)
            .contentShape(Capsule())
        }
        .buttonStyle(PointerButtonStyle())
        .accessibilityElement()
        .accessibilityLabel(Text("Switch"))
        .accessibilityValue(Text(configuration.isOn ? "On" : "Off"))
        .accessibilityAddTraits(.isButton)
    }
}
