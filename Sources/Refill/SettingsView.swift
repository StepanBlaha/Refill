import SwiftUI
import ServiceManagement

enum SettingsTab: String, CaseIterable { case general = "General", history = "History", integrations = "Integrations", accounts = "Accounts" }

struct SettingsView: View {
    @State private var tab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            Segmented(items: SettingsTab.allCases.map { ($0, $0.rawValue) }, selection: $tab)
                .padding(.top, Space.s).padding(.bottom, Space.l)
            Rectangle().fill(Theme.line).frame(height: 1)
            Group {
                switch tab {
                case .general: Scrolling { GeneralTab() }
                case .history: HistoryView()
                case .integrations: IntegrationsTab()
                case .accounts: Scrolling { AccountsTab() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.ink)
        .frame(width: 640, height: 580)
    }
}

/// Standard page: black, 24pt gutters, 20pt between panels.
struct Scrolling<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { content }
                .padding(.horizontal, Space.xl).padding(.vertical, Space.l)
        }
        .scrollIndicators(.never)
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
    @AppStorage("notchEnabled") var notch = true
    @ObservedObject private var updates = UpdateChecker.shared
    @State private var login = LoginItem.isOn

    let sounds = ((try? FileManager.default.contentsOfDirectory(atPath: "/System/Library/Sounds")) ?? [])
        .map { ($0 as NSString).deletingPathExtension }.sorted()
    let hours = (0..<24).map { ($0, String(format: "%02d:00", $0)) }

    var body: some View {
        HStack(spacing: Space.m) {
            Drip(mood: monitor.mood, size: 40, level: monitor.lowestRemaining)
            VStack(alignment: .leading, spacing: 2) {
                Text("Refill").font(.system(size: 19, weight: .semibold))
                Text("Watches your AI limits and tells you when they refill.").font(.system(size: 12)).foregroundStyle(Theme.muted)
            }
        }

        Panel(title: "Startup") {
            ToggleRow(title: "Open at login", isOn: $login)
                .onChange(of: login) { _, on in LoginItem.set(on); login = LoginItem.isOn }
            if LoginItem.status == .requiresApproval {
                RowDivider()
                Row(title: "Needs approval in Login Items") {
                    Button("Open Settings") { SMAppService.openSystemSettingsLoginItems() }.buttonStyle(DarkButton())
                }
            }
        }

        Panel(title: "Alerts") {
            ToggleRow(title: "Notification", isOn: $notify)
            RowDivider()
            Row(title: "Sound") {
                DarkMenu(items: sounds.map { ($0, $0) }, selection: $soundName)
                    .onChange(of: soundName) { _, n in NSSound(named: NSSound.Name(n))?.play() }
                    .opacity(sound ? 1 : 0.4)
                Toggle("", isOn: $sound).labelsHidden().toggleStyle(RefillSwitch())
            }
            RowDivider()
            ToggleRow(title: "Notch", subtitle: "Drip slides out of the notch on events", isOn: $notch)
                .onChange(of: notch) { _, v in NotchController.shared.enabled = v }
            RowDivider()
            ToggleRow(title: "Hook script", subtitle: "~/.config/refill/on-reset", isOn: $hook)
            RowDivider()
            Row(title: "Try it") {
                Button("Preview notch") { NotchController.shared.preview() }.buttonStyle(DarkButton())
                Button("Send test") { monitor.sendTest() }.buttonStyle(DarkButton(prominent: true))
            }
        }

        Panel(title: "Quiet hours", footer: quiet ? "Sounds stay off. Lights and hooks still fire." : nil) {
            ToggleRow(title: "Quiet hours", isOn: $quiet)
            if quiet {
                RowDivider()
                Row(title: "From") { DarkMenu(items: hours, selection: $quietFrom); Text("to").foregroundStyle(Theme.muted).font(.system(size: 12)); DarkMenu(items: hours, selection: $quietTo) }
                RowDivider()
                ToggleRow(title: "Also mute phone and chat pushes", isOn: $quietPush)
            }
        }

        Panel(title: "Usage", footer: "An empty alert is always sent at 100%.") {
            Row(title: "Warn at", subtitle: "Used %, comma separated") {
                TextField("80, 95", text: $thresholds).textFieldStyle(DarkField()).frame(width: 90)
            }
            RowDivider()
            Row(title: "Check every") {
                Stepper("\(Int(poll)) min", value: $poll, in: 1...60).font(.system(size: 12)).fixedSize()
            }
        }

        Panel(title: "Dashboard", footer: lan ? "Anyone on this Wi-Fi can see your usage (read-only)." : nil) {
            Row(title: "Address", subtitle: "http://\(lan ? ProcessInfo.processInfo.hostName : "127.0.0.1"):\(String(port))") {
                Button("Open") { NSWorkspace.shared.open(URL(string: "http://127.0.0.1:\(port)")!) }.buttonStyle(DarkButton())
            }
            RowDivider()
            Row(title: "Port") {
                TextField("7788", value: $port, format: .number.grouping(.never)).textFieldStyle(DarkField()).frame(width: 80)
                    .onSubmit { if (1024...65535).contains(port) { monitor.restartServer() } else { port = 7788 } }
            }
            RowDivider()
            ToggleRow(title: "Visible on Wi-Fi", subtitle: "Open it from your phone", isOn: $lan)
                .onChange(of: lan) { _, _ in monitor.restartServer() }
        }

        Panel(title: "About") {
            Row(title: "Version", subtitle: "Refill is independent, not affiliated with Anthropic, OpenAI, GitHub, Cursor or Google.") {
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")
                    .font(.system(size: 12)).monospacedDigit().foregroundStyle(Theme.muted)
            }
            RowDivider()
            Row(title: "Updates", subtitle: updates.status.isEmpty ? "Checked daily from GitHub Releases" : updates.status) {
                if updates.available != nil {
                    Button("Download") { updates.download() }.buttonStyle(DarkButton(prominent: true))
                } else {
                    Button("Check now") { Task { await updates.check() } }.buttonStyle(DarkButton())
                }
            }
            RowDivider()
            Row(title: "Legal") {
                ForEach([("Privacy", "privacy/"), ("Terms", "terms/"), ("Notice", "notice/")], id: \.0) { i in
                    Button(i.0) { NSWorkspace.shared.open(URL(string: "https://stepanblaha.github.io/Refill/" + i.1)!) }.buttonStyle(DarkButton())
                }
            }
            RowDivider()
            Row(title: "Welcome tour") {
                Button("Show") { Onboarding.show(monitor: monitor) }.buttonStyle(DarkButton())
            }
        }
    }
}

