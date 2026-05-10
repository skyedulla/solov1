import Foundation

/// Sends AI prompt requests via **`URLSession`** only (**`POST /ai/prompt`**).
final class AIRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`POST {base}/ai/prompt`** with JSON body (**`AIPromptModel`**, snake_case keys) and **`Authorization: Bearer`**.
    func sendPromptRaw(_ prompt: AIPromptModel, accessToken: String) async throws -> (Data, URLResponse) {
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

    func sendPrompt(_ prompt: AIPromptModel, accessToken: String) async throws -> AICompletionResponseModel {
        let (data, response) = try await sendPromptRaw(prompt, accessToken: accessToken)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            throw AIRemoteDataSourceError.unacceptableHTTPStatus(status)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AICompletionResponseModel.self, from: data)
    }
}

enum AIRemoteDataSourceError: Error, Equatable {
    case unacceptableHTTPStatus(Int)
}
