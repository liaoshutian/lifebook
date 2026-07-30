import Foundation
import SwiftData

enum EntryKind: String, Codable, CaseIterable {
    case occurrence
    case measurement
    case duration
    case rating
    case note
}

@Model
final class LifeEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var eventID: String
    var title: String
    var symbol: String
    var colorHex: String
    var kindRawValue: String
    var value: Double?
    var unit: String?
    var note: String
    var durationMinutes: Int?
    var detailPayload: Data?

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRawValue) ?? .occurrence }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        eventID: String,
        title: String,
        symbol: String,
        colorHex: String,
        kind: EntryKind = .occurrence,
        value: Double? = nil,
        unit: String? = nil,
        note: String = "",
        durationMinutes: Int? = nil,
        details: EntryDetails = EntryDetails()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventID = eventID
        self.title = title
        self.symbol = symbol
        self.colorHex = colorHex
        self.kindRawValue = kind.rawValue
        self.value = value
        self.unit = unit
        self.note = note
        self.durationMinutes = durationMinutes
        self.detailPayload = details.isEmpty ? nil : try? JSONEncoder().encode(details)
    }

    var details: EntryDetails {
        get {
            guard let detailPayload else { return EntryDetails() }
            return (try? JSONDecoder().decode(EntryDetails.self, from: detailPayload))
                ?? EntryDetails()
        }
        set {
            detailPayload = newValue.isEmpty
                ? nil
                : try? JSONEncoder().encode(newValue)
        }
    }
}
