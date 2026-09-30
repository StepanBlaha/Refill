import SwiftUI
import UserNotifications

struct StepFrame<Content: View>: View {
    let mood: Voice.Mood
    let title: String
    let line: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 10) {
            Drip(mood: mood, size: 76).padding(.top, 6)
            Text(title).font(Theme.rounded(26, .heavy))
            Text(line).font(Theme.rounded(14)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            content.padding(.top, 8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 44)
    }
}

struct WelcomeStep: View {
    var body: some View {
        StepFrame(mood: .party, title: "Hi, I'm Drip.",
                  line: "I watch your AI tanks so you don't have to.\nI'll ping you the second your limits refill.") {
            VStack(alignment: .leading, spacing: 10) {
                row("gauge.with.needle", "Live 5-hour and weekly usage for Claude and Codex")
                row("bell.badge.fill", "A nudge when a tank refills (or runs dry)")
                row("iphone.gen3", "Optional phone push and smart-light signals")
            }
            .padding(16).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
        }
    }
    private func row(_ s: String, _ t: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: s).foregroundStyle(Theme.lime).frame(width: 22)
            Text(t).font(Theme.rounded(13, .medium))
        }
    }
}

struct AccountsStep: View {
    @ObservedObject var monitor: Monitor
    @State private var name = ""
    @State private var adding = false
    @State private var status = ""

    var body: some View {
        StepFrame(mood: monitor.accounts.isEmpty ? .focused : .happy, title: "Your tanks",
                  line: monitor.accounts.isEmpty ? "Nothing yet. Log in to Claude Code or Codex and I'll find it."
                                                 : "Found these. More than one Claude login? Add it below.") {
            VStack(spacing: 10) {
                ScrollView {
                    VStack(spacing: 6) { ForEach(monitor.accounts) { accountRow($0) } }
                }.frame(maxHeight: 120)
                HStack {
                    OBPill(label: "Refresh", symbol: "arrow.clockwise") { Task { await monitor.refresh() } }
                    OBPill(label: "Add another Claude account", symbol: "plus") { adding.toggle() }
                }
                if adding {
                    HStack {
                        TextField("name, e.g. work", text: $name).textFieldStyle(.plain)
                            .font(Theme.mono(13)).padding(8)
                            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line))
                            .onSubmit(add)
                        OBPill(label: "Open Terminal", prominent: true, action: add)
                    }
                }
                if !status.isEmpty {
                    Text(status).font(Theme.rounded(12)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
            }
        }
    }

    private func add() { status = AccountAdder.addClaude(name: name) }

    private func accountRow(_ a: AccountSnapshot) -> some View {
        HStack {
            Image(systemName: a.provider == "codex" ? "chevron.left.forwardslash.chevron.right" : "sparkle")
                .foregroundStyle(Theme.lime).frame(width: 20)
            Text(a.name).font(Theme.rounded(13, .semibold))
            Text(a.email ?? a.plan ?? "").font(Theme.rounded(12)).foregroundStyle(Theme.muted).lineLimit(1)
            Spacer()
            if let e = a.error { Text(e).font(Theme.rounded(11)).foregroundStyle(Theme.coral).lineLimit(1) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
    }
}

struct NotificationsStep: View {
    @AppStorage(Prefs.K.sound) private var sound = true
    @State private var granted: Bool?

    var body: some View {
        StepFrame(mood: granted == true ? .party : .happy, title: "Tap on the shoulder",
                  line: "Let me send notifications so you know the moment a tank refills.") {
            VStack(spacing: 14) {
                if granted == true {
                    Label("Notifications on. Drip approves.", systemImage: "checkmark.circle.fill")
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.lime)
                } else {
                    OBPill(label: granted == false ? "Denied: enable in System Settings" : "Allow notifications",
                           symbol: "bell.fill", prominent: granted == nil, action: request)
                }
                Toggle("Play a sound", isOn: $sound).toggleStyle(.switch).tint(Theme.lime)
                    .font(Theme.rounded(13, .medium)).frame(width: 190)
            }
        }
        .task { granted = await currentStatus() }
    }

    private func currentStatus() async -> Bool? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        let s = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch s { case .authorized, .provisional: return true; case .denied: return false; default: return nil }
    }

    private func request() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        Task {
            let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            granted = ok
        }
    }
}
