import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum EntryExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
    var contentType: UTType {
        switch self {
        case .json: return .json
        case .csv: return .commaSeparatedText
        }
    }
}

enum EntryExporter {
    static func data(
        for entries: [LifeEntry],
        format: EntryExportFormat
    ) throws -> Data {
        let records = entries
            .sorted { $0.timestamp < $1.timestamp }
            .map(ExportRecord.init)

        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(records)
        case .csv:
            let formatter = ISO8601DateFormatter()
            var rows = [
                [
                    "id", "timestamp", "event_id", "title", "kind", "value",
                    "unit", "duration_minutes", "details", "note"
                ]
            ]
            let recordRows: [[String]] = records.map {
                [
                    $0.id.uuidString,
                    formatter.string(from: $0.timestamp),
                    $0.eventID,
                    $0.title,
                    $0.kind,
                    $0.value.map { String($0) } ?? "",
                    $0.unit ?? "",
                    $0.durationMinutes.map { String($0) } ?? "",
                    $0.details
                        .map { "\($0.label)：\($0.value)" }
                        .joined(separator: "；"),
                    $0.note
                ]
            }
            rows += recordRows
            let csv = rows
                .map { $0.map(escapeCSV).joined(separator: ",") }
                .joined(separator: "\r\n") + "\r\n"
            return Data(csv.utf8)
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") ||
                value.contains("\n") || value.contains("\r")
        else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

struct EntryExportDocument: FileDocument {
    let data: Data

    static var readableContentTypes: [UTType] {
        [.json, .commaSeparatedText]
    }

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ExportRecord: Codable {
    let id: UUID
    let timestamp: Date
    let eventID: String
    let title: String
    let symbol: String
    let colorHex: String
    let kind: String
    let value: Double?
    let unit: String?
    let note: String
    let durationMinutes: Int?
    let details: [EntryDetailDisplayItem]
    let detailValues: [String: EntryDetailValue]

    init(_ entry: LifeEntry) {
        id = entry.id
        timestamp = entry.timestamp
        eventID = entry.eventID
        title = entry.title
        symbol = entry.symbol
        colorHex = entry.colorHex
        kind = entry.kindRawValue
        value = entry.value
        unit = entry.unit
        note = entry.note
        durationMinutes = entry.durationMinutes
        details = EntryPresentation.detailItems(for: entry)
        detailValues = entry.details.values
    }
}
