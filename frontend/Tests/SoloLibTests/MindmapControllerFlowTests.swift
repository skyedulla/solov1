import XCTest

@testable import SoloLib

/// Exercises **`MindmapController`** → **`MindmapsRemoteDataSource`** → **`URLSession`** with **`MockURLProtocol`**.
final class MindmapControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let ideaId = "00000000-0000-4000-8000-0000000000a1"
    private let mindmapId = "00000000-0000-4000-8000-0000000000c3"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeController() -> MindmapController {
        let remote = MindmapsRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return MindmapController(remote: remote)
    }

    /// Matches **`JSONDecoder`** **`.iso8601`** on Apple platforms (no fractional seconds in the default strategy).
    private static let fixtureISO8601 = "2024-06-01T12:00:00Z"

    private static func mindmapDocumentJSONObject(
        id: String,
        ideaId: String,
        title: String = "",
        nodes: [[String: Any]] = [],
        connections: [[String: Any]] = []
    ) -> [String: Any] {
        [
            "id": id,
            "idea_id": ideaId,
            "title": title,
            "nodes": nodes,
            "connections": connections,
            "last_transform": [
                "scale": 1.0,
                "translate_x": 0,
                "translate_y": 0,
            ],
        ]
    }

    private static func summaryJSONObject(
        id: String,
        ideaId: String,
        title: String,
        summary: String,
        createdAt: String = MindmapControllerFlowTests.fixtureISO8601,
        lastUpdatedAt: String = MindmapControllerFlowTests.fixtureISO8601
    ) -> [String: Any] {
        [
            "id": id,
            "idea_id": ideaId,
            "title": title,
            "summary": summary,
            "created_at": createdAt,
            "last_updated_at": lastUpdatedAt,
        ]
    }

    private static func jsonData(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [])
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        let url = request.url!
        return HTTPURLResponse(
            url: url,
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

    // MARK: - One test per controller method

    func testCreateMindmap_fullStack_POSTsJSONAndBuildsEmptyDocument() async throws {
        let row: [String: Any] = [
            "id": mindmapId,
            "idea_id": ideaId,
            "title": "",
            "summary": "",
            "created_at": Self.fixtureISO8601,
            "last_updated_at": Self.fixtureISO8601,
        ]
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/mindmaps")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            XCTAssertFalse(posted.isEmpty)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["ideaId"] as? String, self.ideaId)

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.createMindmap(ideaId: ideaId, accessToken: accessToken)

        XCTAssertEqual(model.id, mindmapId)
        XCTAssertEqual(model.ideaId, ideaId)
        XCTAssertTrue(model.nodes.isEmpty)
        XCTAssertTrue(model.connections.isEmpty)
        XCTAssertEqual(model.title, "")
        XCTAssertEqual(model.lastTransform.scale, 1)
        XCTAssertEqual(model.lastTransform.translateX, 0)
        XCTAssertEqual(model.lastTransform.translateY, 0)
    }

    func testLoadMindmap_fullStack_GETsAndDecodesDocument() async throws {
        let doc = Self.mindmapDocumentJSONObject(id: mindmapId, ideaId: ideaId, title: "Roadmap")
        let body = try Self.jsonData(doc)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/mindmaps/\(self.mindmapId)")
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "idea_id" }?.value, self.ideaId)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.loadMindmap(id: mindmapId, ideaId: ideaId, accessToken: accessToken)

        XCTAssertEqual(model.id, mindmapId)
        XCTAssertEqual(model.ideaId, ideaId)
        XCTAssertEqual(model.title, "Roadmap")
        XCTAssertTrue(model.nodes.isEmpty)
        XCTAssertTrue(model.connections.isEmpty)
    }

    func testLoadMindmap_notFound_returnsMindmapNotFound() async {
        MockURLProtocol.requestHandler = { request in
            let res = Self.httpResponse(for: request, statusCode: 404)
            return (res, Data())
        }

        let controller = makeController()
        do {
            _ = try await controller.loadMindmap(id: mindmapId, ideaId: ideaId, accessToken: accessToken)
            XCTFail("Expected mindmapNotFound")
        } catch MindmapControllerError.mindmapNotFound {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListMindmaps_fullStack_GETsQueryAndDecodesSummaries() async throws {
        let rows: [[String: Any]] = [
            Self.summaryJSONObject(
                id: mindmapId,
                ideaId: ideaId,
                title: "Map A",
                summary: "First map",
                createdAt: Self.fixtureISO8601,
                lastUpdatedAt: "2024-06-02T12:00:00Z"
            ),
        ]
        let body = try Self.jsonData(rows)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/mindmaps")
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "idea_id" }?.value, self.ideaId)

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let list = try await controller.listMindmaps(ideaId: ideaId, accessToken: accessToken)

        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].id, mindmapId)
        XCTAssertEqual(list[0].ideaId, ideaId)
        XCTAssertEqual(list[0].title, "Map A")
        XCTAssertEqual(list[0].summary, "First map")
    }

    func testDeleteMindmap_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/mindmaps/\(self.mindmapId)")
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "idea_id" }?.value, self.ideaId)
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteMindmap(id: mindmapId, ideaId: ideaId, accessToken: accessToken)
    }

    func testGenerateMindmapSummary_fullStack_POSTsQueryAndDecodesSummary() async throws {
        let payload = ["summary": "Detailed outline of nodes A and B linked by topic X."]
        let body = try Self.jsonData(payload)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/mindmaps/\(self.mindmapId)/generate-summary")
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "idea_id" }?.value, self.ideaId)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let summary = try await controller.generateMindmapSummary(id: mindmapId, ideaId: ideaId, accessToken: accessToken)

        XCTAssertEqual(summary, "Detailed outline of nodes A and B linked by topic X.")
    }

    func testGenerateMindmapSummary_llmUnavailable_returnsSummaryGenerationUnavailable() async {
        MockURLProtocol.requestHandler = { request in
            let res = Self.httpResponse(for: request, statusCode: 503)
            return (res, Data())
        }

        let controller = makeController()
        do {
            _ = try await controller.generateMindmapSummary(id: mindmapId, ideaId: ideaId, accessToken: accessToken)
            XCTFail("Expected summaryGenerationUnavailable")
        } catch MindmapControllerError.summaryGenerationUnavailable {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteMindmap_notFound_returnsMindmapNotFound() async {
        MockURLProtocol.requestHandler = { request in
            let res = Self.httpResponse(for: request, statusCode: 404)
            return (res, Data())
        }

        let controller = makeController()
        do {
            try await controller.deleteMindmap(id: mindmapId, ideaId: ideaId, accessToken: accessToken)
            XCTFail("Expected mindmapNotFound")
        } catch MindmapControllerError.mindmapNotFound {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
