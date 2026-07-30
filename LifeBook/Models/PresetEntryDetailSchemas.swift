import Foundation

// Declarative field catalog for LifeBook's built-in events.

struct EntryDetailOption: Equatable {
    let id: String
    let title: String
}

enum EntryDetailFieldKind: Equatable {
    case text(placeholder: String)
    case decimal(unit: String, range: ClosedRange<Double>?)
    case integer(unit: String, range: ClosedRange<Int>)
    case choice(options: [EntryDetailOption])
    case choices(options: [EntryDetailOption])
    case rating(lowLabel: String, highLabel: String)
    case time(suggestedMinutes: Int)
}

struct EntryDetailField: Equatable {
    let id: EntryDetailFieldID
    let label: String
    let kind: EntryDetailFieldKind
    let defaultValue: EntryDetailValue?

    init(
        _ id: EntryDetailFieldID,
        label: String,
        kind: EntryDetailFieldKind,
        defaultValue: EntryDetailValue? = nil
    ) {
        self.id = id
        self.label = label
        self.kind = kind
        self.defaultValue = defaultValue
    }
}

struct EntryDetailSection: Equatable {
    let title: String
    let fields: [EntryDetailField]
}

struct EntryDetailDisplayItem: Codable, Equatable {
    let id: String
    let label: String
    let value: String
}

struct EntryDetailSchema: Equatable {
    let presetID: PresetEventID
    let sections: [EntryDetailSection]

    var eventID: String { presetID.rawValue }

    var fields: [EntryDetailField] {
        sections.flatMap(\.fields)
    }

    var defaultValues: [String: EntryDetailValue] {
        Dictionary(
            uniqueKeysWithValues: fields.compactMap { field in
                field.defaultValue.map { (field.id.rawValue, $0) }
            }
        )
    }

    func displayItems(from details: EntryDetails) -> [EntryDetailDisplayItem] {
        fields.compactMap { field in
            guard let value = details[field.id],
                  let formattedValue = field.formatted(value),
                  !formattedValue.isEmpty
            else {
                return nil
            }
            return EntryDetailDisplayItem(
                id: field.id.rawValue,
                label: field.label,
                value: formattedValue
            )
        }
    }

    static func schema(for eventID: String) -> EntryDetailSchema? {
        guard let presetID = PresetEventID(rawValue: eventID) else { return nil }
        return presets.first { $0.presetID == presetID }
    }

