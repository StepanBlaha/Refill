import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: Monitor
    @AppStorage(Prefs.K.notify) var notify = true
    @AppStorage(Prefs.K.sound) var sound = true
    @AppStorage(Prefs.K.soundName) var soundName = "Glass"
    @AppStorage(Prefs.K.hook) var hook = true
    @AppStorage(Prefs.K.webhook) var webhook = ""
    @AppStorage(Prefs.K.poll) var poll = 5.0
    @AppStorage(Prefs.K.codex) var codex = true
    @AppStorage(Prefs.K.port) var port = 7788
    @AppStorage(Prefs.K.extraDirs) var extraDirs = ""

    let sounds = ((try? FileManager.default.contentsOfDirectory(atPath: "/System/Library/Sounds")) ?? [])
        .map { ($0 as NSString).deletingPathExtension }.sorted()

    var body: some View {
        Form {
            Section("Signals on reset") {
                Toggle("macOS notification", isOn: $notify)
                HStack {
                    Toggle("Sound", isOn: $sound)
                    Picker("", selection: $soundName) { ForEach(sounds, id: \.self) { Text($0) } }
                        .labelsHidden().frame(width: 140)
                        .onChange(of: soundName) { _, n in NSSound(named: NSSound.Name(n))?.play() }
                }
                Toggle("Run hook  ~/.config/refill/on-reset", isOn: $hook)
                TextField("Webhook URL (POST JSON)", text: $webhook)
                Text("Also always: distributed notification `cz.stepanblaha.refill.reset`, ~/.config/refill/status.json + events.jsonl, dashboard on localhost.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Sources") {
                Toggle("Codex CLI (reads ~/.codex/sessions)", isOn: $codex)
                Stepper("Poll every \(Int(poll)) min", value: $poll, in: 1...60)
                HStack {
                    TextField("Dashboard port", value: $port, format: .number.grouping(.never))
                    Button("Apply") { monitor.restartServer() }
                }
                VStack(alignment: .leading) {
                    Text("Extra Claude config dirs (one per line)").font(.caption)
                    TextEditor(text: $extraDirs).font(.body.monospaced()).frame(height: 60)
                }
                Text("Add another Claude account:  CLAUDE_CONFIG_DIR=~/.claude-work claude  → /login. ~/.claude-* dirs are picked up automatically.")
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 560)
    }
}
