import Foundation

actor AIViewModel {
    enum SendPromptError: Error {
        case emptyQuery
        case unacceptableHTTPStatus(Int)
    }

    enum AISurfaceContext: Sendable {
        case planning(ideaId: String, conversationId: String?)
        case research(ideaId: String, conversationId: String?)
        case mindmap(ideaId: String, mindmapId: String, conversationId: String?)
        case highlightedSnippet(
            ideaId: String,
            conversationId: String?,
            highlightedText: String
        )
    }

    enum RequestState: Equatable, Sendable {
        case idle
        case loading
        case success
        case failed(String)
    }

    private let remote: AIRemoteDataSource
    private(set) var promptInput: String = ""
    private(set) var requestState: RequestState = .idle
    private(set) var latestResponse: AICompletionResponseModel?
    private(set) var latestError: Error?

    init(remote: AIRemoteDataSource = AIRemoteDataSource()) {
        self.remote = remote
    }

    func updatePromptInput(_ input: String) {
        promptInput = input
    }

    func resetRequestState() {
        requestState = .idle
        latestError = nil
    }

    @discardableResult
    func sendPrompt(surface: AISurfaceContext, accessToken: String) async throws -> AICompletionResponseModel {
        let query = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            requestState = .failed("Prompt cannot be empty.")
            throw SendPromptError.emptyQuery
        }

        requestState = .loading
        latestError = nil

        let body = AIPromptModel(
            toolType: toolType(for: surface).rawValue,
            query: query,
            context: context(for: surface),
            llmModel: LlmResponseSettings.defaultLlmModel,
            temperature: LlmResponseSettings.defaultTemperature,
            maxTokens: LlmResponseSettings.defaultMaxTokens,
            ideaId: ideaId(for: surface),
            conversationId: conversationId(for: surface)
        )

        do {
            let response = try await remote.sendPrompt(body, accessToken: accessToken)
            latestResponse = response
            requestState = .success
            promptInput = ""
            return response
        } catch {
            latestError = error
            requestState = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Compatibility helper for early tests/screens that already pass request pieces directly.
    @discardableResult
    func sendPrompt(
        query: String,
        ideaId: String,
        conversationId: String? = nil,
        context: [String: String] = [:],
        accessToken: String
    ) async throws -> AICompletionResponseModel {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw SendPromptError.emptyQuery
        }

        let body = AIPromptModel(
            toolType: AIToolType.planning.rawValue,
            query: trimmedQuery,
            context: context,
            llmModel: LlmResponseSettings.defaultLlmModel,
            temperature: LlmResponseSettings.defaultTemperature,
            maxTokens: LlmResponseSettings.defaultMaxTokens,
            ideaId: ideaId,
            conversationId: conversationId
        )

        return try await remote.sendPrompt(body, accessToken: accessToken)
    }

    private func toolType(for surface: AISurfaceContext) -> AIToolType {
        switch surface {
        case .planning:
            return .planning
        case .research:
            return .research
        case .mindmap:
            return .mindmap
        case .highlightedSnippet:
            return .highlightedSnippet
        }
    }

    private func ideaId(for surface: AISurfaceContext) -> String {
        switch surface {
        case let .planning(ideaId, _),
             let .research(ideaId, _),
             let .mindmap(ideaId, _, _),
             let .highlightedSnippet(ideaId, _, _):
            return ideaId
        }
    }

    private func conversationId(for surface: AISurfaceContext) -> String? {
        switch surface {
        case let .planning(_, conversationId),
             let .research(_, conversationId),
             let .mindmap(_, _, conversationId),
             let .highlightedSnippet(_, conversationId, _):
            return conversationId
        }
    }

    private func context(for surface: AISurfaceContext) -> [String: String] {
        switch surface {
        case let .planning(ideaId, conversationId):
            var row = ["idea_id": ideaId]
            if let conversationId {
                row["conversation_id"] = conversationId
            }
            return row
        case let .research(ideaId, conversationId):
            var row = ["idea_id": ideaId]
            if let conversationId {
                row["conversation_id"] = conversationId
            }
            return row
        case let .mindmap(ideaId, mindmapId, conversationId):
            var row: [String: String] = [
                "idea_id": ideaId,
                "mindmap_id": mindmapId,
            ]
            if let conversationId {
                row["conversation_id"] = conversationId
            }
            return row
        case let .highlightedSnippet(ideaId, conversationId, highlightedText):
            var row: [String: String] = [
                "idea_id": ideaId,
                "highlighted_text": highlightedText,
            ]
            if let conversationId {
                row["conversation_id"] = conversationId
            }
            return row
        }
    }
}
