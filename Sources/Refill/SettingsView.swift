import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab().tabItem { Label("General", systemImage: "drop.fill") }
            IntegrationsTab().tabItem { Label("Integrations", systemImage: "lightbulb.led.fill") }
            AccountsTab().tabItem { Label("Accounts", systemImage: "person.2.fill") }
        }
        .frame(width: 620, height: 560)
    }
}

struct GeneralTab: View {
    @EnvironmentObject var monitor: Monitor
    @AppStorage(Prefs.K.notify) var notify = true
    @AppStorage(Prefs.K.sound) var sound = true
    @AppStorage(Prefs.K.soundName) var soundName = "Glass"
    @AppStorage(Prefs.K.hook) var hook = true
    @AppStorage(Prefs.K.poll) var poll = 5.0
    @AppStorage(Prefs.K.port) var port = 7788
    @AppStorage(Prefs.K.lan) var lan = false
    @AppStorage(Prefs.K.thresholds) var thresholds = "80, 95"
    @AppStorage(Prefs.K.quiet) var quiet = false
    @AppStorage(Prefs.K.quietFrom) var quietFrom = 22
    @AppStorage(Prefs.K.quietTo) var quietTo = 8
    @AppStorage(Prefs.K.quietPush) var quietPush = false
    @State private var login = LoginItem.isOn

    let sounds = ((try? FileManager.default.contentsOfDirectory(atPath: "/System/Library/Sounds")) ?? [])
        .map { ($0 as NSString).deletingPathExtension }.sorted()

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Drip(mood: monitor.mood, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Refill").font(Theme.rounded(22, .heavy))
                        Text("I watch your AI tanks and yell when they refill.").foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            Section("Startup") {
                Toggle("Open Refill at login", isOn: $login)
                    .onChange(of: login) { _, on in LoginItem.set(on); login = LoginItem.isOn }
                if LoginItem.status == .requiresApproval {
                    Button("Approve in System Settings → Login Items") { SMAppServiceOpen.loginItems() }
                }
                if !Bundle.main.bundlePath.hasPrefix("/Applications") {
                    Text("Tip: run from /Applications for login launch (scripts/build.sh --install).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("On this Mac") {
                Toggle("Notification", isOn: $notify)
                HStack {
                    Toggle("Sound", isOn: $sound)
                    Spacer()
                    Picker("", selection: $soundName) { ForEach(sounds, id: \.self) { Text($0) } }
                        .labelsHidden().frame(width: 140)
                        .onChange(of: soundName) { _, n in NSSound(named: NSSound.Name(n))?.play() }
                }
                Toggle("Run hook script ~/.config/refill/on-reset", isOn: $hook)
                Button("Send test signal everywhere") { monitor.sendTest() }
            }
            Section("Quiet hours") {
                Toggle("Quiet hours (no sounds; lights still work)", isOn: $quiet)
                if quiet {
                    HStack {
                        Picker("From", selection: $quietFrom) { ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)) } }
                        Picker("To", selection: $quietTo) { ForEach(0..<24, id: \.self) { Text(String(format: "%02d:00", $0)) } }
                    }
                    Toggle("Also mute phone and chat pushes", isOn: $quietPush)
                }
            }
            Section("Warnings") {
                TextField("Warn when used % crosses", text: $thresholds)
                Text("Comma-separated. Plus an “empty” event at 100%.").font(.caption).foregroundStyle(.secondary)
                Stepper("Check usage every \(Int(poll)) min", value: $poll, in: 1...60)
            }
            Section("Dashboard") {
                HStack {
                    TextField("Port", value: $port, format: .number.grouping(.never)).frame(width: 160)
                    Toggle("Visible on Wi-Fi (phone)", isOn: $lan)
                    Button("Apply") { monitor.restartServer() }
                }
                Text(lan ? "Open http://\(ProcessInfo.processInfo.hostName):\(String(port)) on your phone. Read-only, but anyone on this network can see usage."
                         : "Local only: http://127.0.0.1:\(String(port))")
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
    }
}

import ServiceManagement
enum SMAppServiceOpen { static func loginItems() { SMAppService.openSystemSettingsLoginItems() } }

