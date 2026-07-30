import Foundation

struct EventFrequency: Equatable, Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

enum AnalyticsEngine {
    static func streak(
        timestamps: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let recordedDays = Set(timestamps.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: now)
        var count = 0

        while recordedDays.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previous
        }
        return count
    }

    static func frequencies(
        entries: [LifeEntry],
        now: Date = .now,
        days: Int = 30,
        calendar: Calendar = .current
    ) -> [EventFrequency] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? .distantPast
        return Dictionary(
            grouping: entries.filter { $0.timestamp >= cutoff && $0.timestamp <= now },
            by: \.title
        )
        .map { EventFrequency(name: $0.key, count: $0.value.count) }
        .sorted {
            if $0.count == $1.count { return $0.name < $1.name }
            return $0.count > $1.count
        }
    }
}
