import SwiftUI

struct PhoneStep: View {
    @ObservedObject var monitor: Monitor
    @State private var sink: Sink?
    @State private var status = ""
    @State private var testing = false

    private var topic: String { sink?.v("topic") ?? "" }
    private var httpsURL: String { "https://ntfy.sh/\(topic)" }

    var body: some View {
        StepFrame(mood: sink == nil ? .happy : .party, title: "Pocket Drip",
                  line: "ntfy is a free push app for iOS and Android, no account needed. I'll buzz your phone when a tank refills.") {
            VStack(spacing: 10) {
                if let sink {
                    HStack(spacing: 16) {
                        QRView(text: "ntfy://ntfy.sh/\(topic)", size: 140)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Install the ntfy app\n2. Scan this QR (or subscribe to the topic)").font(Theme.rounded(12))
                                .foregroundStyle(Theme.muted)
                            Text(httpsURL).font(Theme.mono(11)).textSelection(.enabled).foregroundStyle(Theme.lime)
                            OBPill(label: testing ? "Sending…" : "Send test", symbol: "paperplane.fill") { test(sink) }
                            if !status.isEmpty { Text(status).font(Theme.rounded(12)).foregroundStyle(Theme.muted) }
                        }
                    }
                } else {
                    OBPill(label: "Set up ntfy", symbol: "iphone.gen3", prominent: true, action: setUp)
                    Text("Skip this if you only care about the desktop.").font(Theme.rounded(12)).foregroundStyle(Theme.muted)
                }
            }
        }
        .onAppear { sink = Integrations.load().first { $0.kind == .ntfy && !$0.v("topic").isEmpty } }
    }

    private func setUp() {
        let chars = Array("abcdefghjkmnpqrstuvwxyz23456789")
        let topic = "refill-" + String((0..<8).map { _ in chars.randomElement()! })
        let s = Sink(kind: .ntfy, values: ["server": "https://ntfy.sh", "topic": topic])
        var all = Integrations.load()
        all.append(s)
        Integrations.save(all)
        withAnimation { sink = s }
    }

    private func test(_ s: Sink) {
        testing = true
        Task {
            status = await monitor.testSink(s)
            testing = false
        }
    }
}

struct LightsStep: View {
    var body: some View {
        StepFrame(mood: .focused, title: "Make it glow",
                  line: "Drip can flash your lights: lime on refill, amber on warning, red when empty.") {
            VStack(alignment: .leading, spacing: 10) {
                row("house.fill", "Home Assistant", "One webhook drives any light brand.")
                row("lightbulb.led.fill", "Philips Hue", "Talk to your bridge directly.")
                row("lightbulb.led.wide.fill", "WLED", "Strips and matrices on your LAN.")
                Text("Set these up any time from Settings, in Integrations.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.muted).padding(.top, 2)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        }
    }
    private func row(_ s: String, _ t: String, _ d: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: s).foregroundStyle(Theme.amber).frame(width: 22)
            Text(t).font(Theme.rounded(13, .semibold))
            Text(d).font(Theme.rounded(12)).foregroundStyle(Theme.muted)
        }
    }
}

struct DoneStep: View {
    @State private var login = LoginItem.isOn
    var body: some View {
        StepFrame(mood: .party, title: "All topped up",
                  line: "I live in your menu bar now. Look for the little tank.") {
            Toggle("Launch Refill at login", isOn: Binding(get: { login }, set: { login = $0; LoginItem.set($0); login = LoginItem.isOn }))
                .toggleStyle(RefillSwitch()).tint(Theme.lime).font(Theme.rounded(14, .medium)).frame(width: 240)
        }
    }
}