struct IntegrationsTab: View {
    @EnvironmentObject var monitor: Monitor
    @State private var sinks = Integrations.load()
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(sinks) { s in
                        Label(s.kind.title, systemImage: s.kind.symbol)
                            .foregroundStyle(s.enabled ? .primary : .secondary).tag(s.id)
                    }
                }
                Divider()
                HStack {
                    Menu {
                        ForEach(SinkKind.allCases) { k in
                            Button { add(k) } label: { Label(k.title, systemImage: k.symbol) }
                        }
                    } label: { Image(systemName: "plus") }
                    .menuStyle(.borderlessButton).frame(width: 36)
                    Button { remove() } label: { Image(systemName: "minus") }
                        .buttonStyle(.borderless).disabled(selection == nil)
                    Spacer()
                }.padding(6)
            }
            .frame(width: 210)
            Divider()
            if let i = sinks.firstIndex(where: { $0.id == selection }) {
                SinkEditor(sink: $sinks[i]).id(sinks[i].id)
            } else {
                VStack(spacing: 10) {
                    Drip(mood: .focused, size: 44)
                    Text("Hook me up to your lights, your phone, anything.").font(.headline)
                    Text("Press + to add ntfy / Pushover / Telegram for phone pushes,\nHome Assistant, Hue or WLED for room lights,\nor a custom webhook for everything else.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary).font(.callout)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: sinks) { _, s in Integrations.save(s) }
    }

    func add(_ k: SinkKind) {
        var s = Sink(kind: k)
        if k == .ntfy { s.values = ["server": "https://ntfy.sh", "topic": "refill-" + UUID().uuidString.prefix(8).lowercased()] }
        if k == .homeAssistant { s.values = ["hook": "refill"] }
        if k == .webhook { s.values = ["method": "POST"] }
        sinks.append(s)
        selection = s.id
    }

    func remove() {
        sinks.removeAll { $0.id == selection }
        selection = nil
    }
}

struct SinkEditor: View {
    @EnvironmentObject var monitor: Monitor
    @Binding var sink: Sink
    @State private var status = ""
    @State private var testing = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $sink.enabled) { Label(sink.kind.title, systemImage: sink.kind.symbol).font(.headline) }
                if !sink.kind.help.isEmpty {
                    Text(sink.kind.help).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                }
            }
            Section("Settings") {
                ForEach(sink.kind.fields, id: \.key) { f in
                    let b = Binding(get: { sink.values[f.key] ?? "" }, set: { sink.values[f.key] = $0 })
                    if f.multiline {
                        VStack(alignment: .leading) {
                            Text(f.label).font(.caption)
                            TextEditor(text: b).font(.system(.body, design: .monospaced)).frame(height: 54)
                        }
                    } else if f.secret {
                        SecureField(f.label, text: b, prompt: Text(f.placeholder))
                    } else {
                        TextField(f.label, text: b, prompt: Text(f.placeholder))
                    }
                }
            }
            Section("Fire on") {
                Toggle("Reset (tank refilled)", isOn: $sink.onReset)
                Toggle("Warning (crossed threshold)", isOn: $sink.onWarning)
                Toggle("Empty (hit the limit)", isOn: $sink.onEmpty)
            }
            Section {
                HStack {
                    Button(testing ? "Sending…" : "Send test") {
                        testing = true
                        Task { status = await monitor.testSink(sink); testing = false }
                    }.disabled(testing)
                    Text(status).font(.caption.monospaced())
                        .foregroundStyle(status.hasPrefix("OK") ? .green : .orange).lineLimit(2)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct AccountsTab: View {
    @EnvironmentObject var monitor: Monitor
    @AppStorage(Prefs.K.codex) var codex = true
    @AppStorage(Prefs.K.extraDirs) var extraDirs = ""

    var body: some View {
        Form {
            Section("Detected") {
                ForEach(monitor.accounts) { a in
                    HStack {
                        Text(a.email ?? a.name)
                        Spacer()
                        Text(a.error == nil ? a.name : "needs login").foregroundStyle(a.error == nil ? Color.secondary : Color.orange)
                    }
                }
            }
            Section("Claude accounts") {
                Text("Each Claude login lives in its own config folder. ~/.claude and every ~/.claude-* folder are found automatically.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("CLAUDE_CONFIG_DIR=~/.claude-work claude    → then /login")
                    .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                VStack(alignment: .leading) {
                    Text("Extra folders (one per line)").font(.caption)
                    TextEditor(text: $extraDirs).font(.system(.body, design: .monospaced)).frame(height: 60)
                }
                Button("Rescan now") { Task { await monitor.refresh() } }
            }
            Section("Other tools") {
                Toggle("Codex CLI (reads ~/.codex/sessions, offline)", isOn: $codex)
            }
        }
        .formStyle(.grouped)
    }
}