struct AccountsTab: View {
    @EnvironmentObject var monitor: Monitor
    @AppStorage(Prefs.K.codex) var codex = true
    @AppStorage(Prefs.K.extraDirs) var extraDirs = ""
    @AppStorage(Prefs.K.extraCodex) var extraCodex = ""
    @AppStorage(Prefs.K.extraGemini) var extraGemini = ""
    @AppStorage("refreshTokens") var refreshTokens = true
    @State private var hiddenIds = AccountActions.hidden

    @State private var claudeName = ""
    @State private var claudeStatus = ""
    @State private var codexName = ""
    @State private var codexStatus = ""
    @State private var geminiName = ""
    @State private var geminiStatus = ""

    var body: some View {
        Panel(title: "Detected") {
            ForEach(Array(monitor.accounts.enumerated()), id: \.1.id) { i, a in
                if i > 0 { RowDivider() }
                Row(title: a.title, subtitle: a.error ?? a.detail) {
                    Circle().fill(a.error == nil ? Theme.accent : Theme.amber).frame(width: 6, height: 6)
                    Menu { AccountMenuItems(account: a) } label: {
                        Image(systemName: "ellipsis").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.muted)
                            .frame(width: 24, height: 20).contentShape(Rectangle())
                    }
                    .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
                    .onHover { ClickFeedback.cursor(hovering: $0, enabled: true) }
                }
                .contextMenu { AccountMenuItems(account: a) }
            }
            RowDivider()
            Row(title: "Rescan") { Button("Refresh") { Task { await monitor.refresh() } }.buttonStyle(DarkButton()) }
        }
        .onChange(of: monitor.accounts.map(\.id)) { _, _ in hiddenIds = AccountActions.hidden }

