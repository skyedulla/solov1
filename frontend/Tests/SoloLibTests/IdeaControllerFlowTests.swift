import XCTest

@testable import SoloLib

/// Exercises **`IdeaController`** → **`IdeasRemoteDataSource`** → **`URLSession`** with a stub transport.
/// The network is mocked at the protocol level so decoding, headers, methods, paths, and bodies still run for real.
final class IdeaControllerFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://solo.test")!
    private let accessToken = "test-access-token"

    private let ideaId = "00000000-0000-4000-8000-0000000000a1"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeController() -> IdeaController {
        let remote = IdeasRemoteDataSource(session: makeSession(), baseURL: baseURL)
        return IdeaController(remote: remote)
    }

    /// Matches **`JSONDecoder`** **`.iso8601`** on Apple platforms (no fractional seconds in the default strategy).
    private static let fixtureISO8601 = "2024-06-01T12:00:00Z"

    private static func ideaResponseJSONObject(
        id: String,
        title: String,
        description: String,
        purpose: String,
        targetUser: String,
        isPublished: Bool = false,
        createdAt: String = IdeaControllerFlowTests.fixtureISO8601,
        lastUpdatedAt: String = IdeaControllerFlowTests.fixtureISO8601
    ) -> [String: Any] {
        [
            "id": id,
            "title": title,
            "description": description,
            "is_published": isPublished,
            "created_at": createdAt,
            "last_updated_at": lastUpdatedAt,
            "target_user": targetUser,
            "purpose": purpose,
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

    /// **`URLSession`** often supplies **`httpBodyStream`** instead of **`httpBody`** for uploads.
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

    // MARK: - Per-method coverage

    func testFetchIdeas_fullStack_GETsListAndDecodes() async throws {
        let row = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Listed",
            description: "D",
            purpose: "P",
            targetUser: "TU"
        )
        let listPayload = try Self.jsonData([row])

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/ideas")
            XCTAssertEqual(request.url?.query, "sort=created_desc")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, listPayload)
        }

        let controller = makeController()
        let filter = IdeaFilterModel(sortBy: "created_desc", searchQuery: "")
        let ideas = try await controller.fetchIdeas(using: filter, accessToken: accessToken)

        XCTAssertEqual(ideas.count, 1)
        XCTAssertEqual(ideas[0].id, ideaId)
        XCTAssertEqual(ideas[0].title, "Listed")
    }

    func testFetchIdeas_includesSearchQueryWhenNonEmpty() async throws {
        let listPayload = try Self.jsonData([] as [[String: Any]])

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.query, "sort=title_asc&q=hello")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, listPayload)
        }

        let controller = makeController()
        let filter = IdeaFilterModel(sortBy: "title_asc", searchQuery: "hello")
        _ = try await controller.fetchIdeas(using: filter, accessToken: accessToken)
    }

    func testCreateNewIdea_fullStack_POSTsJSONAndDecodes() async throws {
        let row = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "New title",
            description: "New desc",
            purpose: "New purpose",
            targetUser: "Readers"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/ideas")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")

            let posted = Self.httpBodyData(from: request)
            XCTAssertFalse(posted.isEmpty, "Expected JSON body on POST")
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["title"] as? String, "New title")
            XCTAssertEqual(obj["purpose"] as? String, "New purpose")
            XCTAssertEqual(obj["description"] as? String, "New desc")
            XCTAssertEqual(obj["targetUser"] as? String, "Readers")

            let res = Self.httpResponse(for: request, statusCode: 201)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.createNewIdea(
            title: "New title",
            purpose: "New purpose",
            description: "New desc",
            targetUser: "Readers",
            accessToken: accessToken
        )

        XCTAssertEqual(model.id, ideaId)
        XCTAssertEqual(model.title, "New title")
    }

    func testEditIdea_fullStack_PATCHesJSONAndDecodes() async throws {
        let row = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Edited",
            description: "E desc",
            purpose: "E purpose",
            targetUser: "TU"
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/ideas/\(self.ideaId)")
            let posted = Self.httpBodyData(from: request)
            XCTAssertFalse(posted.isEmpty, "Expected JSON body on PATCH")
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["title"] as? String, "Edited")
            XCTAssertEqual(obj["purpose"] as? String, "E purpose")

            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.editIdea(
            id: ideaId,
            title: "Edited",
            purpose: "E purpose",
            description: nil,
            targetUser: nil,
            accessToken: accessToken
        )

        XCTAssertEqual(model.title, "Edited")
        XCTAssertEqual(model.id, ideaId)
    }

    func testTogglePublished_fullStack_PATCHesFlippedIsPublishedAndDecodes() async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let at = try XCTUnwrap(formatter.date(from: Self.fixtureISO8601))
        let idea = IdeaModel(
            id: ideaId,
            title: "T",
            description: "D",
            isPublished: false,
            createdAt: at,
            lastUpdatedAt: at,
            targetUser: "U",
            purpose: "P"
        )
        let row = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "T",
            description: "D",
            purpose: "P",
            targetUser: "U",
            isPublished: true
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/ideas/\(self.ideaId)")
            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["isPublished"] as? Bool, true)
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.togglePublished(idea: idea, accessToken: accessToken)
        XCTAssertTrue(model.isPublished)
    }

    func testTogglePublished_fullStack_flipsTrueToFalse() async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let at = try XCTUnwrap(formatter.date(from: Self.fixtureISO8601))
        let idea = IdeaModel(
            id: ideaId,
            title: "T",
            description: "D",
            isPublished: true,
            createdAt: at,
            lastUpdatedAt: at,
            targetUser: "U",
            purpose: "P"
        )
        let row = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "T",
            description: "D",
            purpose: "P",
            targetUser: "U",
            isPublished: false
        )
        let body = try Self.jsonData(row)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            let posted = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
            XCTAssertEqual(obj["isPublished"] as? Bool, false)
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, body)
        }

        let controller = makeController()
        let model = try await controller.togglePublished(idea: idea, accessToken: accessToken)
        XCTAssertFalse(model.isPublished)
    }

    func testEditIdea_throwsWhenStatusNot200() async throws {
        MockURLProtocol.requestHandler = { request in
            let res = Self.httpResponse(for: request, statusCode: 500)
            return (res, Data())
        }

        let controller = makeController()
        do {
            _ = try await controller.editIdea(
                id: ideaId,
                title: "T",
                purpose: "P",
                accessToken: accessToken
            )
            XCTFail("Expected URLError.badServerResponse")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badServerResponse)
        }
    }

    func testDeleteIdea_fullStack_DELETEsAndAccepts204() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/ideas/\(self.ideaId)")
            XCTAssertTrue(Self.httpBodyData(from: request).isEmpty)
            let res = Self.httpResponse(for: request, statusCode: 204)
            return (res, Data())
        }

        let controller = makeController()
        try await controller.deleteIdea(id: ideaId, accessToken: accessToken)
    }

    func testDeleteIdea_throwsWhenNot204() async throws {
        MockURLProtocol.requestHandler = { request in
            let res = Self.httpResponse(for: request, statusCode: 404)
            let data = try Self.jsonData(["error": "Idea not found"])
            return (res, data)
        }

        let controller = makeController()
        do {
            try await controller.deleteIdea(id: ideaId, accessToken: accessToken)
            XCTFail("Expected URLError.badServerResponse")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badServerResponse)
        }
    }

    // MARK: - Sequential flow (create → list → edit → toggle publish → delete)

    func testSequentialCRUD_invokesAllFourControllerMethodsThroughDataSource() async throws {
        final class StepCounter: @unchecked Sendable {
            var value = 0
        }
        let step = StepCounter()

        let created = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Alpha",
            description: "",
            purpose: "Why",
            targetUser: ""
        )
        let listed = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Alpha",
            description: "",
            purpose: "Why",
            targetUser: ""
        )
        let updated = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Beta",
            description: "Now",
            purpose: "Why",
            targetUser: ""
        )
        let toggled = Self.ideaResponseJSONObject(
            id: ideaId,
            title: "Beta",
            description: "Now",
            purpose: "Why",
            targetUser: "",
            isPublished: true
        )

        let expectedId = ideaId
        MockURLProtocol.requestHandler = { request in
            step.value += 1
            switch step.value {
            case 1:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.url?.path, "/ideas")
                let res = Self.httpResponse(for: request, statusCode: 201)
                let data = try Self.jsonData(created)
                return (res, data)
            case 2:
                XCTAssertEqual(request.httpMethod, "GET")
                XCTAssertEqual(request.url?.path, "/ideas")
                let res = Self.httpResponse(for: request, statusCode: 200)
                let data = try Self.jsonData([listed])
                return (res, data)
            case 3:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertEqual(request.url?.path, "/ideas/\(expectedId)")
                let res = Self.httpResponse(for: request, statusCode: 200)
                let data = try Self.jsonData(updated)
                return (res, data)
            case 4:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertEqual(request.url?.path, "/ideas/\(expectedId)")
                let posted = Self.httpBodyData(from: request)
                let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: posted) as? [String: Any])
                XCTAssertEqual(obj["isPublished"] as? Bool, true)
                let res = Self.httpResponse(for: request, statusCode: 200)
                let data = try Self.jsonData(toggled)
                return (res, data)
            case 5:
                XCTAssertEqual(request.httpMethod, "DELETE")
                XCTAssertEqual(request.url?.path, "/ideas/\(expectedId)")
                let res = Self.httpResponse(for: request, statusCode: 204)
                return (res, Data())
            default:
                XCTFail("Unexpected extra request: \(request.httpMethod ?? "?") \(request.url?.path ?? "")")
                let res = Self.httpResponse(for: request, statusCode: 500)
                return (res, Data())
            }
        }

        let controller = makeController()

        let createdModel = try await controller.createNewIdea(
            title: "Alpha",
            purpose: "Why",
            accessToken: accessToken
        )
        XCTAssertEqual(createdModel.id, ideaId)

        let filter = IdeaFilterModel(sortBy: "created_desc", searchQuery: "")
        let list = try await controller.fetchIdeas(using: filter, accessToken: accessToken)
        XCTAssertTrue(list.contains { $0.id == ideaId })

        let edited = try await controller.editIdea(
            id: ideaId,
            title: "Beta",
            purpose: "Why",
            description: "Now",
            accessToken: accessToken
        )
        XCTAssertEqual(edited.title, "Beta")

        let afterToggle = try await controller.togglePublished(idea: edited, accessToken: accessToken)
        XCTAssertTrue(afterToggle.isPublished)

        try await controller.deleteIdea(id: ideaId, accessToken: accessToken)
        XCTAssertEqual(step.value, 5)
    }
}
