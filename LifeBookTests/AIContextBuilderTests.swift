import XCTest
@testable import LifeBook

final class AIContextBuilderTests: XCTestCase {
    func testContextExcludesOldEntriesAndIncludesValues() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let recent = LifeEntry(
            timestamp: now.addingTimeInterval(-86_400),
            eventID: "illness",
            title: "生病",
            symbol: "cross.case.fill",
            colorHex: "EB5757",
            details: EntryDetails(values: [
                EntryDetailFieldID.illnessSymptoms.rawValue: .choices(["fever", "cough"]),
                EntryDetailFieldID.bodyTemperature.rawValue: .number(38.6),
                EntryDetailFieldID.careLevel.rawValue: .choice("clinic")
            ])
        )
        let old = LifeEntry(
            timestamp: now.addingTimeInterval(-40 * 86_400),
            eventID: "swim",
            title: "游泳",
            symbol: "figure.pool.swim",
            colorHex: "2F80ED"
        )

        let context = AIContextBuilder.makeContext(entries: [old, recent], now: now, days: 30)

        XCTAssertTrue(context.contains("生病"))
        XCTAssertTrue(context.contains("症状：发热、咳嗽"))
        XCTAssertTrue(context.contains("体温：38.6 ℃"))
        XCTAssertTrue(context.contains("就医情况：门诊"))
        XCTAssertFalse(context.contains("游泳"))
    }
}