        if !hiddenIds.isEmpty {
            Panel(title: "Hidden", footer: "Hidden accounts aren't checked and never alert.") {
                ForEach(Array(hiddenIds.sorted().enumerated()), id: \.1) { i, id in
                    if i > 0 { RowDivider() }
                    Row(title: AccountNames.hiddenLabel(id)) {
                        Button("Show") { AccountActions.unhide(id, monitor: monitor); hiddenIds = AccountActions.hidden }
                            .buttonStyle(DarkButton())
                    }
                }
            }
        }

        Panel(title: "Add a Claude account", footer: "Opens Terminal with a separate Claude profile. Type /login there, then quit. Refill picks it up on the next refresh.") {
            Row(title: "Name") {
                TextField("work", text: $claudeName).textFieldStyle(DarkField()).frame(width: 140)
                Button("Add") { claudeStatus = AccountAdder.addClaude(name: claudeName); claudeName = "" }
                    .buttonStyle(DarkButton(prominent: true)).disabled(claudeName.isEmpty)
            }
            if !claudeStatus.isEmpty { RowDivider(); Row(title: claudeStatus) { EmptyView() } }
            RowDivider()
            Row(title: "Step-by-step help") {
                Button("Setup guide") { NSWorkspace.shared.open(Guides.url("accounts")) }.buttonStyle(DarkButton())
            }
        }

        Panel(title: "Extra Claude folders", footer: "~/.claude and every ~/.claude-* folder are found automatically. One path per line.") {
            TextEditor(text: $extraDirs).font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden).padding(Space.s).frame(height: 64)
        }

        Panel(title: "Codex CLI", footer: "Reads session logs offline. The default ~/.codex stays the account you already have. CODEX_HOME and every ~/.codex-* folder are found too.") {
            ToggleRow(title: "Codex CLI", subtitle: "Off skips every Codex home", isOn: $codex)
            RowDivider()
            Row(title: "Name") {
                TextField("work", text: $codexName).textFieldStyle(DarkField()).frame(width: 140)
                Button("Add") { codexStatus = AccountAdder.addCodex(name: codexName); codexName = "" }
                    .buttonStyle(DarkButton(prominent: true)).disabled(codexName.isEmpty)
            }
            if !codexStatus.isEmpty { RowDivider(); Row(title: codexStatus) { EmptyView() } }
        }

        Panel(title: "Extra Codex folders", footer: "One Codex home per line, if it is not ~/.codex or ~/.codex-*. ~ is fine.") {
            TextEditor(text: $extraCodex).font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden).padding(Space.s).frame(height: 64)
        }

        Panel(title: "Add a Gemini account", footer: "Opens Terminal with GEMINI_CLI_HOME set. Gemini CLI stores the login in that folder's .gemini directory. Sign in, then quit.") {
            Row(title: "Name") {
                TextField("work", text: $geminiName).textFieldStyle(DarkField()).frame(width: 140)
                Button("Add") { geminiStatus = AccountAdder.addGemini(name: geminiName); geminiName = "" }
                    .buttonStyle(DarkButton(prominent: true)).disabled(geminiName.isEmpty)
            }
            if !geminiStatus.isEmpty { RowDivider(); Row(title: geminiStatus) { EmptyView() } }
        }

        Panel(title: "Extra Gemini folders", footer: "One folder per line. A folder with oauth_creds.json, or a GEMINI_CLI_HOME whose .gemini child has that file. ~ is fine.") {
            TextEditor(text: $extraGemini).font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden).padding(Space.s).frame(height: 64)
        }

        ProvidersPanel()

        Panel(title: "Login renewal", footer: "When off, Refill never renews a Claude login itself. Safer if Claude Code runs all day; an idle account then shows \"Login expired\" until you run claude.") {
            ToggleRow(title: "Renew expired logins", isOn: $refreshTokens)
        }
    }
}
