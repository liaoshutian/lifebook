import Foundation

enum EntryDetailValue: Codable, Equatable {
    case text(String)
    case number(Double)
    case choice(String)
    case choices([String])
    case integer(Int)
    case time(Int)

    private enum ValueType: String, Codable {
        case text
        case number
        case choice
        case choices
        case integer
        case time
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case number
        case choice
        case choices
        case integer
        case minutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ValueType.self, forKey: .type) {
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .number:
            self = .number(try container.decode(Double.self, forKey: .number))
        case .choice:
            self = .choice(try container.decode(String.self, forKey: .choice))
        case .choices:
            self = .choices(try container.decode([String].self, forKey: .choices))
        case .integer:
            self = .integer(try container.decode(Int.self, forKey: .integer))
        case .time:
            self = .time(try container.decode(Int.self, forKey: .minutes))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode(ValueType.text, forKey: .type)
            try container.encode(value, forKey: .text)
        case .number(let value):
            try container.encode(ValueType.number, forKey: .type)
            try container.encode(value, forKey: .number)
        case .choice(let value):
            try container.encode(ValueType.choice, forKey: .type)
            try container.encode(value, forKey: .choice)
        case .choices(let value):
            try container.encode(ValueType.choices, forKey: .type)
            try container.encode(value, forKey: .choices)
        case .integer(let value):
            try container.encode(ValueType.integer, forKey: .type)
            try container.encode(value, forKey: .integer)
        case .time(let value):
            try container.encode(ValueType.time, forKey: .type)
            try container.encode(value, forKey: .minutes)
        }
    }
}

struct EntryDetails: Codable, Equatable {
    let version: Int
    var values: [String: EntryDetailValue]

    init(values: [String: EntryDetailValue] = [:]) {
        version = 1
        self.values = values
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        values = try container.decode(
            [String: EntryDetailValue].self,
            forKey: .values
        )
    }

    subscript(_ fieldID: String) -> EntryDetailValue? {
        get { values[fieldID] }
        set { values[fieldID] = newValue }
    }

    subscript(_ fieldID: EntryDetailFieldID) -> EntryDetailValue? {
        get { values[fieldID.rawValue] }
        set { values[fieldID.rawValue] = newValue }
    }

    var isEmpty: Bool {
        values.isEmpty
    }
}

enum EntryDetailFieldID: String {
    case swimStroke
    case swimDistance
    case swimIntensity
    case swimVenue
    case haircutService
    case haircutShop
    case haircutCost
    case haircutSatisfaction
    case illnessName
    case illnessSymptoms
    case bodyTemperature
    case illnessSeverity
    case medication
    case careLevel
    case mealOccasion
    case cuisine
    case restaurant
    case companions
    case mealCost
    case mealSatisfaction
    case measurementState
    case bodyFatPercentage
    case waistCircumference
    case muscleMass
    case sleepType
    case bedtime
    case wakeTime
    case sleepQuality
    case wakeUpCount
    case emotions
    case energyLevel
    case stressLevel
    case moodTrigger
    case diaryTitle
    case weather
    case location
    case diaryTags
    case gratitude
}
