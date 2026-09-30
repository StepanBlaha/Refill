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
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Theme.accent)
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

/// Plain dark button; `.prominent` is the one green action on a screen.
struct DarkButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .medium))
            .foregroundStyle(prominent ? Color.black : Theme.text)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(prominent ? Theme.accent : (configuration.isPressed ? Theme.hover : Theme.raised),
                        in: RoundedRectangle(cornerRadius: Theme.radius + 1))
            .opacity(prominent && configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 1), value: configuration.isPressed)
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
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.radius + 2))
        .animation(.spring(response: 0.3, dampingFraction: 1), value: selection)
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
    }
}
