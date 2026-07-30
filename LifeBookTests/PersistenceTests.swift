import SwiftData
import XCTest
@testable import LifeBook

final class PersistenceTests: XCTestCase {
    @MainActor
    func testEntryAndCustomEventPersistInModelContainer() throws {
        let schema = Schema([LifeEntry.self, EventDefinition.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext
        let definition = EventDefinition(
            title: "冥想",
            symbol: "star.fill",
            colorHex: "2F80ED",
            kind: .duration,
            unit: "分钟"
        )
        let entry = LifeEntry(
            eventID: definition.id,
            title: definition.title,
            symbol: definition.symbol,
            colorHex: definition.colorHex,
            kind: definition.kind,
            durationMinutes: 20,
            details: EntryDetails(values: [
                EntryDetailFieldID.swimDistance.rawValue: .number(1_000),
                EntryDetailFieldID.swimStroke.rawValue: .choice("freestyle")
            ])
        )

        context.insert(definition)
        context.insert(entry)
        try context.save()

        let definitions = try context.fetch(FetchDescriptor<EventDefinition>())
        let entries = try context.fetch(FetchDescriptor<LifeEntry>())
        XCTAssertEqual(definitions.count, 1)
        XCTAssertEqual(definitions.first?.preset.title, "冥想")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.durationMinutes, 20)
        XCTAssertEqual(
            entries.first?.details[EntryDetailFieldID.swimDistance.rawValue],
            .number(1_000)
        )
    }
}
