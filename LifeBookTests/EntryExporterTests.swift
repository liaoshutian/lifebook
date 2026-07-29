import XCTest
@testable import LifeBook

final class EntryExporterTests: XCTestCase {
    func testJSONRoundTripContainsAllPublicFields() throws {
        let entry = makeEntry(note: "状态很好")
        let data = try EntryExporter.data(for: [entry], format: .json)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        ).first

        XCTAssertEqual(object?["eventID"] as? String, "weight")
        XCTAssertEqual(object?["title"] as? String, "体重")
        XCTAssertEqual(object?["value"] as? Double, 68.5)
        XCTAssertEqual(object?["note"] as? String, "状态很好")
    }

    func testCSVEscapesCommaQuoteAndNewline() throws {
        let entry = makeEntry(note: "很好,\"继续\"\n明天")
        let data = try EntryExporter.data(for: [entry], format: .csv)
        let csv = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(csv.hasPrefix("id,timestamp,event_id,title,kind"))
        XCTAssertTrue(csv.contains("\"很好,\"\"继续\"\"\n明天\""))
        XCTAssertTrue(csv.hasSuffix("\r\n"))
    }

    func testExportSortsEntriesOldestFirst() throws {
        let newer = makeEntry(id: UUID(), timestamp: Date(timeIntervalSince1970: 200))
        let older = makeEntry(id: UUID(), timestamp: Date(timeIntervalSince1970: 100))
        let data = try EntryExporter.data(for: [newer, older], format: .json)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        XCTAssertEqual(object.first?["id"] as? String, older.id.uuidString)
    }

    private func makeEntry(
        id: UUID = UUID(),
        timestamp: Date = Date(timeIntervalSince1970: 1_900_000_000),
        note: String = ""
    ) -> LifeEntry {
        LifeEntry(
            id: id,
            timestamp: timestamp,
            eventID: "weight",
            title: "体重",
            symbol: "scalemass.fill",
            colorHex: "27AE60",
            kind: .measurement,
            value: 68.5,
            unit: "kg",
            note: note
        )
    }
}
