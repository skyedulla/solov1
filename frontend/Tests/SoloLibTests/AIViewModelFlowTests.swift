import XCTest

@testable import SoloLib

final class AIViewModelFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let ideaId = "00000000-0000-4000-8000-0000000000a1"
    private let mindmapId = "00000000-0000-4000-8000-0000000000b1"
    private let conversationId = "00000000-0000-4000-8000-0000000000c1"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeViewModel() -> AIViewModel {
        let remote = AIRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return AIViewModel(remote: remote)
    }

    private static func jsonData(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [])
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    private static func httpBodyData(from request: URLRequest) -> Data {
        if let body = request.httpBody, !body.isEmpty {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return Data()
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    func testSendPrompt_fromMindmapSurface_sendsPromptPayloadAndDecodesCompletion() async throws {
        let responsePayload = try Self.jsonData([
            "content": "Generated answer",
            "model": "gpt-4o-mini",
            "conversation_id": conversationId,
            "usage": [
                "prompt_tokens": 10,
                "completion_tokens": 5,
                "total_tokens": 15,
                "cached_prompt_tokens": 2,
            ],
        ])

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/ai/prompt")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let bodyData = Self.httpBodyData(from: request)
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
            XCTAssertEqual(body["tool_type"] as? String, AIToolType.mindmap.rawValue)
            XCTAssertEqual(body["query"] as? String, "Expand the onboarding cluster")
            XCTAssertEqual(body["idea_id"] as? String, self.ideaId)
            XCTAssertEqual(body["conversation_id"] as? String, self.conversationId)

            let context = try XCTUnwrap(body["context"] as? [String: String])
            XCTAssertEqual(context["idea_id"], self.ideaId)
            XCTAssertEqual(context["mindmap_id"], self.mindmapId)
            XCTAssertEqual(context["conversation_id"], self.conversationId)

            return (Self.httpResponse(for: request, statusCode: 200), responsePayload)
        }

        let viewModel = makeViewModel()
        await viewModel.updatePromptInput("  Expand the onboarding cluster  ")
        let response = try await viewModel.sendPrompt(
            surface: .mindmap(
                ideaId: ideaId,
                mindmapId: mindmapId,
                conversationId: conversationId
            ),
            accessToken: accessToken
        )

        XCTAssertEqual(response.content, "Generated answer")
        XCTAssertEqual(response.conversationId, conversationId)
        XCTAssertEqual(response.usage.promptTokens, 10)
        XCTAssertEqual(response.usage.cachedPromptTokens, 2)
        let requestState = await viewModel.requestState
        let promptInput = await viewModel.promptInput
        XCTAssertEqual(requestState, .success)
        XCTAssertEqual(promptInput, "")
    }

    func testSendPrompt_nilConversationId_omitsConversationIdInBodyAndContext() async throws {
        let responsePayload = try Self.jsonData([
            "content": "OK",
            "model": "gpt-4o-mini",
            "usage": [
                "prompt_tokens": 1,
                "completion_tokens": 1,
                "total_tokens": 2,
                "cached_prompt_tokens": 0,
            ],
        ])

        MockURLProtocol.requestHandler = { request in
            let bodyData = Self.httpBodyData(from: request)
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
            XCTAssertNil(body["conversation_id"] as? String)
            let context = try XCTUnwrap(body["context"] as? [String: String])
            XCTAssertNil(context["conversation_id"])
            return (Self.httpResponse(for: request, statusCode: 200), responsePayload)
        }

        let viewModel = makeViewModel()
        await viewModel.updatePromptInput("Hello")
        _ = try await viewModel.sendPrompt(
            surface: .mindmap(
                ideaId: ideaId,
                mindmapId: mindmapId,
                conversationId: nil
            ),
            accessToken: accessToken
        )
    }
}
