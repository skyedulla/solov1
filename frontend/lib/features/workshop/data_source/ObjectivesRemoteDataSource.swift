import Foundation

private struct AddObjectiveRequestBody: Encodable {
    let ideaId: String
    let text: String
}

private struct ModifyObjectiveRequestBody: Encodable {
    let text: String
}

/// **`URLSession`-only** I/O for **`/objectives`** — no response decoding.
final class ObjectivesRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    private func resourceURL() -> URL {
        baseURL.appendingPathComponent("objectives", isDirectory: false)
    }

    /// **`POST {base}/objectives`** with **`{ "ideaId": …, "text": … }`**, expects **`201`** and JSON body.
    func addObjective(ideaId: String, text: String, accessToken: String) async throws -> (Data, URLResponse) {
        let body = AddObjectiveRequestBody(ideaId: ideaId, text: text)
        let data = try JSONEncoder().encode(body)
        var request = URLRequest(url: resourceURL())
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await session.data(for: request)
    }

    /// **`PATCH {base}/objectives/{id}`** with **`{ "text": … }`**, expects **`200`**.
    func modifyObjective(id: String, text: String, accessToken: String) async throws -> (Data, URLResponse) {
        let body = ModifyObjectiveRequestBody(text: text)
        let data = try JSONEncoder().encode(body)
        let url = resourceURL().appendingPathComponent(id, isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = data
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await session.data(for: request)
    }

    /// **`POST {base}/objectives/{id}/complete`** (no body) — toggles **`is_completed`**, expects **`200`**.
    func completeObjective(id: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = resourceURL()
            .appendingPathComponent(id, isDirectory: false)
            .appendingPathComponent("complete", isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await session.data(for: request)
    }

    /// **`DELETE {base}/objectives/{id}`** — expects **`204`**.
    func deleteObjective(id: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = resourceURL().appendingPathComponent(id, isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await session.data(for: request)
    }
}
