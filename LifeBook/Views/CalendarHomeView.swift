import SwiftData
import SwiftUI

struct CalendarHomeView: View {
    enum Mode: String, CaseIterable { case calendar = "日历"; case events = "事件" }

    @Query(sort: \LifeEntry.timestamp, order: .reverse) private var entries: [LifeEntry]
    @State private var mode: Mode = .calendar
    @State private var displayedMonth = Date.now
    @State private var selectedDate = Date.now
    @State private var showingQuickRecord = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("显示方式", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)

            if mode == .calendar {
                MonthCalendarView(
                    month: $displayedMonth,
                    selectedDate: $selectedDate,
                    entries: entries
                )
                DayEntryList(date: selectedDate, entries: entriesForSelectedDate)
            } else {
                EventStreamView(entries: entries)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                showingQuickRecord = true
            } label: {
                Label("记一笔", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 50)
                    .background(Color.accentBlue, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingQuickRecord) {
            QuickRecordSheet(defaultDate: selectedDate)
        }
    }

    private var entriesForSelectedDate: [LifeEntry] {
        entries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }
}

private struct MonthCalendarView: View {
    @Binding var month: Date
    @Binding var selectedDate: Date
    let entries: [LifeEntry]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(ChineseDateFormatter.monthYear(month))
                    .font(.headline)
                Spacer()
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(ChineseDateFormatter.weekdaySymbols.enumerated()), id: \.offset) { _, weekday in
                    Text(weekday)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            entries: entries.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 50)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
    }

    private var days: [Date?] {
        CalendarEngine.days(in: month, calendar: calendar)
    }

    private func moveMonth(_ offset: Int) {
        guard let value = calendar.date(byAdding: .month, value: offset, to: month) else { return }
        month = value
    }
}

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let entries: [LifeEntry]

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 28, height: 26)
                .background(isSelected ? Color.accentBlue : .clear, in: Circle())

            HStack(spacing: 2) {
                ForEach(entries.prefix(3)) { entry in
                    Image(systemName: entry.symbol)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Color(hex: entry.colorHex))
                }
                if entries.count > 3 {
                    Text("+\(entries.count - 3)").font(.system(size: 7))
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(isSelected ? Color.accentBlue.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }
}

private struct DayEntryList: View {
    let date: Date
    let entries: [LifeEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(ChineseDateFormatter.fullDate(date))
                    .font(.headline)
                Text(ChineseDateFormatter.lunarDate(date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if entries.isEmpty {
                ContentUnavailableView("这天还没有记录", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(entries) { EntryRow(entry: $0) }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EntryRow: View {
    let entry: LifeEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.symbol)
                .foregroundStyle(Color(hex: entry.colorHex))
                .frame(width: 34, height: 34)
                .background(Color(hex: entry.colorHex).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).fontWeight(.medium)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Text(entry.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var detail: String? {
        EntryPresentation.summary(for: entry)
    }
}
