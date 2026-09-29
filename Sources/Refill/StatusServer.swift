import Foundation
import Network

/// Tiny localhost HTTP server: GET / (dashboard), /status, /events.
final class StatusServer {
    private var listener: NWListener?
    private let provider: () -> (status: Data, events: Data)

    init(provider: @escaping () -> (status: Data, events: Data)) { self.provider = provider }

    func start(port: UInt16) {
        stop()
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!)
        guard let l = try? NWListener(using: params) else { return }
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

enum Dashboard {
    static let html = """
    <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
    <title>Refill</title><style>
    :root{color-scheme:dark;--bg:#0b0b0c;--card:#161618;--fg:#f2f2f2;--mut:#8a8a90;--ok:#4ade80;--warn:#fbbf24;--hot:#f87171}
    body{margin:0;background:var(--bg);color:var(--fg);font:15px -apple-system,system-ui,sans-serif;padding:32px 16px;transition:background .6s}
    body.flash{background:#14361f}
    h1{font-size:22px;margin:0 0 20px;max-width:720px;margin-inline:auto}
    .grid{display:grid;gap:14px;max-width:720px;margin:auto}
    .card{background:var(--card);border-radius:14px;padding:16px 18px}
    .top{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:10px}
    .name{font-weight:600}.mut{color:var(--mut);font-size:13px}
    .row{display:grid;grid-template-columns:110px 1fr 90px;gap:10px;align-items:center;margin:6px 0;font-size:13px}
    .bar{height:8px;border-radius:4px;background:#2a2a2e;overflow:hidden}.bar i{display:block;height:100%}
    .err{color:var(--hot);font-size:13px}#log{max-width:720px;margin:24px auto;font-size:13px;color:var(--mut)}
    </style></head><body><h1>Refill</h1><div class="grid" id="g"></div><div id="log"></div><script>
    let last=null;const col=u=>u>=90?'var(--hot)':u>=70?'var(--warn)':'var(--ok)';
    const left=d=>{if(!d)return'';let s=Math.max(0,(new Date(d)-Date.now())/1e3|0),h=s/3600|0,m=(s%3600)/60|0;return h>23?`${h/24|0}d ${h%24}h`:h?`${h}h ${m}m`:`${m}m`};
    function beep(){try{const a=new AudioContext(),o=a.createOscillator(),g=a.createGain();o.connect(g);g.connect(a.destination);o.frequency.value=880;g.gain.setValueAtTime(.2,a.currentTime);g.gain.exponentialRampToValueAtTime(.001,a.currentTime+.6);o.start();o.stop(a.currentTime+.6)}catch(e){}}
    async function tick(){try{
     const s=await (await fetch('/status')).json();
     document.getElementById('g').innerHTML=s.accounts.map(a=>`<div class=card><div class=top><span class=name>${a.name}</span><span class=mut>${[a.email,a.plan].filter(Boolean).join(' · ')}</span></div>`+
      (a.error?`<div class=err>${a.error}</div>`:'')+a.windows.map(w=>`<div class=row><span>${w.label}</span><div class=bar><i style="width:${Math.min(100,w.utilization)}%;background:${col(w.utilization)}"></i></div><span class=mut>${Math.round(w.utilization)}% · ${left(w.resetsAt)}</span></div>`).join('')+`</div>`).join('');
     const ev=await (await fetch('/events')).json();
     const top=ev[ev.length-1];if(top){const k=top.detectedAt+top.accountId+top.window;if(last&&k!==last){document.body.classList.add('flash');beep();setTimeout(()=>document.body.classList.remove('flash'),4000)}last=k}else last='';
     document.getElementById('log').innerHTML=ev.slice(-8).reverse().map(e=>`<div>${new Date(e.detectedAt).toLocaleString()} — ${e.accountName} ${e.windowLabel} reset (${e.reason})</div>`).join('');
    }catch(e){}}
    tick();setInterval(tick,5000);</script></body></html>
    """
}
