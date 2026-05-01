import XCTest

@testable import SoloLib

/// Exercises **`ConnectionController`** → **`ConnectionsRemoteDataSource`** → **`URLSession`** with **`MockURLProtocol`**.
final class ConnectionControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let ideaId = "00000000-0000-4000-8000-0000000000a1"
    private let mindmapId = "00000000-0000-4000-8000-0000000000c3"
    private let connectionId = "00000000-0000-4000-8000-0000000000e5"
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

    private func makeController() -> ConnectionController {
        let remote = ConnectionsRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return ConnectionController(remote: remote)
    }

    private static func connectionResponseJSONObject(
        id: String,
        ideaId: String,
        mindmapId: String,
        sourceNodeId: String,
        targetNodeId: String?,
        sourceAnchor: String,
        targetAnchor: String?
    ) -> [String: Any] {
        var row: [String: Any] = [
            "id": id,
            "idea_id": ideaId,
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

    func testAddConnection_withTarget_POSTsJSONAndDecodes() async throws {
        let row = Self.connectionResponseJSONObject(
            id: connectionId,
            ideaId: ideaId,
            mindmapId: mindmapId,
            sourceNodeId: sourceNodeId,
            targetNodeId: targetNodeId,
            sourceAnchor: "right",
            targetAnchor: "left"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/connections")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["sourceNodeId"] as? String, self.sourceNodeId)
            XCTAssertEqual(obj["targetNodeId"] as? String, self.targetNodeId)
            XCTAssertEqual(obj["sourceAnchor"] as? String, "right")
            XCTAssertEqual(obj["targetAnchor"] as? String, "left")

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.addConnection(
            sourceNodeId: sourceNodeId,
            sourceAnchor: .right,
            targetNodeId: targetNodeId,
            targetAnchor: .left,
            ideaId: ideaId,
            mindmapId: mindmapId,
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, connectionId)
        XCTAssertEqual(model.sourceNodeId, sourceNodeId)
        XCTAssertEqual(model.targetNodeId, targetNodeId)
        XCTAssertEqual(model.sourceAnchor, .right)
        XCTAssertEqual(model.targetAnchor, .left)
    }

    func testAddConnection_openEnded_omitsTargetFieldsInBody() async throws {
        let row = Self.connectionResponseJSONObject(
            id: connectionId,
            ideaId: ideaId,
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

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.addConnection(
            sourceNodeId: sourceNodeId,
            sourceAnchor: .bottom,
            ideaId: ideaId,
            mindmapId: mindmapId,
            accessToken: accessToken
        )

        XCTAssertNil(model.targetNodeId)
        XCTAssertNil(model.targetAnchor)
        XCTAssertEqual(model.sourceAnchor, .bottom)
    }

    func testDeleteConnection_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/connections/\(self.connectionId)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteConnection(id: connectionId, accessToken: accessToken)
    }
}
