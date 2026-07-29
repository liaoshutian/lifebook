import XCTest
@testable import LifeBook

final class OpenAIClientTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        session.invalidateAndCancel()
        session = nil
        super.tearDown()
    }

    func testAskBuildsResponsesRequestAndParsesOutputText() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://example.test/v1/responses")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret")

            let body = try XCTUnwrap(request.httpBody)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["model"] as? String, "test-model")
            XCTAssertEqual(json["max_output_tokens"] as? Int, 900)
            XCTAssertTrue((json["input"] as? String)?.contains("用户问题") == true)

            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )
            let data = Data("""
            {"output":[{"content":[{"type":"output_text","text":"第一段"},{"type":"refusal","text":"忽略"}]},{"content":[{"type":"output_text","text":"第二段"}]}]}
            """.utf8)
            return (response, data)
        }

        let result = try await OpenAIClient(
            session: session,
            endpoint: URL(string: "https://example.test/v1/responses")!
        ).ask(
            question: "用户问题",
            context: "个人记录",
            model: "test-model",
            apiKey: "secret"
        )

        XCTAssertEqual(result, "第一段\n第二段")
    }

    func testAskSurfacesServerMessage() async throws {
        MockURLProtocol.handler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (response, Data(#"{"error":{"message":"invalid key"}}"#.utf8))
        }

        do {
            _ = try await OpenAIClient(session: session).ask(
                question: "问题",
                context: "记录",
                model: "test-model",
                apiKey: "bad"
            )
            XCTFail("Expected an error")
        } catch let error as OpenAIClient.ClientError {
            XCTAssertEqual(error.localizedDescription, "OpenAI 请求失败（401）：invalid key")
        }
    }

    func testAskRejectsBlankAPIKeyWithoutNetworkCall() async {
        do {
            _ = try await OpenAIClient(session: session).ask(
                question: "问题",
                context: "记录",
                model: "test-model",
                apiKey: "  \n"
            )
            XCTFail("Expected an error")
        } catch let error as OpenAIClient.ClientError {
            XCTAssertEqual(error.localizedDescription, "请先在设置中填写 OpenAI API Key")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            XCTFail("MockURLProtocol handler was not configured")
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
