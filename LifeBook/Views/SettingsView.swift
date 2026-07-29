import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \LifeEntry.timestamp) private var entries: [LifeEntry]
    @AppStorage("openAIModel") private var model = "gpt-5.6-sol"
    @State private var apiKey = ""
    @State private var hasSavedKey = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                SecureField(hasSavedKey ? "已保存（输入新值可替换）" : "sk-…", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("模型", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("保存 API 配置") { saveKey() }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if hasSavedKey {
                    Button("删除 API Key", role: .destructive) {
                        KeychainStore.deleteAPIKey()
                        apiKey = ""
                        hasSavedKey = false
                        statusMessage = "API Key 已删除"
                    }
                }
            } header: {
                Label("OpenAI", systemImage: "sparkles")
            } footer: {
                Text("API Key 只保存在本机 Keychain，LifeBook 不会把它同步到 iCloud。OpenAI API 与 ChatGPT 订阅分别计费。")
            }

            Section("数据") {
                NavigationLink {
                    EventManagementView()
                } label: {
                    Label("自定义事件", systemImage: "square.grid.2x2")
                }
                if let jsonExport {
                    ShareLink(item: jsonExport) {
                        Label("导出 JSON", systemImage: "doc.text")
                    }
                }
                if let csvExport {
                    ShareLink(item: csvExport) {
                        Label("导出 CSV", systemImage: "tablecells")
                    }
                }
                LabeledContent {
                    Text("需 Apple 配置")
                        .foregroundStyle(.secondary)
                } label: {
                    Label("iCloud 同步", systemImage: "icloud")
                }
            }

            Section("隐私") {
                Label("本地优先存储", systemImage: "iphone")
                Label("AI 默认不读取记录", systemImage: "hand.raised")
                Label("每次发送前明确确认", systemImage: "checkmark.shield")
            }

            Section("关于") {
                LabeledContent("版本", value: "1.0.0")
                Link("OpenAI API 费用说明", destination: URL(string: "https://platform.openai.com/usage")!)
            }
        }
        .navigationTitle("设置")
        .onAppear { hasSavedKey = KeychainStore.readAPIKey() != nil }
        .alert("LifeBook", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("好") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func saveKey() {
        do {
            if !apiKey.isEmpty {
                try KeychainStore.saveAPIKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                apiKey = ""
                hasSavedKey = true
            }
            statusMessage = "API 配置已安全保存"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private var jsonExport: JSONEntryExport? {
        guard let data = try? EntryExporter.data(for: entries, format: .json) else { return nil }
        return JSONEntryExport(data: data)
    }

    private var csvExport: CSVEntryExport? {
        guard let data = try? EntryExporter.data(for: entries, format: .csv) else { return nil }
        return CSVEntryExport(data: data)
    }
}
