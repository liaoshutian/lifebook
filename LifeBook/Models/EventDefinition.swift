import Foundation
import SwiftData

@Model
final class EventDefinition {
    @Attribute(.unique) var id: String
    var title: String
    var symbol: String
    var colorHex: String
    var kindRawValue: String
    var unit: String?
    var sortOrder: Int
    var isQuickRecordEnabled: Bool

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRawValue) ?? .occurrence }
        set { kindRawValue = newValue.rawValue }
    }

    var preset: PresetEvent {
        PresetEvent(
            id: id,
            title: title,
            symbol: symbol,
            colorHex: colorHex,
            kind: kind,
            unit: unit
        )
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        symbol: String,
        colorHex: String,
        kind: EntryKind,
        unit: String? = nil,
        sortOrder: Int = 0,
        isQuickRecordEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.colorHex = colorHex
        self.kindRawValue = kind.rawValue
        self.unit = unit
        self.sortOrder = sortOrder
        self.isQuickRecordEnabled = isQuickRecordEnabled
    }
}
