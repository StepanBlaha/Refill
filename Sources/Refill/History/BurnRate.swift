import Foundation

enum BurnRate {
    /// Linear regression of utilization over the last ~90 min inside the current window cycle.
    static func estimate(samples: [HistorySample], window: UsageWindow) -> (perHour: Double, runsOutAt: Date?)? {
        let now = Date()
        let cutoff = now.addingTimeInterval(-90 * 60)
        let pts = samples.filter { s in
            guard s.t >= cutoff else { return false }
            switch (s.resetsAt, window.resetsAt) {
            case let (a?, b?): return abs(a.timeIntervalSince(b)) <= 600
            case (nil, nil): return true
            default: return false
            }
        }.sorted { $0.t < $1.t }
        guard pts.count >= 2, let first = pts.first, let last = pts.last,
              last.t.timeIntervalSince(first.t) > 60 else { return nil }
        let t0 = first.t
        let xs = pts.map { $0.t.timeIntervalSince(t0) / 3600 }   // hours
        let ys = pts.map(\.utilization)
        let n = Double(pts.count)
        let mx = xs.reduce(0, +) / n, my = ys.reduce(0, +) / n
        var num = 0.0, den = 0.0
        for i in 0..<pts.count { num += (xs[i] - mx) * (ys[i] - my); den += (xs[i] - mx) * (xs[i] - mx) }
        guard den > 0 else { return nil }
        let slope = num / den
        guard slope > 0.01 else { return nil }
        let hoursLeft = max(0, 100 - window.utilization) / slope
        let out = now.addingTimeInterval(hoursLeft * 3600)
        if let r = window.resetsAt, out >= r { return (slope, nil) }
        return (slope, window.resetsAt == nil ? nil : out)
    }
}
