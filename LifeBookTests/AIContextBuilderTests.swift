import XCTest
@testable import LifeBook

final class AIContextBuilderTests: XCTestCase {
    func testContextExcludesOldEntriesAndIncludesValues() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let recent = LifeEntry(
            timestamp: now.addingTimeInterval(-86_400),
            eventID: "weight",
            title: "体重",
            symbol: "scalemass",
            colorHex: "27AE60",
            kind: .measurement,
            value: 68.5,
            unit: "kg"
        )
        let old = LifeEntry(
            timestamp: now.addingTimeInterval(-40 * 86_400),
            eventID: "swim",
            title: "游泳",
            symbol: "figure.pool.swim",
            colorHex: "2F80ED"
        )

        let context = AIContextBuilder.makeContext(entries: [old, recent], now: now, days: 30)

        XCTAssertTrue(context.contains("体重"))
        XCTAssertTrue(context.contains("68.5kg"))
        XCTAssertFalse(context.contains("游泳"))
    }
}

