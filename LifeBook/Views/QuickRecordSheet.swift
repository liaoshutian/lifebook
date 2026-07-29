import SwiftData
import SwiftUI

struct QuickRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<EventDefinition> { $0.isQuickRecordEnabled },
        sort: \EventDefinition.sortOrder
    ) private var customEvents: [EventDefinition]
    let defaultDate: Date

    @State private var selected: PresetEvent?
    @State private var numberText = ""
    @State private var note = ""
    @State private var duration = 30
    @State private var rating = 3

    var body: some View {
        NavigationStack {
            Group {
                if let selected {
                    details(for: selected)
                } else {
                    eventGrid
                }
            }
            .navigationTitle(selected?.title ?? "记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selected == nil ? "取消" : "返回") {
                        if selected == nil { dismiss() } else { self.selected = nil }
                    }
                }
            }
        }
    }

    private var eventGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(PresetEvent.defaults + customEvents.map(\.preset)) { event in
                Button {
                    if event.kind == .occurrence {
                        save(event)
                    } else {
                        selected = event
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: event.symbol)
                            .font(.title2)
                            .foregroundStyle(Color(hex: event.colorHex))
                            .frame(width: 50, height: 50)
                            .background(Color(hex: event.colorHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                        Text(event.title)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func details(for event: PresetEvent) -> some View {
        Form {
            switch event.kind {
            case .measurement:
                TextField("数值", text: $numberText)
                    .keyboardType(.decimalPad)
                LabeledContent("单位", value: event.unit ?? "")
            case .duration:
                Stepper(value: $duration, in: 5...720, step: 5) {
                    LabeledContent("时长", value: "\(duration) 分钟")
                }
            case .rating:
                Picker("评分", selection: $rating) {
                    ForEach(1...5, id: \.self) { Text("\($0) 分").tag($0) }
                }
            case .note:
                TextEditor(text: $note).frame(minHeight: 180)
            case .occurrence:
                EmptyView()
            }

            if event.kind != .note {
                TextField("备注（可选）", text: $note, axis: .vertical)
            }

            Button {
                save(event)
            } label: {
                Text("保存记录").frame(maxWidth: .infinity)
            }
            .disabled(event.kind == .measurement && Double(numberText) == nil)
        }
    }

    private func save(_ event: PresetEvent) {
        let timestamp = CalendarEngine.replacingTime(of: defaultDate, with: .now)
        let entry = LifeEntry(
            timestamp: timestamp,
            eventID: event.id,
            title: event.title,
            symbol: event.symbol,
            colorHex: event.colorHex,
            kind: event.kind,
            value: event.kind == .measurement ? Double(numberText) : event.kind == .rating ? Double(rating) : nil,
            unit: event.unit,
            note: note,
            durationMinutes: event.kind == .duration ? duration : nil
        )
        modelContext.insert(entry)
        dismiss()
    }
}
