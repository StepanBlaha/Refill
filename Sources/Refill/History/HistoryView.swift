import SwiftUI
import Charts

private enum Range: String, CaseIterable, Identifiable {
    case day = "24h", week = "7d"
    var id: String { rawValue }
    var seconds: TimeInterval { self == .day ? 86400 : 7 * 86400 }
}

struct HistoryView: View {
    @ObservedObject private var store = HistoryStore.shared
    @State private var accountId: String = ""
    @State private var windowKey: String = ""
    @State private var range: Range = .day

    private var accounts: [(id: String, name: String)] { store.accounts }
    private var windows: [(key: String, label: String)] { store.windows(accountId: accountId) }
    private var since: Date { Date().addingTimeInterval(-range.seconds) }
    private var series: [HistorySample] { store.series(accountId: accountId, windowKey: windowKey, since: since) }

    /// Distinct cycle-end moments (resetsAt rounded to 10 min) that already passed.
    private func cycleEnds(_ s: [HistorySample]) -> [Date] {
        var seen = Set<Int>(); var out: [Date] = []
        for x in s { if let r = x.resetsAt, seen.insert(Int(r.timeIntervalSince1970 / 600)).inserted { out.append(r) } }
        return out.sorted()
    }
    private var resetMoments: [Date] { cycleEnds(series).filter { $0 <= Date() && $0 >= since } }
    private var resetsToday: Int {
        let start = Calendar.current.startOfDay(for: Date())
        return cycleEnds(store.series(accountId: accountId, windowKey: windowKey, since: start.addingTimeInterval(-3600)))
            .filter { $0 >= start && $0 <= Date() }.count
    }
    private var avgPeak: Double? {
        var peaks: [Int: Double] = [:]
        for x in series { if let r = x.resetsAt { let k = Int(r.timeIntervalSince1970 / 600); peaks[k] = max(peaks[k] ?? 0, x.utilization) } }
        return peaks.isEmpty ? nil : peaks.values.reduce(0, +) / Double(peaks.count)
    }
    private var daily: [(day: Date, peak: Double)] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date().addingTimeInterval(-6 * 86400))
        var m: [Date: Double] = [:]
        for x in store.series(accountId: accountId, windowKey: windowKey, since: start) {
            let d = cal.startOfDay(for: x.t); m[d] = max(m[d] ?? 0, x.utilization)
        }
        return (0..<7).compactMap { i in cal.date(byAdding: .day, value: i, to: start) }.map { ($0, m[$0] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if series.isEmpty && store.samples.isEmpty {
                Text("No history yet. Samples are recorded as usage is refreshed.")
                    .font(Theme.mono(11)).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 200)
            } else {
                mainChart.frame(height: 170)
                stats
                Text("Daily peak (7d)").font(Theme.mono(10)).foregroundStyle(.secondary)
                dailyChart.frame(height: 90)
            }
        }
        .padding(16)
        .frame(minWidth: 580, minHeight: 480, alignment: .topLeading)
        .onAppear(perform: ensureSelection)
        .onChange(of: accountId) { _, _ in windowKey = windows.first?.key ?? "" }
    }

    private func ensureSelection() {
        if accountId.isEmpty || !accounts.contains(where: { $0.id == accountId }) { accountId = accounts.first?.id ?? "" }
        if windowKey.isEmpty || !windows.contains(where: { $0.key == windowKey }) { windowKey = windows.first?.key ?? "" }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Picker("Account", selection: $accountId) {
                ForEach(accounts, id: \.id) { Text($0.name).tag($0.id) }
            }.labelsHidden().frame(maxWidth: 180)
            Picker("Window", selection: $windowKey) {
                ForEach(windows, id: \.key) { Text($0.label).tag($0.key) }
            }.labelsHidden().frame(maxWidth: 140)
            Spacer()
            Picker("Range", selection: $range) {
                ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).labelsHidden().frame(width: 110)
        }
    }

    private var mainChart: some View {
        Chart {
            ForEach(series, id: \.self) { s in
                AreaMark(x: .value("Time", s.t), y: .value("Used", s.utilization))
                    .foregroundStyle(LinearGradient(colors: [Theme.lime.opacity(0.18), Theme.lime.opacity(0.0)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", s.t), y: .value("Used", s.utilization))
                    .foregroundStyle(Theme.amber).interpolationMethod(.monotone)
            }
            ForEach(resetMoments, id: \.self) { r in
                RuleMark(x: .value("Reset", r)).foregroundStyle(Theme.lime.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            RuleMark(y: .value("Limit", 90)).foregroundStyle(Theme.coral.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: since...Date())
    }

    private var dailyChart: some View {
        Chart(daily, id: \.day) { d in
            BarMark(x: .value("Day", d.day, unit: .day), y: .value("Peak", d.peak))
                .foregroundStyle(Theme.level(used: d.peak)).cornerRadius(3)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
    }

    private var stats: some View {
        let f = store.forecast(accountId: accountId, windowKey: windowKey)
        let time = DateFormatter(); time.dateFormat = "HH:mm"
        return HStack(spacing: 8) {
            stat("Burn", f.map { "~\(Int($0.perHour.rounded()))%/h" } ?? "idle")
            stat("Forecast", f == nil ? "no trend" : (f!.runsOutAt.map { "Runs out ~\(time.string(from: $0))" } ?? "Won't run out before refill"))
            stat("Resets today", "\(resetsToday)")
            stat("Avg peak / window", avgPeak.map { "\(Int($0.rounded()))%" } ?? "-")
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(Theme.mono(9)).foregroundStyle(.secondary)
            Text(value).font(Theme.rounded(12, .semibold)).lineLimit(2).minimumScaleFactor(0.8)
        }
        .padding(8).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
    }
}

struct BurnBadge: View {
    let accountId: String
    let windowKey: String
    @ObservedObject private var store = HistoryStore.shared

    var body: some View {
        if let f = store.forecast(accountId: accountId, windowKey: windowKey) {
            let time = DateFormatter()
            let _ = time.dateFormat = "HH:mm"
            let tail = f.runsOutAt.map { " · empty \(time.string(from: $0))" } ?? ""
            Text("🔥 \(Int(f.perHour.rounded()))%/h\(tail)")
                .font(Theme.mono(10)).foregroundStyle(f.runsOutAt == nil ? Theme.muted : Theme.amber)
        }
    }
}
