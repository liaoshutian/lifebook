import Charts
import SwiftData
import SwiftUI

struct AnalysisView: View {
    @Query(sort: \LifeEntry.timestamp) private var entries: [LifeEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCards
                frequencyCard
                latestMeasurements
            }
            .padding()
        }
        .navigationTitle("分析")
        .toolbar {
            NavigationLink {
                AIAssistantView()
            } label: {
                Image(systemName: "sparkles")
            }
            .accessibilityLabel("AI 助理")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            MetricCard(title: "本周记录", value: "\(thisWeekEntries.count)", symbol: "calendar.badge.checkmark")
            MetricCard(title: "连续记录", value: "\(streak) 天", symbol: "flame.fill")
        }
    }

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("近 30 天常用事件").font(.headline)
            if frequency.isEmpty {
                Text("开始记录后，这里会出现趋势。")
                    .foregroundStyle(.secondary)
            } else {
                Chart(Array(frequency.prefix(6))) { item in
                    BarMark(
                        x: .value("次数", item.count),
                        y: .value("事件", item.name)
                    )
                    .foregroundStyle(.accentBlue.gradient)
                    .annotation(position: .trailing) { Text("\(item.count)").font(.caption) }
                }
                .frame(height: 190)
            }
        }
        .cardStyle()
    }

    private var latestMeasurements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最新数值").font(.headline)
            let measurements = entries.filter { $0.kind == .measurement }.suffix(5).reversed()
            if measurements.isEmpty {
                Text("还没有体重等数值记录。").foregroundStyle(.secondary)
            } else {
                ForEach(Array(measurements)) { EntryRow(entry: $0) }
            }
        }
        .cardStyle()
    }

    private var thisWeekEntries: [LifeEntry] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return entries.filter { interval.contains($0.timestamp) }
    }

    private var frequency: [EventFrequency] {
        AnalyticsEngine.frequencies(entries: entries)
    }

    private var streak: Int {
        AnalyticsEngine.streak(timestamps: entries.map(\.timestamp))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(.accentBlue)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
