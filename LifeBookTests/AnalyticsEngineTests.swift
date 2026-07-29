import XCTest
@testable import LifeBook

final class AnalyticsEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testStreakCountsConsecutiveDaysEndingToday() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 29, hour: 12
        )))
        let timestamps = [0, 1, 2].compactMap {
            calendar.date(byAdding: .day, value: -$0, to: now)
        }

        XCTAssertEqual(
            AnalyticsEngine.streak(timestamps: timestamps, now: now, calendar: calendar),
            3
        )
    }

    func testStreakIsZeroWhenTodayHasNoEntry() throws {
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 7, day: 29, hour: 12
        )))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: now))

        XCTAssertEqual(
            AnalyticsEngine.streak(timestamps: [yesterday], now: now, calendar: calendar),
            0
        )
    }

    func testFrequenciesExcludeFutureAndOldEntriesAndSortTies() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let entries = [
            entry(title: "游泳", timestamp: now.addingTimeInterval(-86_400)),
            entry(title: "游泳", timestamp: now.addingTimeInterval(-2 * 86_400)),
            entry(title: "理发", timestamp: now.addingTimeInterval(-3 * 86_400)),
            entry(title: "大餐", timestamp: now.addingTimeInterval(-3 * 86_400)),
            entry(title: "旧记录", timestamp: now.addingTimeInterval(-40 * 86_400)),
            entry(title: "未来", timestamp: now.addingTimeInterval(86_400))
        ]

        let result = AnalyticsEngine.frequencies(
            entries: entries,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            [
                EventFrequency(name: "游泳", count: 2),
                EventFrequency(name: "大餐", count: 1),
                EventFrequency(name: "理发", count: 1)
            ]
        )
    }

    private func entry(title: String, timestamp: Date) -> LifeEntry {
        LifeEntry(
            timestamp: timestamp,
            eventID: UUID().uuidString,
            title: title,
            symbol: "star",
            colorHex: "000000"
        )
    }
}
