import Foundation

enum EntryPresentation {
    static func coreItems(for entry: LifeEntry) -> [EntryDetailDisplayItem] {
        var items: [EntryDetailDisplayItem] = []
        if let value = entry.value {
            let formatted = value.formatted(
                .number.precision(.fractionLength(0...2))
            )
            let suffix = entry.unit.map { " \($0)" } ?? ""
            items.append(
                EntryDetailDisplayItem(
                    id: "value",
                    label: entry.kind == .rating ? "评分" : "数值",
                    value: "\(formatted)\(suffix)"
                )
            )
        }
        if let duration = entry.durationMinutes {
            items.append(
                EntryDetailDisplayItem(
                    id: "durationMinutes",
                    label: "时长",
                    value: durationText(minutes: duration, eventID: entry.eventID)
                )
            )
        }
        return items
    }

    static func detailItems(for entry: LifeEntry) -> [EntryDetailDisplayItem] {
        guard let schema = EntryDetailSchema.schema(for: entry.eventID) else {
            return []
        }
        return schema.displayItems(from: entry.details)
    }

    static func allItems(for entry: LifeEntry) -> [EntryDetailDisplayItem] {
        var items = coreItems(for: entry) + detailItems(for: entry)
        if !entry.note.isEmpty {
            items.append(
                EntryDetailDisplayItem(
                    id: "note",
                    label: entry.kind == .note ? "正文" : "备注",
                    value: entry.note
                )
            )
        }
        return items
    }

    static func summary(for entry: LifeEntry) -> String? {
        let core = coreItems(for: entry).map(\.value)
        let details = detailItems(for: entry).map { "\($0.label)：\($0.value)" }
        let note = entry.note.isEmpty
            ? []
            : ["\(entry.kind == .note ? "正文" : "备注")：\(entry.note)"]
        let parts = core + details + note
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func durationText(minutes: Int, eventID: String) -> String {
        EntryRecordingConfiguration(eventID: eventID)
            .durationText(minutes: minutes)
    }
}
