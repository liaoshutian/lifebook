import SwiftData
import SwiftUI

struct AIAssistantView: View {
    @Query(sort: \LifeEntry.timestamp) private var entries: [LifeEntry]
    @AppStorage("openAIModel") private var model = "gpt-5.6-sol"
    @State private var question = ""
    @State private var answer = ""
    @State private var consentToSend = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("AI 只会看到你在本次请求中同意发送的最近 30 天记录。原始数据仍保存在本机。")
                    .font(.callout)
                Toggle("我同意本次发送这些记录", isOn: $consentToSend)
            } header: {
                Label("发送范围", systemImage: "hand.raised.fill")
            }

            Section("你想了解什么？") {
                TextField("例如：总结我这个月的运动和睡眠", text: $question, axis: .vertical)
                    .lineLimit(3...6)
                Button {
                    Task { await askAI() }
                } label: {
                    if isLoading {
                        HStack { ProgressView(); Text("分析中…") }
                    } else {
                        Label("询问 AI", systemImage: "sparkles")
                    }
                }
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !consentToSend || isLoading)
            }

            if !answer.isEmpty {
                Section("AI 回答") {
                    Text(answer).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("AI 助理")
        .alert("无法完成", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func askAI() async {
        guard let key = KeychainStore.readAPIKey() else {
            errorMessage = OpenAIClient.ClientError.missingAPIKey.localizedDescription
            return
        }
        isLoading = true
        consentToSend = false
        defer { isLoading = false }
        do {
            answer = try await OpenAIClient().ask(
                question: question,
                context: AIContextBuilder.makeContext(entries: entries),
                model: model,
                apiKey: key
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
