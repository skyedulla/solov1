import XCTest

@testable import SoloLib

/// Exercises **`ObjectiveController`** → **`ObjectivesRemoteDataSource`** → **`URLSession`** with **`MockURLProtocol`**.
final class ObjectiveControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"
    private let ideaId = "00000000-0000-4000-8000-0000000000a1"
    private let objectiveId = "00000000-0000-4000-8000-0000000000b2"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeController() -> ObjectiveController {
        let remote = ObjectivesRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return ObjectiveController(remote: remote)
    }

    private static func objectiveResponseJSONObject(
        id: String,
        ideaId: String,
        text: String,
        isCompleted: Bool
    ) -> [String: Any] {
        [
            "id": id,
            "idea_id": ideaId,
            "text": text,
            "is_completed": isCompleted,
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

    func testAddObjective_fullStack_POSTsJSONAndDecodes() async throws {
        let row = Self.objectiveResponseJSONObject(
            id: objectiveId,
            ideaId: ideaId,
            text: "Learn Swift",
            isCompleted: false
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/objectives")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            XCTAssertFalse(posted.isEmpty)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["ideaId"] as? String, self.ideaId)
            XCTAssertEqual(obj["text"] as? String, "Learn Swift")

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.addObjective(
            ideaId: ideaId,
            text: "Learn Swift",
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, objectiveId)
        XCTAssertEqual(model.ideaId, ideaId)
        XCTAssertEqual(model.text, "Learn Swift")
        XCTAssertFalse(model.isCompleted)
    }

    func testModifyObjective_fullStack_PATCHesJSONAndDecodes() async throws {
        let row = Self.objectiveResponseJSONObject(
            id: objectiveId,
            ideaId: ideaId,
            text: "Updated text",
            isCompleted: false
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/objectives/\(self.objectiveId)")
            let posted = Self.httpBodyData(from: request)
            XCTAssertFalse(posted.isEmpty)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["text"] as? String, "Updated text")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.modifyObjective(
            id: objectiveId,
            text: "Updated text",
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, objectiveId)
        XCTAssertEqual(model.ideaId, ideaId)
        XCTAssertEqual(model.text, "Updated text")
    }

    func testCompleteObjective_fullStack_POSTsTogglePathAndDecodes() async throws {
        let row = Self.objectiveResponseJSONObject(
            id: objectiveId,
            ideaId: ideaId,
            text: "Done item",
            isCompleted: true
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/objectives/\(self.objectiveId)/complete")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty, "POST complete has no body")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.completeObjective(id: objectiveId, accessToken: accessToken)

        XCTAssertTrue(model.isCompleted)
        XCTAssertEqual(model.ideaId, ideaId)
        XCTAssertEqual(model.text, "Done item")
    }

    func testDeleteObjective_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/objectives/\(self.objectiveId)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteObjective(id: objectiveId, accessToken: accessToken)
    }
}
