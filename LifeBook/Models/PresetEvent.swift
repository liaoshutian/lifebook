import Foundation

enum PresetEventID: String, CaseIterable {
    case swim
    case haircut
    case illness
    case feast
    case weight
    case sleep
    case mood
    case diary
}

struct PresetEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let colorHex: String
    let kind: EntryKind
    let unit: String?

    static let defaults: [PresetEvent] = [
        .init(id: PresetEventID.swim.rawValue, title: "游泳", symbol: "figure.pool.swim", colorHex: "2F80ED", kind: .duration, unit: "分钟"),
        .init(id: PresetEventID.haircut.rawValue, title: "理发", symbol: "scissors", colorHex: "8E7CC3", kind: .occurrence, unit: nil),
        .init(id: PresetEventID.illness.rawValue, title: "生病", symbol: "cross.case.fill", colorHex: "EB5757", kind: .occurrence, unit: nil),
        .init(id: PresetEventID.feast.rawValue, title: "大餐", symbol: "fork.knife", colorHex: "F2994A", kind: .occurrence, unit: nil),
        .init(id: PresetEventID.weight.rawValue, title: "体重", symbol: "scalemass.fill", colorHex: "27AE60", kind: .measurement, unit: "kg"),
        .init(id: PresetEventID.sleep.rawValue, title: "睡眠", symbol: "moon.zzz.fill", colorHex: "4C5B9B", kind: .duration, unit: "小时"),
        .init(id: PresetEventID.mood.rawValue, title: "心情", symbol: "face.smiling.fill", colorHex: "F2C94C", kind: .rating, unit: "分"),
        .init(id: PresetEventID.diary.rawValue, title: "日记", symbol: "book.pages.fill", colorHex: "3D5A80", kind: .note, unit: nil)
    ]

    var recordingConfiguration: EntryRecordingConfiguration {
        EntryRecordingConfiguration(eventID: id)
    }
}

struct EntryRecordingConfiguration {
    let initialDurationMinutes: Int
    let durationRange: ClosedRange<Int>
    let durationStep: Int
    let primaryInputLabel: String
    let ratingLabel: String
    let ratingTitles: [String]?
    let disclaimer: String?
    private let formatsDurationAsHours: Bool

    init(eventID: String) {
        let presetID = PresetEventID(rawValue: eventID)
        initialDurationMinutes = presetID == .sleep ? 8 * 60 : 30
        durationRange = presetID == .sleep ? 15...1_440 : 5...720
        durationStep = presetID == .sleep ? 15 : 5
        primaryInputLabel = presetID == .weight ? "体重" : "数值"
        ratingLabel = presetID == .mood ? "整体心情" : "评分"
        ratingTitles = presetID == .mood
            ? ["很差", "较差", "一般", "不错", "很好"]
            : nil
        disclaimer = presetID == .illness
            ? "健康明细仅用于个人记录，不能替代专业医疗建议。"
            : nil
        formatsDurationAsHours = presetID == .sleep
    }

    func durationText(minutes: Int) -> String {
        guard formatsDurationAsHours else { return "\(minutes) 分钟" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return "\(remainder) 分钟"
        }
        if remainder == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(remainder) 分钟"
    }

    func ratingTitle(score: Int) -> String {
        guard let ratingTitles, ratingTitles.indices.contains(score - 1) else {
            return "\(score) 分"
        }
        return ratingTitles[score - 1]
    }
}
