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
    @State private var detailForm = EntryDetailFormState()
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        NavigationStack {
            Group {
                if let selected {
                    detailsForm(for: selected)
                } else {
                    eventGrid
                }
            }
            .navigationTitle(selected?.title ?? "记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selected == nil ? "取消" : "返回") {
                        if selected == nil {
                            dismiss()
                        } else {
                            selected = nil
                            resetInput()
                            selectedDetent = .medium
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
    }

    private var eventGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(PresetEvent.defaults + customEvents.map(\.preset)) { event in
                Button {
                    beginRecording(event)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: event.symbol)
                            .font(.title2)
                            .foregroundStyle(Color(hex: event.colorHex))
                            .frame(width: 50, height: 50)
                            .background(
                                Color(hex: event.colorHex).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 15)
                            )
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

    private func beginRecording(_ event: PresetEvent) {
        resetInput()
        duration = event.recordingConfiguration.initialDurationMinutes
        if let schema = EntryDetailSchema.schema(for: event.id) {
            detailForm.values = schema.defaultValues
        }

        if event.kind == .occurrence && EntryDetailSchema.schema(for: event.id) == nil {
            save(event)
        } else {
            selected = event
            selectedDetent = .large
        }
    }

    private func resetInput() {
        numberText = ""
        note = ""
        duration = 30
        rating = 3
        detailForm = EntryDetailFormState()
    }

    private func detailsForm(for event: PresetEvent) -> some View {
        Form {
            baseFields(for: event)

            if let schema = EntryDetailSchema.schema(for: event.id) {
                ForEach(schema.sections, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.fields, id: \.id) { field in
                            detailField(field)
                        }
                    }
                }
            }

            if event.kind != .note {
                Section("补充说明") {
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
            }

            if let disclaimer = event.recordingConfiguration.disclaimer {
                Section {
                    Label(
                        disclaimer,
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

        }
        .safeAreaInset(edge: .bottom) {
            Button {
                save(event)
            } label: {
                Text("保存记录")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaveDisabled(for: event))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    @ViewBuilder
    private func baseFields(for event: PresetEvent) -> some View {
        switch event.kind {
        case .measurement:
            Section("基本信息") {
                HStack {
                    TextField(event.recordingConfiguration.primaryInputLabel, text: $numberText)
                        .keyboardType(.decimalPad)
                    if let unit = event.unit {
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case .duration:
            Section("基本信息") {
                Stepper(
                    value: $duration,
                    in: event.recordingConfiguration.durationRange,
                    step: event.recordingConfiguration.durationStep
                ) {
                    LabeledContent(
                        "时长",
                        value: durationDescription(for: event)
                    )
                }
            }
        case .rating:
            Section("基本信息") {
                Picker(event.recordingConfiguration.ratingLabel, selection: $rating) {
                    ForEach(1...5, id: \.self) { score in
                        Text(event.recordingConfiguration.ratingTitle(score: score)).tag(score)
                    }
                }
            }
        case .note:
            Section("正文") {
                ZStack(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("写下今天发生的事……")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $note)
                        .frame(minHeight: 160)
                        .accessibilityLabel("日记正文")
                }
            }
        case .occurrence:
            EmptyView()
        }
    }

    @ViewBuilder
    private func detailField(_ field: EntryDetailField) -> some View {
        switch field.kind {
        case .text(let placeholder):
            TextField(
                field.label,
                text: textBinding(for: field.id.rawValue),
                prompt: Text(placeholder),
                axis: .vertical
            )
            .lineLimit(1...4)
            .accessibilityLabel(field.label)
            .accessibilityIdentifier(field.label)

        case .decimal(let unit, let range):
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    TextField(field.label, text: numberBinding(for: field.id.rawValue))
                        .keyboardType(.decimalPad)
                        .accessibilityLabel(field.label)
                        .accessibilityIdentifier(field.label)
                    Text(unit)
                        .foregroundStyle(.secondary)
                }
                if let message = numberValidationMessage(for: field.id.rawValue, range: range) {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

        case .integer(let unit, let range):
            OptionalIntegerField(
                label: field.label,
                unit: unit,
                range: range,
                value: optionalIntegerBinding(for: field.id.rawValue)
            )

        case .choice(let options):
            Picker(field.label, selection: choiceBinding(for: field.id.rawValue)) {
                Text("未选择").tag("")
                ForEach(options, id: \.id) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .accessibilityIdentifier(field.label)

        case .choices(let options):
            MultiChoiceField(
                label: field.label,
                options: options,
                selection: choicesBinding(for: field.id.rawValue)
            )

        case .rating(let lowLabel, let highLabel):
            VStack(alignment: .leading, spacing: 5) {
                Picker(field.label, selection: ratingBinding(for: field.id.rawValue)) {
                    Text("未填写").tag(0)
                    ForEach(1...5, id: \.self) { score in
                        Text("\(score) 分").tag(score)
                    }
                }
                .accessibilityIdentifier(field.label)
                HStack {
                    Text(lowLabel)
                    Spacer()
                    Text(highLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

        case .time(let suggestedMinutes):
            OptionalTimeField(
                label: field.label,
                defaultDate: defaultDate,
                suggestedMinutes: suggestedMinutes,
                minutes: optionalTimeBinding(for: field.id.rawValue)
            )
            .accessibilityIdentifier(field.label)
        }
    }

    private func durationDescription(for event: PresetEvent) -> String {
        event.recordingConfiguration.durationText(minutes: duration)
    }

    private func textBinding(for fieldID: String) -> Binding<String> {
        Binding(
            get: {
                guard case .text(let value) = detailForm.values[fieldID] else { return "" }
                return value
            },
            set: { value in
                if value.isEmpty {
                    detailForm.values.removeValue(forKey: fieldID)
                } else {
                    detailForm.values[fieldID] = .text(value)
                }
            }
        )
    }

    private func numberBinding(for fieldID: String) -> Binding<String> {
        Binding(
            get: { detailForm.numberTexts[fieldID, default: ""] },
            set: { detailForm.numberTexts[fieldID] = $0 }
        )
    }

    private func choiceBinding(for fieldID: String) -> Binding<String> {
        Binding(
            get: {
                guard case .choice(let value) = detailForm.values[fieldID] else { return "" }
                return value
            },
            set: { value in
                if value.isEmpty {
                    detailForm.values.removeValue(forKey: fieldID)
                } else {
                    detailForm.values[fieldID] = .choice(value)
                }
            }
        )
    }

    private func choicesBinding(for fieldID: String) -> Binding<Set<String>> {
        Binding(
            get: {
                guard case .choices(let values) = detailForm.values[fieldID] else { return [] }
                return Set(values)
            },
            set: { values in
                if values.isEmpty {
                    detailForm.values.removeValue(forKey: fieldID)
                } else {
                    detailForm.values[fieldID] = .choices(values.sorted())
                }
            }
        )
    }

    private func ratingBinding(for fieldID: String) -> Binding<Int> {
        Binding(
            get: {
                guard case .integer(let value) = detailForm.values[fieldID] else { return 0 }
                return value
            },
            set: { value in
                if value == 0 {
                    detailForm.values.removeValue(forKey: fieldID)
                } else {
                    detailForm.values[fieldID] = .integer(value)
                }
            }
        )
    }

    private func optionalIntegerBinding(for fieldID: String) -> Binding<Int?> {
        Binding(
            get: {
                guard case .integer(let value) = detailForm.values[fieldID] else { return nil }
                return value
            },
            set: { value in
                if let value {
                    detailForm.values[fieldID] = .integer(value)
                } else {
                    detailForm.values.removeValue(forKey: fieldID)
                }
            }
        )
    }

    private func optionalTimeBinding(for fieldID: String) -> Binding<Int?> {
        Binding(
            get: {
                guard case .time(let value) = detailForm.values[fieldID] else { return nil }
                return value
            },
            set: { value in
                if let value {
                    detailForm.values[fieldID] = .time(value)
                } else {
                    detailForm.values.removeValue(forKey: fieldID)
                }
            }
        )
    }

    private func parsedNumber(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private func numberValidationMessage(
        for fieldID: String,
        range: ClosedRange<Double>?
    ) -> String? {
        let text = detailForm.numberTexts[fieldID, default: ""]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard let number = parsedNumber(text) else { return "请输入有效数字" }
        guard let range, !range.contains(number) else { return nil }
        return "请输入 \(range.lowerBound.formatted())～\(range.upperBound.formatted())"
    }

    private func isSaveDisabled(for event: PresetEvent) -> Bool {
        if event.kind == .measurement,
           parsedNumber(numberText) == nil {
            return true
        }
        guard let schema = EntryDetailSchema.schema(for: event.id) else { return false }
        return schema.fields.contains { field in
            guard case .decimal(_, let range) = field.kind else { return false }
            return numberValidationMessage(for: field.id.rawValue, range: range) != nil
        }
    }

    private func collectedDetails(for event: PresetEvent) -> EntryDetails {
        var values = detailForm.values
        guard let schema = EntryDetailSchema.schema(for: event.id) else {
            return EntryDetails(values: values)
        }

        for field in schema.fields {
            guard case .decimal = field.kind else { continue }
            let fieldID = field.id.rawValue
            let text = detailForm.numberTexts[fieldID, default: ""]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let number = parsedNumber(text) {
                values[fieldID] = .number(number)
            } else {
                values.removeValue(forKey: fieldID)
            }
        }

        for fieldID in Array(values.keys) {
            guard let value = values[fieldID] else { continue }
            if case .text(let text) = value {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    values.removeValue(forKey: fieldID)
                } else {
                    values[fieldID] = .text(trimmed)
                }
            }
        }
        return EntryDetails(values: values)
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
            value: event.kind == .measurement
                ? parsedNumber(numberText)
                : event.kind == .rating ? Double(rating) : nil,
            unit: event.unit,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            durationMinutes: event.kind == .duration ? duration : nil,
            details: collectedDetails(for: event)
        )
        modelContext.insert(entry)
        dismiss()
    }
}

private struct MultiChoiceField: View {
    let label: String
    let options: [EntryDetailOption]
    @Binding var selection: Set<String>

    private let columns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(options, id: \.id) { option in
                    let isSelected = selection.contains(option.id)
                    Button {
                        if isSelected {
                            selection.remove(option.id)
                        } else {
                            selection.insert(option.id)
                        }
                    } label: {
                        Text(option.title)
                            .font(.subheadline)
                            .foregroundStyle(isSelected ? Color.accentBlue : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 36)
                            .background(
                                isSelected
                                    ? Color.accentBlue.opacity(0.14)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 9)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(
                                        isSelected ? Color.accentBlue : .clear,
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isSelected ? "已选择" : "未选择")
                }
            }
        }
    }
}

private struct EntryDetailFormState {
    var values: [String: EntryDetailValue] = [:]
    var numberTexts: [String: String] = [:]
}

private struct OptionalIntegerField: View {
    let label: String
    let unit: String
    let range: ClosedRange<Int>
    @Binding var value: Int?

    var body: some View {
        if value == nil {
            Button {
                value = range.lowerBound
            } label: {
                HStack {
                    Text(label)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("未填写")
                        .foregroundStyle(.secondary)
                    Image(systemName: "plus.circle")
                }
            }
            .accessibilityIdentifier(label)
        } else {
            HStack {
                Stepper(value: binding, in: range) {
                    LabeledContent(label, value: "\(value ?? range.lowerBound) \(unit)")
                }
                Button {
                    value = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除\(label)")
            }
        }
    }

    private var binding: Binding<Int> {
        Binding(
            get: { value ?? range.lowerBound },
            set: { value = $0 }
        )
    }
}

private struct OptionalTimeField: View {
    let label: String
    let defaultDate: Date
    let suggestedMinutes: Int
    @Binding var minutes: Int?

    var body: some View {
        if minutes == nil {
            Button {
                minutes = suggestedMinutes
            } label: {
                HStack {
                    Text(label)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("未填写")
                        .foregroundStyle(.secondary)
                    Image(systemName: "plus.circle")
                }
            }
            .accessibilityIdentifier(label)
        } else {
            HStack {
                DatePicker(
                    label,
                    selection: dateBinding,
                    displayedComponents: .hourAndMinute
                )
                Button {
                    minutes = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除\(label)")
            }
        }
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let value = minutes ?? suggestedMinutes
                return Calendar.current.date(
                    bySettingHour: value / 60,
                    minute: value % 60,
                    second: 0,
                    of: defaultDate
                ) ?? defaultDate
            },
            set: { value in
                let components = Calendar.current.dateComponents(
                    [.hour, .minute],
                    from: value
                )
                minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }
}
