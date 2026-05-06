import Foundation

/// Sends AI prompt requests via **`URLSession`** only (**`POST /ai/prompt`**) — no response interpretation beyond raw **`Data`**.
final class AIRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`POST {base}/ai/prompt`** with JSON body (**`AIPromptModel`**, snake_case keys) and **`Authorization: Bearer`**.
    func sendPrompt(_ prompt: AIPromptModel, accessToken: String) async throws -> (Data, URLResponse) {
        let url = baseURL
            .appendingPathComponent("ai", isDirectory: false)
            .appendingPathComponent("prompt", isDirectory: false)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let json = try encoder.encode(prompt)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }
}
