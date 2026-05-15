import XCTest

@testable import SoloLib

/// Exercises **`MindmapNodeController`** → **`MindmapNodeRemoteDataSource`** → **`URLSession`** with **`MockURLProtocol`**.
final class MindmapNodeControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let mindmapId = "00000000-0000-4000-8000-0000000000c3"
    private let mindmapNodeId = "00000000-0000-4000-8000-0000000000d4"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeController() -> MindmapNodeController {
        let remote = MindmapNodeRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return MindmapNodeController(remote: remote)
    }

    private static func mindmapNodeResponseJSONObject(
        id: String,
        mindmapId: String,
        parentNodeId: String? = nil,
        text: String,
        x: Int = 10,
        y: Int = 20,
        height: Int = 40,
        width: Int = 120
    ) -> [String: Any] {
        var row: [String: Any] = [
            "id": id,
            "mindmap_id": mindmapId,
            "position": ["x": x, "y": y],
            "text": text,
            "dimensions": ["height": height, "width": width],
        ]
        if let parentNodeId {
            row["parent_node_id"] = parentNodeId
        } else {
            row["parent_node_id"] = NSNull()
        }
        return row
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

    private func sampleMindmapNode(isNewId: Bool = false) -> NodeModel {
        NodeModel(
            id: isNewId ? "00000000-0000-4000-8000-000000009999" : mindmapNodeId,
            nodeType: .mindmapNode(MindmapNodeModel(mindmapId: mindmapId, text: "Mind map node body")),
            parentNodeId: nil,
            position: NodeModel.Position(x: 5, y: 8),
            dimensions: NodeModel.Dimensions(height: 32, width: 100)
        )
    }

    func testSearchMindmapNodes_fullStack_GETsQueryAndDecodes() async throws {
        let row = Self.mindmapNodeResponseJSONObject(id: mindmapNodeId, mindmapId: mindmapId, text: "Alpha")
        let body = try Self.jsonData([row])

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/mindmap-node")
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertEqual(items.first { $0.name == "mindmap_id" }?.value, self.mindmapId)
            XCTAssertEqual(items.first { $0.name == "q" }?.value, "al")

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let list = try await controller.searchMindmapNodes(
            mindmapId: mindmapId,
            query: "al",
            accessToken: accessToken
        )

        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].id, mindmapNodeId)
        guard case let .mindmapNode(payload) = list[0].nodeType else {
            XCTFail("expected mindmap-node")
            return
        }
        XCTAssertEqual(payload.text, "Alpha")
    }

    func testSearchMindmapNodes_emptyQuery_omitsQParameter() async throws {
        let body = try Self.jsonData([Any]())

        MockURLProtocol.requestHandler = { request in
            let items = try XCTUnwrap(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
            XCTAssertNil(items.first { $0.name == "q" })
            XCTAssertEqual(items.first { $0.name == "mindmap_id" }?.value, self.mindmapId)
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let list = try await controller.searchMindmapNodes(
            mindmapId: mindmapId,
            query: "   ",
            accessToken: accessToken
        )
        XCTAssertTrue(list.isEmpty)
    }

    func testAddMindmapNode_POSTsJSONAndDecodes() async throws {
        let row = Self.mindmapNodeResponseJSONObject(
            id: mindmapNodeId,
            mindmapId: mindmapId,
            text: "Mind map node body"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/mindmap-node")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["mindmapId"] as? String, self.mindmapId)
            XCTAssertNil(obj["ideaId"] as? String)
            XCTAssertEqual(obj["text"] as? String, "Mind map node body")

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let saved = try await controller.addMindmapNode(sampleMindmapNode(isNewId: true), accessToken: accessToken)

        XCTAssertEqual(saved.id, mindmapNodeId)
        guard case let .mindmapNode(saved) = saved.nodeType else {
            XCTFail("expected mindmap-node")
            return
        }
        XCTAssertEqual(saved.mindmapId, mindmapId)
        XCTAssertEqual(saved.text, "Mind map node body")
    }

    func testEditMindmapNode_PATCHesJSONAndDecodes() async throws {
        let row = Self.mindmapNodeResponseJSONObject(id: mindmapNodeId, mindmapId: mindmapId, text: "Updated")
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/mindmap-node/\(self.mindmapNodeId)")

            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["text"] as? String, "Updated")

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        var mindmapNode = sampleMindmapNode(isNewId: false)
        guard case let .mindmapNode(existing) = mindmapNode.nodeType else {
            XCTFail("expected mindmap-node")
            return
        }
        mindmapNode.nodeType = .mindmapNode(MindmapNodeModel(mindmapId: existing.mindmapId, text: "Updated"))

        let controller = makeController()
        let saved = try await controller.editMindmapNode(mindmapNode, accessToken: accessToken)

        XCTAssertEqual(saved.id, mindmapNodeId)
        guard case let .mindmapNode(updated) = saved.nodeType else {
            XCTFail("expected mindmap-node")
            return
        }
        XCTAssertEqual(updated.text, "Updated")
    }

    func testDeleteMindmapNode_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/mindmap-node/\(self.mindmapNodeId)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteMindmapNode(mindmapNodeId: mindmapNodeId, accessToken: accessToken)
    }
}
