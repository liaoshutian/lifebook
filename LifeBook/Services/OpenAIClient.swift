import Foundation

struct OpenAIClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case server(status: Int, message: String)
        case emptyOutput

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "请先在设置中填写 OpenAI API Key"
            case .invalidResponse: return "OpenAI 返回了无法识别的响应"
            case .server(let status, let message): return "OpenAI 请求失败（\(status)）：\(message)"
            case .emptyOutput: return "AI 没有返回文字内容"
            }
        }
    }

    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func ask(question: String, context: String, model: String, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClientError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let payload = RequestPayload(
            model: model,
            instructions: """
            你是 LifeBook 中谨慎、简洁的个人记录助理。只根据用户提供的记录回答。
            指出趋势时必须引用具体日期；不要把相关性描述成因果关系；不要作医疗诊断。
            如果记录不足，明确说明。使用与用户问题相同的语言。
            """,
            input: "以下是用户明确同意发送的个人记录：\n\(context)\n\n问题：\(question)",
            maxOutputTokens: 900
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data).error.message)
                ?? String(data: data, encoding: .utf8)
                ?? "未知错误"
            throw ClientError.server(status: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(ResponsePayload.self, from: data)
        let text = decoded.output
            .flatMap { $0.content ?? [] }
            .filter { $0.type == "output_text" }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ClientError.emptyOutput }
        return text
    }
}

private struct RequestPayload: Encodable {
    let model: String
    let instructions: String
    let input: String
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, instructions, input
        case maxOutputTokens = "max_output_tokens"
    }
}

private struct ResponsePayload: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String?
        }
        let content: [Content]?
    }
    let output: [Output]
}

private struct APIErrorEnvelope: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}

enum AIContextBuilder {
    static func makeContext(entries: [LifeEntry], now: Date = .now, days: Int = 30) -> String {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? .distantPast
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let lines = entries
            .filter { $0.timestamp >= cutoff && $0.timestamp <= now }
            .sorted { $0.timestamp < $1.timestamp }
            .map { entry in
                var details: [String] = []
                if let value = entry.value {
                    details.append("\(value.formatted())\(entry.unit ?? "")")
                }
                if let duration = entry.durationMinutes {
                    details.append("\(duration)分钟")
                }
                if !entry.note.isEmpty {
                    details.append("备注：\(entry.note)")
                }
                let suffix = details.isEmpty ? "" : "；" + details.joined(separator: "；")
                return "- \(formatter.string(from: entry.timestamp))：\(entry.title)\(suffix)"
            }
        return lines.isEmpty ? "最近 \(days) 天没有记录。" : lines.joined(separator: "\n")
    }
}
