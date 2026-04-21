import Foundation
import Supabase
import XCTest

@testable import SoloLib

/// Exercises **`AuthController`** → **`SupabaseClient`** → **`URLSession`** (Auth **`/auth/v1`** routes) with a stub transport.
private final class TestAuthLocalStorage: AuthLocalStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    func store(key: String, value: Data) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }

    func retrieve(key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func remove(key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = nil
    }
}

final class AuthControllerFlowTests: XCTestCase {
    private let supabaseURL = URL(string: "https://solo.test")!
    private let anonKey = "test-anon-key"

    private let userId = "00000000-0000-4000-8000-0000000000a1"
    private let userEmail = "user@solo.test"
    private let accessToken =
        "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTQwMDAtODAwMC0wMDAwMDAwMDAwYTEifQ.signature"

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeSupabase(session: URLSession) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: TestAuthLocalStorage(),
                    autoRefreshToken: false,
                    emitLocalSessionAsInitialSession: true
                ),
                global: SupabaseClientOptions.GlobalOptions(session: session)
            )
        )
    }

    private func makeController(session: URLSession) -> AuthController {
        AuthController(supabase: makeSupabase(session: session))
    }

    private static let fixtureISO8601 = "2024-06-01T12:00:00Z"

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

    /// **`URLSession`** may surface request bodies on **`httpBodyStream`**.
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

    private func userJSON(
        id: String = "00000000-0000-4000-8000-0000000000a1",
        email: String = "user@solo.test",
        userMetadata: [String: Any] = [:]
    ) -> [String: Any] {
        [
            "id": id,
            "aud": "authenticated",
            "role": "authenticated",
            "email": email,
            "app_metadata": [:],
            "user_metadata": userMetadata,
            "created_at": Self.fixtureISO8601,
            "updated_at": Self.fixtureISO8601,
            "is_anonymous": false,
        ]
    }

    private func sessionJSON(
        accessToken: String,
        refreshToken: String,
        user: [String: Any]
    ) -> [String: Any] {
        [
            "access_token": accessToken,
            "token_type": "bearer",
            "expires_in": 3600,
            "expires_at": 2_000_000_000,
            "refresh_token": refreshToken,
            "user": user,
        ]
    }

    // MARK: - Per-method coverage

    func testLogin_fullStack_POSTsTokenAndReturnsSession() async throws {
        let sessionPayload = try Self.jsonData(
            sessionJSON(
                accessToken: accessToken,
                refreshToken: "refresh-token",
                user: userJSON()
            )
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/auth/v1/token") == true)
            XCTAssertEqual(request.url?.query, "grant_type=password")
            let body = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(obj["email"] as? String, self.userEmail)
            XCTAssertEqual(obj["password"] as? String, "secret-pass")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, sessionPayload)
        }

        let session = try await makeController(session: makeURLSession()).login(
            model: AuthModel(
                firstName: "A",
                lastName: "B",
                email: userEmail,
                password: "secret-pass"
            )
        )
        XCTAssertEqual(session.accessToken, accessToken)
        XCTAssertEqual(session.user.email, userEmail)
    }

    func testSignUp_fullStack_POSTsSignupAndDecodesUserResponse() async throws {
        let newId = "00000000-0000-4000-8000-0000000000b2"
        let newEmail = "new@solo.test"
        let userOnly = try Self.jsonData(
            userJSON(
                id: newId,
                email: newEmail,
                userMetadata: [
                    "first_name": "Pat",
                    "last_name": "Lee",
                ]
            )
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/signup"))
            let body = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(obj["email"] as? String, newEmail)
            XCTAssertEqual(obj["password"] as? String, "p1")
            let dataObj = try XCTUnwrap(obj["data"] as? [String: Any])
            XCTAssertEqual(dataObj["first_name"] as? String, "Pat")
            XCTAssertEqual(dataObj["last_name"] as? String, "Lee")
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, userOnly)
        }

        let response = try await makeController(session: makeURLSession()).signUp(
            model: AuthModel(firstName: "Pat", lastName: "Lee", email: newEmail, password: "p1")
        )

        switch response {
        case .session:
            XCTFail("Expected .user for this fixture")
        case .user(let user):
            XCTAssertEqual(user.id.uuidString.lowercased(), newId.lowercased())
            XCTAssertEqual(user.email, newEmail)
        }
    }

    func testSignUp_throwsWhenFirstNameMissingAfterTrim() async throws {
        let controller = makeController(session: makeURLSession())
        do {
            _ = try await controller.signUp(
                model: AuthModel(firstName: "  ", lastName: "L", email: "e@e.com", password: "p")
            )
            XCTFail("Expected AuthValidationError.firstNameRequired")
        } catch AuthValidationError.firstNameRequired {
            // expected
        }
    }

    func testSignUp_throwsWhenLastNameMissingAfterTrim() async throws {
        let controller = makeController(session: makeURLSession())
        do {
            _ = try await controller.signUp(
                model: AuthModel(firstName: "F", lastName: "", email: "e@e.com", password: "p")
            )
            XCTFail("Expected AuthValidationError.lastNameRequired")
        } catch AuthValidationError.lastNameRequired {
            // expected
        }
    }

    func testResetPassword_fullStack_POSTsRecover() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/recover"))
            let body = Self.httpBodyData(from: request)
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(obj["email"] as? String, self.userEmail)
            let res = Self.httpResponse(for: request, statusCode: 200)
            return (res, Data())
        }

        try await makeController(session: makeURLSession()).resetPassword(email: userEmail)
    }

    func testLogout_fullStack_POSTsLogoutWithBearerFromSession() async throws {
        let sessionPayload = try Self.jsonData(
            sessionJSON(
                accessToken: accessToken,
                refreshToken: "refresh-token",
                user: userJSON()
            )
        )

        var step = 0
        MockURLProtocol.requestHandler = { request in
            step += 1
            if step == 1 {
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue(request.url?.path.contains("/auth/v1/token") == true)
                let res = Self.httpResponse(for: request, statusCode: 200)
                return (res, sessionPayload)
            }
            if step == 2 {
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/logout"))
                XCTAssertEqual(request.url?.query, "scope=global")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")
                let res = Self.httpResponse(for: request, statusCode: 204)
                return (res, Data())
            }
            XCTFail("Unexpected request step \(step)")
            return (Self.httpResponse(for: request, statusCode: 500), Data())
        }

        let urlSession = makeURLSession()
        let controller = makeController(session: urlSession)
        _ = try await controller.login(
            model: AuthModel(firstName: "A", lastName: "B", email: userEmail, password: "secret-pass")
        )
        try await controller.logout()
        XCTAssertEqual(step, 2)
    }

    // MARK: - Sequential flow (all four controller entry points)

    func testSequentialAuth_invokesLoginResetSignUpLogoutThroughSupabaseSession() async throws {
        final class StepCounter: @unchecked Sendable {
            var value = 0
        }
        let step = StepCounter()

        let newId = "00000000-0000-4000-8000-0000000000c3"
        let newEmail = "seq@solo.test"
        let sessionPayload = try Self.jsonData(
            sessionJSON(
                accessToken: accessToken,
                refreshToken: "refresh-token",
                user: userJSON()
            )
        )
        let userOnly = try Self.jsonData(
            userJSON(
                id: newId,
                email: newEmail,
                userMetadata: ["first_name": "S", "last_name": "Q"]
            )
        )

        MockURLProtocol.requestHandler = { request in
            step.value += 1
            switch step.value {
            case 1:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue(request.url?.path.contains("/auth/v1/token") == true)
                let res = Self.httpResponse(for: request, statusCode: 200)
                return (res, sessionPayload)
            case 2:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/recover"))
                let res = Self.httpResponse(for: request, statusCode: 200)
                return (res, Data())
            case 3:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/signup"))
                let res = Self.httpResponse(for: request, statusCode: 200)
                return (res, userOnly)
            case 4:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue((request.url?.path ?? "").hasSuffix("/auth/v1/logout"))
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.accessToken)")
                let res = Self.httpResponse(for: request, statusCode: 204)
                return (res, Data())
            default:
                XCTFail("Unexpected extra request")
                return (Self.httpResponse(for: request, statusCode: 500), Data())
            }
        }

        let controller = makeController(session: makeURLSession())

        _ = try await controller.login(
            model: AuthModel(firstName: "A", lastName: "B", email: userEmail, password: "secret-pass")
        )
        try await controller.resetPassword(email: userEmail)
        _ = try await controller.signUp(
            model: AuthModel(firstName: "S", lastName: "Q", email: newEmail, password: "pw")
        )
        try await controller.logout()

        XCTAssertEqual(step.value, 4)
    }
}
