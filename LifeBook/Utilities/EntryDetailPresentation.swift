import Foundation

extension EntryDetailField {
    func formatted(_ value: EntryDetailValue) -> String? {
        switch (kind, value) {
        case (.text, .text(let text)):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case (.decimal(let unit, _), .number(let number)):
            let formatted = number.formatted(
                .number.precision(.fractionLength(0...2))
            )
            return "\(formatted) \(unit)"
        case (.integer(let unit, _), .integer(let number)):
            return "\(number) \(unit)"
        case (.choice(let options), .choice(let choice)):
            return options.first { $0.id == choice }?.title ?? choice
        case (.choices(let options), .choices(let choices)):
            let known = options
                .filter { choices.contains($0.id) }
                .map(\.title)
            let knownIDs = Set(options.map(\.id))
            let unknown = choices.filter { !knownIDs.contains($0) }
            return (known + unknown).joined(separator: "、")
        case (.rating, .integer(let rating)):
            return "\(rating)/5"
        case (.time(_), .time(let minutes)):
            let normalized = ((minutes % (24 * 60)) + (24 * 60)) % (24 * 60)
            return String(
                format: "%02d:%02d",
                normalized / 60,
                normalized % 60
            )
        default:
            return nil
        }
    }
}
