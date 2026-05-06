import Foundation

actor AIViewModel {
    enum SendPromptError: Error {
        case unacceptableHTTPStatus(Int)
    }

    private let remote: AIRemoteDataSource

    init(remote: AIRemoteDataSource = AIRemoteDataSource()) {
        self.remote = remote
    }

    /// **`POST /ai/prompt`** via **`AIRemoteDataSource`**; builds an **`AIPromptModel`** (placeholder **`toolType`**).
    func sendPrompt(
        query: String,
        ideaId: String,
        conversationId: String,
        context: [String: String] = [:],
        accessToken: String
    ) async throws {
        let body = AIPromptModel(
            toolType: AIToolType.planning.rawValue,
            query: query,
            context: context,
            llmModel: LlmResponseSettings.defaultLlmModel,
            temperature: LlmResponseSettings.defaultTemperature,
            maxTokens: LlmResponseSettings.defaultMaxTokens,
            ideaId: ideaId,
            conversationId: conversationId
        )

        let (_, response) = try await remote.sendPrompt(body, accessToken: accessToken)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(status) else {
            throw SendPromptError.unacceptableHTTPStatus(status)
        }
    }
}