    static let presets: [EntryDetailSchema] = [
        EntryDetailSchema(
            presetID: .swim,
            sections: [
                EntryDetailSection(title: "训练明细", fields: [
                    EntryDetailField(
                        .swimStroke,
                        label: "泳姿",
                        kind: .choice(options: [
                            .init(id: "freestyle", title: "自由泳"),
                            .init(id: "breaststroke", title: "蛙泳"),
                            .init(id: "backstroke", title: "仰泳"),
                            .init(id: "butterfly", title: "蝶泳"),
                            .init(id: "mixed", title: "混合")
                        ])
                    ),
                    EntryDetailField(
                        .swimDistance,
                        label: "距离",
                        kind: .decimal(unit: "m", range: 1...100_000)
                    ),
                    EntryDetailField(
                        .swimIntensity,
                        label: "强度",
                        kind: .choice(options: [
                            .init(id: "easy", title: "轻松"),
                            .init(id: "moderate", title: "适中"),
                            .init(id: "hard", title: "高强度")
                        ])
                    ),
                    EntryDetailField(
                        .swimVenue,
                        label: "场地",
                        kind: .choice(options: [
                            .init(id: "pool25", title: "25 米泳池"),
                            .init(id: "pool50", title: "50 米泳池"),
                            .init(id: "openWater", title: "开放水域"),
                            .init(id: "other", title: "其他")
                        ])
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .haircut,
            sections: [
                EntryDetailSection(title: "服务明细", fields: [
                    EntryDetailField(
                        .haircutService,
                        label: "项目",
                        kind: .choices(options: [
                            .init(id: "cut", title: "修剪"),
                            .init(id: "styling", title: "造型"),
                            .init(id: "color", title: "染发"),
                            .init(id: "perm", title: "烫发"),
                            .init(id: "care", title: "护理")
                        ])
                    ),
                    EntryDetailField(
                        .haircutShop,
                        label: "门店或理发师",
                        kind: .text(placeholder: "例如：常去的门店、小李")
                    ),
                    EntryDetailField(
                        .haircutCost,
                        label: "花费",
                        kind: .decimal(unit: "元", range: 0...100_000)
                    ),
                    EntryDetailField(
                        .haircutSatisfaction,
                        label: "满意度",
                        kind: .rating(lowLabel: "不满意", highLabel: "很满意")
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .illness,
            sections: [
                EntryDetailSection(title: "症状与指标", fields: [
                    EntryDetailField(
                        .illnessName,
                        label: "疾病或诊断名称",
                        kind: .text(placeholder: "例如：感冒、流感、偏头痛")
                    ),
                    EntryDetailField(
                        .illnessSymptoms,
                        label: "症状",
                        kind: .choices(options: [
                            .init(id: "fever", title: "发热"),
                            .init(id: "cough", title: "咳嗽"),
                            .init(id: "soreThroat", title: "咽痛"),
                            .init(id: "congestion", title: "鼻塞或流涕"),
                            .init(id: "headache", title: "头痛"),
                            .init(id: "fatigue", title: "乏力"),
                            .init(id: "nausea", title: "恶心或呕吐"),
                            .init(id: "diarrhea", title: "腹泻"),
                            .init(id: "muscleAche", title: "肌肉酸痛"),
                            .init(id: "other", title: "其他")
                        ])
                    ),
                    EntryDetailField(
                        .bodyTemperature,
                        label: "体温",
                        kind: .decimal(unit: "℃", range: 30...45)
                    ),
                    EntryDetailField(
                        .illnessSeverity,
                        label: "严重程度",
                        kind: .choice(options: [
                            .init(id: "mild", title: "轻微"),
                            .init(id: "moderate", title: "中等"),
                            .init(id: "severe", title: "严重")
                        ])
                    )
                ]),
                EntryDetailSection(title: "处理情况", fields: [
                    EntryDetailField(
                        .medication,
                        label: "用药",
                        kind: .text(placeholder: "药名、剂量或服用时间")
                    ),
                    EntryDetailField(
                        .careLevel,
                        label: "就医情况",
                        kind: .choice(options: [
                            .init(id: "rest", title: "自行休息"),
                            .init(id: "online", title: "线上问诊"),
                            .init(id: "clinic", title: "门诊"),
                            .init(id: "emergency", title: "急诊"),
                            .init(id: "hospitalized", title: "住院")
                        ])
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .feast,
            sections: [
                EntryDetailSection(title: "用餐明细", fields: [
                    EntryDetailField(
                        .mealOccasion,
                        label: "餐次",
                        kind: .choice(options: [
                            .init(id: "breakfast", title: "早餐"),
                            .init(id: "lunch", title: "午餐"),
                            .init(id: "dinner", title: "晚餐"),
                            .init(id: "lateNight", title: "夜宵"),
                            .init(id: "gathering", title: "聚会")
                        ])
                    ),
                    EntryDetailField(
                        .cuisine,
                        label: "类型",
                        kind: .choice(options: [
                            .init(id: "chinese", title: "中餐"),
                            .init(id: "hotpot", title: "火锅"),
                            .init(id: "barbecue", title: "烧烤"),
                            .init(id: "western", title: "西餐"),
                            .init(id: "japanese", title: "日料"),
                            .init(id: "korean", title: "韩餐"),
                            .init(id: "dessert", title: "甜品"),
                            .init(id: "other", title: "其他")
                        ])
                    ),
                    EntryDetailField(
                        .restaurant,
                        label: "餐厅",
                        kind: .text(placeholder: "餐厅名称")
                    ),
                    EntryDetailField(
                        .companions,
                        label: "同伴",
                        kind: .text(placeholder: "和谁一起")
                    ),
                    EntryDetailField(
                        .mealCost,
                        label: "花费",
                        kind: .decimal(unit: "元", range: 0...1_000_000)
                    ),
                    EntryDetailField(
                        .mealSatisfaction,
                        label: "满意度",
                        kind: .rating(lowLabel: "一般", highLabel: "很满意")
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .weight,
            sections: [
                EntryDetailSection(title: "身体指标", fields: [
                    EntryDetailField(
                        .measurementState,
                        label: "测量状态",
                        kind: .choice(options: [
                            .init(id: "fasting", title: "空腹"),
                            .init(id: "afterMeal", title: "餐后"),
                            .init(id: "afterExercise", title: "运动后"),
                            .init(id: "beforeSleep", title: "睡前")
                        ])
                    ),
                    EntryDetailField(
                        .bodyFatPercentage,
                        label: "体脂率",
                        kind: .decimal(unit: "%", range: 1...70)
                    ),
                    EntryDetailField(
                        .waistCircumference,
                        label: "腰围",
                        kind: .decimal(unit: "cm", range: 20...250)
                    ),
                    EntryDetailField(
                        .muscleMass,
                        label: "肌肉量",
                        kind: .decimal(unit: "kg", range: 1...200)
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .sleep,
            sections: [
                EntryDetailSection(title: "睡眠明细", fields: [
                    EntryDetailField(
                        .sleepType,
                        label: "类型",
                        kind: .choice(options: [
                            .init(id: "night", title: "夜间睡眠"),
                            .init(id: "nap", title: "午睡"),
                            .init(id: "catchUp", title: "补觉")
                        ])
                    ),
                    EntryDetailField(
                        .bedtime,
                        label: "入睡时间",
                        kind: .time(suggestedMinutes: 23 * 60)
                    ),
                    EntryDetailField(
                        .wakeTime,
                        label: "醒来时间",
                        kind: .time(suggestedMinutes: 7 * 60)
                    ),
                    EntryDetailField(
                        .sleepQuality,
                        label: "睡眠质量",
                        kind: .rating(lowLabel: "很差", highLabel: "很好")
                    ),
                    EntryDetailField(
                        .wakeUpCount,
                        label: "夜间醒来",
                        kind: .integer(unit: "次", range: 0...20)
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .mood,
            sections: [
                EntryDetailSection(title: "情绪明细", fields: [
                    EntryDetailField(
                        .emotions,
                        label: "感受",
                        kind: .choices(options: [
                            .init(id: "happy", title: "开心"),
                            .init(id: "calm", title: "平静"),
                            .init(id: "excited", title: "兴奋"),
                            .init(id: "satisfied", title: "满足"),
                            .init(id: "anxious", title: "焦虑"),
                            .init(id: "down", title: "低落"),
                            .init(id: "angry", title: "生气"),
                            .init(id: "tired", title: "疲惫")
                        ])
                    ),
                    EntryDetailField(
                        .energyLevel,
                        label: "精力",
                        kind: .rating(lowLabel: "很低", highLabel: "充沛")
                    ),
                    EntryDetailField(
                        .stressLevel,
                        label: "压力",
                        kind: .rating(lowLabel: "很低", highLabel: "很高")
                    ),
                    EntryDetailField(
                        .moodTrigger,
                        label: "影响因素",
                        kind: .text(placeholder: "什么事情影响了心情")
                    )
                ])
            ]
        ),
        EntryDetailSchema(
            presetID: .diary,
            sections: [
                EntryDetailSection(title: "日记信息", fields: [
                    EntryDetailField(
                        .diaryTitle,
                        label: "标题",
                        kind: .text(placeholder: "给今天的记录起个标题")
                    ),
                    EntryDetailField(
                        .weather,
                        label: "天气",
                        kind: .choice(options: [
                            .init(id: "sunny", title: "晴"),
                            .init(id: "cloudy", title: "多云"),
                            .init(id: "overcast", title: "阴"),
                            .init(id: "rain", title: "雨"),
                            .init(id: "snow", title: "雪"),
                            .init(id: "windy", title: "大风")
                        ])
                    ),
                    EntryDetailField(
                        .location,
                        label: "地点",
                        kind: .text(placeholder: "今天在哪里")
                    ),
                    EntryDetailField(
                        .diaryTags,
                        label: "标签",
                        kind: .text(placeholder: "用逗号分隔，例如：工作，旅行")
                    ),
                    EntryDetailField(
                        .gratitude,
                        label: "值得感谢的事",
                        kind: .text(placeholder: "今天有什么值得感谢")
                    )
                ])
            ]
        )
    ]
}
