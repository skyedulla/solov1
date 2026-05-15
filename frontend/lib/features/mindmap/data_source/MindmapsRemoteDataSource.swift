import Foundation

private struct CreateMindmapRequestBody: Encodable {
    let ideaId: String
}

/// Sends **`/mindmaps`** requests over **`URLSession`** only — no response interpretation here.
final class MindmapsRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`POST {base}/mindmaps`** with **`{ "ideaId": … }`** and **`Authorization: Bearer`** — returns raw **`URLSession`** result.
    func createMindmap(ideaId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL.appendingPathComponent("mindmaps", isDirectory: false)
        let body = CreateMindmapRequestBody(ideaId: ideaId)
        let encoder = JSONEncoder()
        let json = try encoder.encode(body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`GET {base}/mindmaps?idea_id=…`** with **`Authorization: Bearer`** — returns raw **`URLSession`** result.
    func listMindmaps(ideaId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let resourceURL = baseURL.appendingPathComponent("mindmaps", isDirectory: false)
        var components = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "idea_id", value: ideaId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`GET {base}/mindmaps/{id}?idea_id=…`** with **`Authorization: Bearer`** — full document (**wire** **`nodes`** / **`connections`** = **mindmap-nodes** / **mindmap-connections**); returns raw **`URLSession`** result.
    func loadMindmap(id: String, ideaId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let pathURL = baseURL
            .appendingPathComponent("mindmaps", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)
        var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "idea_id", value: ideaId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`POST {base}/mindmaps/{id}/generate-summary?idea_id=…`** — runs server summarization (**`OPENAI_API_KEY`**) and returns **`{ "summary": … }`** (**`200`**); **`503`** when the LLM is unavailable.
    func generateMindmapSummary(id: String, ideaId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let pathURL = baseURL
            .appendingPathComponent("mindmaps", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)
            .appendingPathComponent("generate-summary", isDirectory: false)
        var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "idea_id", value: ideaId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }

    /// **`DELETE {base}/mindmaps/{id}?idea_id=…`** with **`Authorization: Bearer`** — returns raw **`URLSession`** result (expect **`204`**).
    func deleteMindmap(id: String, ideaId: String, accessToken: String) async throws -> (Data, URLResponse) {
        let pathURL = baseURL
            .appendingPathComponent("mindmaps", isDirectory: false)
            .appendingPathComponent(id, isDirectory: false)
        var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "idea_id", value: ideaId)]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await session.data(for: request)
    }
}
