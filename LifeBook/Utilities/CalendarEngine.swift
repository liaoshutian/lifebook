import Foundation

enum CalendarEngine {
    static func days(
        in month: Date,
        calendar: Calendar = .current
    ) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let dates = range.map {
            calendar.date(byAdding: .day, value: $0 - 1, to: interval.start)
        }
        return Array(repeating: nil, count: leading) + dates
    }

    static func replacingTime(
        of date: Date,
        with time: Date,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.hour, .minute, .second], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 12,
            minute: components.minute ?? 0,
            second: components.second ?? 0,
            of: date
        ) ?? date
    }
}
