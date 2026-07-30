import SwiftData
import SwiftUI

struct EventManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\EventDefinition.sortOrder),
        SortDescriptor(\EventDefinition.title)
    ]) private var definitions: [EventDefinition]
    @State private var showingAddEvent = false

    var body: some View {
        List {
            Section("内置事件") {
                ForEach(PresetEvent.defaults) { event in
                    EventDefinitionRow(event: event, isEnabled: true)
                }
            }

            Section {
                if definitions.isEmpty {
                    ContentUnavailableView(
                        "还没有自定义事件",
                        systemImage: "square.grid.2x2",
                        description: Text("添加适合你的活动、数值或评分。")
                    )
                } else {
                    ForEach(definitions) { definition in
                        EventDefinitionRow(
                            event: definition.preset,
                            isEnabled: definition.isQuickRecordEnabled
                        )
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(definitions[index])
                        }
                    }
                }
            } header: {
                Text("自定义事件")
            } footer: {
                Text("左滑可以删除。关闭快捷记录的事件不会出现在“记一笔”中，历史记录不受影响。")
            }
        }
        .navigationTitle("事件管理")
        .toolbar {
            Button {
                showingAddEvent = true
            } label: {
                Label("添加事件", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(sortOrder: definitions.count)
        }
    }
}

private struct EventDefinitionRow: View {
    let event: PresetEvent
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.symbol)
                .foregroundStyle(Color(hex: event.colorHex))
                .frame(width: 34, height: 34)
                .background(Color(hex: event.colorHex).opacity(0.12), in: Circle())
            VStack(alignment: .leading) {
                Text(event.title)
                Text(event.kind.displayName + (event.unit.map { " · \($0)" } ?? ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !isEnabled {
                Text("已隐藏")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let sortOrder: Int

    @State private var title = ""
    @State private var symbol = "star.fill"
    @State private var colorHex = "2F80ED"
    @State private var kind: EntryKind = .occurrence
    @State private var unit = ""

    private let symbols = [
        "star.fill", "figure.run", "figure.walk", "dumbbell.fill",
        "cup.and.saucer.fill", "pills.fill", "heart.fill", "drop.fill"
    ]
    private let colors = ["2F80ED", "27AE60", "F2994A", "EB5757", "8E7CC3", "4C5B9B"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $title)
                Picker("类型", selection: $kind) {
                    ForEach(EntryKind.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }

                if kind == .measurement || kind == .duration || kind == .rating {
                    TextField("单位（可选）", text: $unit)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(symbols, id: \.self) { candidate in
                            Button {
                                symbol = candidate
                            } label: {
                                Image(systemName: candidate)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        symbol == candidate ? Color.accentBlue.opacity(0.15) : .clear,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("颜色") {
                    HStack {
                        ForEach(colors, id: \.self) { candidate in
                            Button {
                                colorHex = candidate
                            } label: {
                                Circle()
                                    .fill(Color(hex: candidate))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorHex == candidate {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("添加事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let definition = EventDefinition(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            symbol: symbol,
                            colorHex: colorHex,
                            kind: kind,
                            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            sortOrder: sortOrder
                        )
                        modelContext.insert(definition)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

extension EntryKind {
    var displayName: String {
        switch self {
        case .occurrence: return "发生一次"
        case .measurement: return "数值"
        case .duration: return "时长"
        case .rating: return "评分"
        case .note: return "文字"
        }
    }
}
