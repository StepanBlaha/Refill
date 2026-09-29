import Foundation
import Network

/// Tiny localhost HTTP server: GET / (dashboard), /status, /events.
final class StatusServer {
    private var listener: NWListener?
    private let provider: () -> (status: Data, events: Data)

    init(provider: @escaping () -> (status: Data, events: Data)) { self.provider = provider }

    /// lan=false binds loopback only; lan=true lets phones on the same Wi-Fi open the dashboard.
    func start(port: UInt16, lan: Bool) {
        stop()
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        if !lan { params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!) }
        guard let l = lan ? try? NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
                          : try? NWListener(using: params) else { return }
        l.newConnectionHandler = { [weak self] c in self?.handle(c) }
        l.start(queue: .global())
        listener = l
    }

    func stop() { listener?.cancel(); listener = nil }

    private func handle(_ c: NWConnection) {
        c.start(queue: .global())
        c.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self, let data, let req = String(data: data, encoding: .utf8) else { c.cancel(); return }
            let path = req.split(separator: " ").dropFirst().first.map(String.init) ?? "/"
            let (s, e) = DispatchQueue.main.sync { self.provider() }
            let (body, type): (Data, String) = switch path.split(separator: "?").first.map(String.init) {
            case "/status": (s, "application/json")
            case "/events": (e, "application/json")
            default: (Data(Dashboard.html.utf8), "text/html; charset=utf-8")
            }
            var head = "HTTP/1.1 200 OK\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\n"
            head += "Access-Control-Allow-Origin: *\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n"
            c.send(content: Data(head.utf8) + body, completion: .contentProcessed { _ in c.cancel() })
        }
    }
}
