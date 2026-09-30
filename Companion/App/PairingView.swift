import SwiftUI
import Network

/// Optional Bonjour scan for `_http._tcp` services on the LAN.
@MainActor
final class BonjourScanner: ObservableObject {
    @Published var found: [String] = []
    private var browser: NWBrowser?

    func start() {
        stop(); found = []
        let b = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: .tcp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            let names = results.compactMap { r -> String? in
                if case let .service(name, _, _, _) = r.endpoint { return name }
                return nil
            }.sorted()
            Task { @MainActor in self?.found = names }
        }
        b.start(queue: .main)
        browser = b
    }

    func stop() { browser?.cancel(); browser = nil }
}

struct PairingView: View {
    @EnvironmentObject var store: Store
    @StateObject private var scanner = BonjourScanner()
    @State private var input = ""
    @State private var testing = false
    @State private var message: String?
    @State private var ok = false
    var onDone: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Drip(mood: ok ? .party : .happy, size: 96).padding(.top, 40)
                    Text("Pair with your Mac").font(Theme.rounded(26, .bold)).foregroundStyle(Theme.text)
                    Text("On your Mac, open Refill and turn on \"Visible on Wi-Fi\". Then enter its name below.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)

                    TextField("Stepans-MacBook.local", text: $input)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(14).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
                        .foregroundStyle(Theme.text)

                    if !scanner.found.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NEARBY").font(Theme.mono(11)).foregroundStyle(Theme.muted)
                            ForEach(scanner.found, id: \.self) { n in
                                Button { input = n.replacingOccurrences(of: " ", with: "-") + ".local" } label: {
                                    Text(n).font(Theme.rounded(15)).foregroundStyle(Theme.text)
                                        .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    Button("Scan for Macs") { scanner.start() }
                        .font(Theme.rounded(14, .medium)).foregroundStyle(Theme.muted)

                    if let message {
                        Text(message).font(Theme.rounded(13)).foregroundStyle(ok ? Theme.lime : Theme.coral)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await connect() }
                    } label: {
                        HStack { if testing { ProgressView().tint(Theme.ink) }; Text(testing ? "Testing…" : "Test & connect") }
                            .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity).padding(15)
                            .background(Theme.lime, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || testing)
                }
                .padding(24)
            }
        }
        .onAppear { input = store.host }
        .onDisappear { scanner.stop() }
    }

    private func connect() async {
        testing = true; message = nil
        let err = await store.test(host: input)
        testing = false
        if let err { ok = false; message = err; return }
        ok = true; message = "Connected. Drip is thrilled."
        try? await Task.sleep(for: .milliseconds(600))
        store.host = input.trimmingCharacters(in: .whitespaces)
        store.startPolling()
        onDone?()
    }
}
