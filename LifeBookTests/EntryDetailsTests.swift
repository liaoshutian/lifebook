import XCTest
@testable import LifeBook

final class EntryDetailsTests: XCTestCase {
    func testEveryPresetEventHasDedicatedDetailSchema() {
        let presetIDs = Set(PresetEvent.defaults.map(\.id))
        let schemaIDs = Set(EntryDetailSchema.presets.map(\.eventID))

        XCTAssertEqual(schemaIDs, presetIDs)
    }

    func testIllnessDetailsRoundTripAndUseChineseDisplayLabels() throws {
        let details = EntryDetails(values: [
            EntryDetailFieldID.illnessName.rawValue: .text("流感"),
            EntryDetailFieldID.illnessSymptoms.rawValue: .choices(["fever", "cough"]),
            EntryDetailFieldID.bodyTemperature.rawValue: .number(38.6),
            EntryDetailFieldID.illnessSeverity.rawValue: .choice("moderate"),
            EntryDetailFieldID.medication.rawValue: .text("退热药"),
            EntryDetailFieldID.careLevel.rawValue: .choice("clinic")
        ])

        let data = try JSONEncoder().encode(details)
        let decoded = try JSONDecoder().decode(EntryDetails.self, from: data)
        let items = try XCTUnwrap(
            EntryDetailSchema.schema(for: "illness")
        ).displayItems(from: decoded)

        XCTAssertEqual(decoded, details)
        XCTAssertTrue(items.contains(.init(id: "illnessName", label: "疾病或诊断名称", value: "流感")))
        XCTAssertTrue(items.contains(.init(id: "illnessSymptoms", label: "症状", value: "发热、咳嗽")))
        XCTAssertTrue(items.contains(.init(id: "bodyTemperature", label: "体温", value: "38.6 ℃")))
        XCTAssertTrue(items.contains(.init(id: "illnessSeverity", label: "严重程度", value: "中等")))
        XCTAssertTrue(items.contains(.init(id: "careLevel", label: "就医情况", value: "门诊")))
    }

    func testSleepTimeAndRatingAreFormattedForDisplay() throws {
        let details = EntryDetails(values: [
            EntryDetailFieldID.bedtime.rawValue: .time(23 * 60 + 15),
            EntryDetailFieldID.wakeTime.rawValue: .time(7 * 60 + 5),
            EntryDetailFieldID.sleepQuality.rawValue: .integer(4)
        ])

        let items = try XCTUnwrap(
            EntryDetailSchema.schema(for: "sleep")
        ).displayItems(from: details)

        XCTAssertTrue(items.contains(.init(id: "bedtime", label: "入睡时间", value: "23:15")))
        XCTAssertTrue(items.contains(.init(id: "wakeTime", label: "醒来时间", value: "07:05")))
        XCTAssertTrue(items.contains(.init(id: "sleepQuality", label: "睡眠质量", value: "4/5")))
    }

    func testSleepSchemaDoesNotSaveUnconfirmedDefaults() throws {
        let schema = try XCTUnwrap(EntryDetailSchema.schema(for: "sleep"))

        XCTAssertTrue(schema.defaultValues.isEmpty)
    }
}
