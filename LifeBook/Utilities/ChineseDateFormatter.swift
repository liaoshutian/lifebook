import Foundation

enum ChineseDateFormatter {
    static let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    private static let locale = Locale(identifier: "zh_Hans_CN")
    private static let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    private static let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    private static let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    static func monthYear(_ date: Date, timeZone: TimeZone = .current) -> String {
        format(date, pattern: "yyyy年M月", timeZone: timeZone)
    }

    static func fullDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        format(date, pattern: "yyyy年M月d日 EEEE", timeZone: timeZone)
    }

    static func lunarDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = locale
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              lunarMonths.indices.contains(month - 1),
              lunarDays.indices.contains(day - 1)
        else { return "" }

        let stem = heavenlyStems[(year - 1) % heavenlyStems.count]
        let branch = earthlyBranches[(year - 1) % earthlyBranches.count]
        let leapPrefix = components.isLeapMonth == true ? "闰" : ""
        return "\(stem)\(branch)年\(leapPrefix)\(lunarMonths[month - 1])\(lunarDays[day - 1])"
    }

    private static func format(_ date: Date, pattern: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
