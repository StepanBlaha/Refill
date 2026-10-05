import SwiftUI

struct IntegrationsTab: View {
    @EnvironmentObject var monitor: Monitor
    @State private var sinks = Integrations.load()
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(sinks) { s in
                    Button { selection = s.id } label: {
                        HStack(spacing: Space.s) {
                            Image(systemName: s.kind.symbol).font(.system(size: 11)).frame(width: 16)
                            Text(s.kind.title).font(.system(size: 13)).lineLimit(1)
                            Spacer(minLength: 0)
                            if !s.enabled { Text("Off").font(.system(size: 10)).foregroundStyle(Theme.tertiary) }
                        }
                        .foregroundStyle(s.enabled ? Theme.text : Theme.muted)
                        .padding(.horizontal, Space.s).frame(height: 30)
                        .background(selection == s.id ? Theme.raised : .clear, in: RoundedRectangle(cornerRadius: Theme.radius))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(s.enabled ? "Turn off" : "Turn on") { toggle(s.id) }
                        Divider()
                        Button("Remove", role: .destructive) { remove(s.id) }
                    }
                }
                Spacer()
                HStack(spacing: Space.xs) {
                    Menu {
                        ForEach(SinkKind.allCases) { k in Button { add(k) } label: { Label(k.title, systemImage: k.symbol) } }
                    } label: {
                        Label("Add", systemImage: "plus").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.text)
                            .padding(.horizontal, Space.s).padding(.vertical, 4)
                            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
                    }
                    .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
                    Spacer()
                    if let id = selection {
                        Button { remove(id) } label: { Image(systemName: "trash").font(.system(size: 11)) }
                            .buttonStyle(.plain).foregroundStyle(Theme.muted).help("Remove (⌫)")
                    }
                }
                .padding(.horizontal, Space.s).frame(height: 32)
            }
            .padding(Space.s)
            .frame(width: 210)
            .background(Theme.panel.opacity(0.5))
            Rectangle().fill(Theme.line).frame(width: 1)

            if let i = sinks.firstIndex(where: { $0.id == selection }) {
                Scrolling { SinkEditor(sink: $sinks[i]) { remove(sinks[i].id) } }.id(sinks[i].id)
            } else {
                VStack(spacing: Space.m) {
                    Drip(mood: .focused, size: 40)
                    Text("Connect lights, your phone, anything").font(.system(size: 15, weight: .semibold))
                    Text("Phone: ntfy, Pushover or Telegram. Lights: Home Assistant, Hue or WLED. Or a custom webhook.")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).frame(maxWidth: 300)
                    Button("Read the setup guides") { NSWorkspace.shared.open(URL(string: Guides.base)!) }
                        .buttonStyle(DarkButton())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: sinks) { _, s in Integrations.save(s) }
        .focusable()
        .onDeleteCommand { if let id = selection { remove(id) } }
    }

    func toggle(_ id: UUID) {
        if let i = sinks.firstIndex(where: { $0.id == id }) { sinks[i].enabled.toggle() }
    }

    func add(_ k: SinkKind) {
        var s = Sink(kind: k)
        if k == .ntfy { s.values = ["server": "https://ntfy.sh", "topic": "refill-" + UUID().uuidString.prefix(8).lowercased()] }
        if k == .homeAssistant { s.values = ["hook": "refill"] }
        if k == .webhook { s.values = ["method": "POST"] }
        sinks.append(s)
        selection = s.id
    }

    func remove(_ id: UUID) {
        guard let i = sinks.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
            sinks.remove(at: i)
            if selection == id { selection = sinks.indices.contains(i) ? sinks[i].id : sinks.last?.id }
        }
    }
}

struct SinkEditor: View {
    @EnvironmentObject var monitor: Monitor
    @Binding var sink: Sink
    var onRemove: () -> Void = {}
    @State private var status = ""
    @State private var confirming = false
    @State private var testing = false

    var body: some View {
        HStack(spacing: Space.m) {
            Image(systemName: sink.kind.symbol).font(.system(size: 14)).foregroundStyle(Theme.muted)
                .frame(width: 32, height: 32).background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.panelRadius))
            VStack(alignment: .leading, spacing: 2) {
                Text(sink.kind.title).font(.system(size: 16, weight: .semibold))
                if !sink.kind.help.isEmpty {
                    Text(sink.kind.help).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                }
            }
            Spacer()
            Button { NSWorkspace.shared.open(sink.kind.guideURL) } label: {
                Label("Setup guide", systemImage: "book").font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(DarkButton())
            Toggle("", isOn: $sink.enabled).labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Theme.accent)
        }

        Panel(title: "Connection") {
            ForEach(Array(sink.kind.fields.enumerated()), id: \.1.key) { i, f in
                if i > 0 { RowDivider() }
                let b = Binding(get: { sink.values[f.key] ?? "" }, set: { sink.values[f.key] = $0 })
                if f.multiline {
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text(f.label).font(.system(size: 13))
                        TextEditor(text: b).font(.system(size: 12, design: .monospaced))
                            .scrollContentBackground(.hidden).padding(Space.xs)
                            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius)).frame(height: 56)
                    }
                    .padding(Space.m)
                } else {
                    Row(title: f.label) {
                        Group {
                            if f.secret { SecureField(f.placeholder, text: b) } else { TextField(f.placeholder, text: b) }
                        }
                        .textFieldStyle(DarkField()).frame(width: 240)
                    }
                }
            }
        }

        Panel(title: "Send on") {
            ToggleRow(title: "Refill", subtitle: "A limit reset", isOn: $sink.onReset)
            RowDivider()
            ToggleRow(title: "Warning", subtitle: "Usage crossed a threshold", isOn: $sink.onWarning)
            RowDivider()
            ToggleRow(title: "Empty", subtitle: "Hit the limit", isOn: $sink.onEmpty)
        }

        HStack(spacing: Space.s) {
            Button(testing ? "Sending…" : "Send test") {
                testing = true
                Task { status = await monitor.testSink(sink); testing = false }
            }
            .buttonStyle(DarkButton(prominent: true)).disabled(testing)
            Text(status).font(.system(size: 11)).monospacedDigit()
                .foregroundStyle(status.hasPrefix("OK") ? Theme.accent : Theme.amber).lineLimit(2)
            Spacer()
            Button { confirming = true } label: {
                Label("Remove", systemImage: "trash").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.coral)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Remove \(sink.kind.title)?", isPresented: $confirming) {
                Button("Remove", role: .destructive, action: onRemove)
            } message: { Text("Its settings, including any tokens, are deleted from this Mac.") }
        }
    }
}
