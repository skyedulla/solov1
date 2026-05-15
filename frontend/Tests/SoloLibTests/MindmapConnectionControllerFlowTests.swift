import XCTest

@testable import SoloLib

/// Exercises **`MindmapConnectionController`** → **`MindmapConnectionRemoteDataSource`** → **`URLSession`** with **`MockURLProtocol`**.
final class MindmapConnectionControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let mindmapId = "00000000-0000-4000-8000-0000000000c3"
    private let mindmapConnectionId = "00000000-0000-4000-8000-0000000000e5"
    private let sourceNodeId = "00000000-0000-4000-8000-0000000000f1"
    private let targetNodeId = "00000000-0000-4000-8000-0000000000f2"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeController() -> MindmapConnectionController {
        let remote = MindmapConnectionRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return MindmapConnectionController(remote: remote)
    }

    private static func connectionResponseJSONObject(
        id: String,
        mindmapId: String,
        sourceNodeId: String,
        targetNodeId: String?,
        sourceAnchor: String,
        targetAnchor: String?
    ) -> [String: Any] {
        var row: [String: Any] = [
            "id": id,
            "mindmap_id": mindmapId,
            "source_node_id": sourceNodeId,
            "source_anchor": sourceAnchor,
        ]
        if let targetNodeId {
            row["target_node_id"] = targetNodeId
        } else {
            row["target_node_id"] = NSNull()
        }
        if let targetAnchor {
            row["target_anchor"] = targetAnchor
        } else {
            row["target_anchor"] = NSNull()
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

    func testAddMindmapConnection_withTarget_POSTsJSONAndDecodes() async throws {
        let row = Self.connectionResponseJSONObject(
            id: mindmapConnectionId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            sourceAnchor: "right",
            targetAnchor: "left"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/mindmap-connection")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["mindmapId"] as? String, self.mindmapId)
            XCTAssertEqual(obj["sourceNodeId"] as? String, self.sourceNodeId)
            XCTAssertNil(obj["ideaId"] as? String)
            XCTAssertEqual(obj["targetNodeId"] as? String, self.targetNodeId)
            XCTAssertEqual(obj["sourceAnchor"] as? String, "right")
            XCTAssertEqual(obj["targetAnchor"] as? String, "left")

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.addMindmapConnection(
            sourceNodeId: sourceNodeId,
            sourceAnchor: .right,
            targetNodeId: targetNodeId,
            targetAnchor: .left,
            mindmapId: mindmapId,
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, mindmapConnectionId)
        XCTAssertEqual(model.sourceNodeId, sourceNodeId)
        XCTAssertEqual(model.targetNodeId, targetNodeId)
        XCTAssertEqual(model.sourceAnchor, .right)
        XCTAssertEqual(model.targetAnchor, .left)
        guard case let .mindmapConnection(scope) = model.connectionType else {
            XCTFail("expected mindmap connection")
            return
        }
        XCTAssertEqual(scope.mindmapId, mindmapId)
    }

    func testAddMindmapConnection_openEnded_omitsTargetFieldsInBody() async throws {
        let row = Self.connectionResponseJSONObject(
            id: mindmapConnectionId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: nil,
            sourceAnchor: "bottom",
            targetAnchor: nil
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertNil(obj["targetNodeId"] as? String)
            XCTAssertNil(obj["targetAnchor"] as? String)
            XCTAssertEqual(obj["mindmapId"] as? String, self.mindmapId)

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.addMindmapConnection(
            sourceNodeId: sourceNodeId,
            sourceAnchor: .bottom,
            mindmapId: mindmapId,
            accessToken: accessToken
        )

        XCTAssertNil(model.targetNodeId)
        XCTAssertNil(model.targetAnchor)
        XCTAssertEqual(model.sourceAnchor, .bottom)
        guard case let .mindmapConnection(scope) = model.connectionType else {
            XCTFail("expected mindmap connection")
            return
        }
        XCTAssertEqual(scope.mindmapId, mindmapId)
    }

    func testDeleteMindmapConnection_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/mindmap-connection/\(self.mindmapConnectionId)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteMindmapConnection(
            mindmapConnectionId: mindmapConnectionId,
            accessToken: accessToken
        )
    }

    func testUpdateMindmapConnection_PATCHesJSONAndDecodes() async throws {
        let row = Self.connectionResponseJSONObject(
            id: mindmapConnectionId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            sourceAnchor: "top",
            targetAnchor: "bottom"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/mindmap-connection/\(self.mindmapConnectionId)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["sourceAnchor"] as? String, "top")
            XCTAssertEqual(obj["targetNodeId"] as? String, self.targetNodeId)
            XCTAssertEqual(obj["targetAnchor"] as? String, "bottom")
            XCTAssertEqual(obj.count, 3)

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.updateMindmapConnection(
            mindmapConnectionId: mindmapConnectionId,
            targetNodeId: targetNodeId,
            sourceAnchor: .top,
            targetAnchor: .bottom,
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, mindmapConnectionId)
        XCTAssertEqual(model.sourceAnchor, .top)
        XCTAssertEqual(model.targetNodeId, targetNodeId)
        XCTAssertEqual(model.targetAnchor, .bottom)
        guard case let .mindmapConnection(scope) = model.connectionType else {
            XCTFail("expected mindmap connection")
            return
        }
        XCTAssertEqual(scope.mindmapId, mindmapId)
    }
}
