import XCTest
@testable import LifeBook

final class CalendarEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = 1
        return calendar
    }

    func testFebruaryLeapYearIncludesTwentyNineDays() throws {
        let month = try XCTUnwrap(calendar.date(from: DateComponents(year: 2024, month: 2, day: 15)))
        let days = CalendarEngine.days(in: month, calendar: calendar)
        let actualDates = days.compactMap { $0 }

        XCTAssertEqual(actualDates.count, 29)
        XCTAssertEqual(calendar.component(.day, from: actualDates.last!), 29)
    }

    func testMonthLeadingPlaceholdersRespectFirstWeekday() throws {
        let month = try XCTUnwrap(calendar.date(from: DateComponents(year: 2024, month: 9, day: 15)))
        let days = CalendarEngine.days(in: month, calendar: calendar)

        XCTAssertNotNil(days.first!)
    }

    func testReplacingTimePreservesSelectedDay() throws {
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 29)))
        let time = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2020, month: 1, day: 1, hour: 18, minute: 42, second: 5
        )))

        let result = CalendarEngine.replacingTime(of: day, with: time, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: result)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 29)
        XCTAssertEqual(components.hour, 18)
        XCTAssertEqual(components.minute, 42)
        XCTAssertEqual(components.second, 5)
    }

    func testChineseDateFormattingDoesNotDependOnDeviceLocale() throws {
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 7,
            day: 30,
            hour: 12
        )))

        XCTAssertEqual(ChineseDateFormatter.monthYear(date, timeZone: timeZone), "2026年7月")
        XCTAssertEqual(
            ChineseDateFormatter.fullDate(date, timeZone: timeZone),
            "2026年7月30日 星期四"
        )
        XCTAssertEqual(
            ChineseDateFormatter.lunarDate(date, timeZone: timeZone),
            "丙午年六月十七"
        )
    }
}
