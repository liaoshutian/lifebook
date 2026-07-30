import Foundation

struct PresetEvent: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let colorHex: String
    let kind: EntryKind
    let unit: String?

    static let defaults: [PresetEvent] = [
        .init(id: "swim", title: "游泳", symbol: "figure.pool.swim", colorHex: "2F80ED", kind: .duration, unit: "分钟"),
        .init(id: "haircut", title: "理发", symbol: "scissors", colorHex: "8E7CC3", kind: .occurrence, unit: nil),
        .init(id: "illness", title: "生病", symbol: "cross.case.fill", colorHex: "EB5757", kind: .occurrence, unit: nil),
        .init(id: "feast", title: "大餐", symbol: "fork.knife", colorHex: "F2994A", kind: .occurrence, unit: nil),
        .init(id: "weight", title: "体重", symbol: "scalemass.fill", colorHex: "27AE60", kind: .measurement, unit: "kg"),
        .init(id: "sleep", title: "睡眠", symbol: "moon.zzz.fill", colorHex: "4C5B9B", kind: .duration, unit: "小时"),
        .init(id: "mood", title: "心情", symbol: "face.smiling.fill", colorHex: "F2C94C", kind: .rating, unit: "分"),
        .init(id: "diary", title: "日记", symbol: "book.pages.fill", colorHex: "3D5A80", kind: .note, unit: nil)
    ]
}

