import SwiftUI

struct EventStreamView: View {
    let entries: [LifeEntry]

    var body: some View {
        if entries.isEmpty {
            ContentUnavailableView("还没有记录", systemImage: "clock.arrow.circlepath")
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedDates, id: \.self) { day in
                        Section {
                            ForEach(entriesFor(day)) { EntryRow(entry: $0) }
                        } header: {
                            Text(day.formatted(date: .complete, time: .omitted))
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .background(.background)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 72)
            }
        }
    }

    private var groupedDates: [Date] {
        Array(Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) })).sorted(by: >)
    }

    private func entriesFor(_ date: Date) -> [LifeEntry] {
        entries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }
}

