import Foundation

/// Coordinates idea persistence and domain flows (create, update, publish, list, etc.).
final class IdeaController: Sendable {
    private let remote: IdeasRemoteDataSource

    init(remote: IdeasRemoteDataSource = IdeasRemoteDataSource()) {
        self.remote = remote
    }

    /// Loads all ideas for the current user using **`filter`** for sort (and optional search). Response handling will be layered in later.
    func fetchIdeas(using filter: IdeaFilterModel, accessToken: String) async throws -> [IdeaModel] {
        let (data, _) = try await remote.fetchIdeas(filter: filter, accessToken: accessToken)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([IdeaModel].self, from: data)
    }

    /// Creates a new idea (**`title`** and **`purpose`** required; **`description`** and **`targetUser`** optional) and returns the persisted **`IdeaModel`**.
    func createNewIdea(
        title: String,
        purpose: String,
        description: String? = nil,
        targetUser: String? = nil,
        accessToken: String
    ) async throws -> IdeaModel {
        let (data, _) = try await remote.createNewIdea(
            title: title,
            purpose: purpose,
            description: description,
            targetUser: targetUser,
            accessToken: accessToken
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(IdeaModel.self, from: data)
    }

    /// Updates an existing idea (**`title`** and **`purpose`** required; **`description`** and **`targetUser`** optional — omitted fields stay unchanged on the server). Returns the updated **`IdeaModel`**.
    func editIdea(
        id: String,
        title: String,
        purpose: String,
        description: String? = nil,
        targetUser: String? = nil,
        isPublished: Bool? = nil,
        accessToken: String
    ) async throws -> IdeaModel {
        let (data, response) = try await remote.updateIdea(
            id: id,
            title: title,
            purpose: purpose,
            description: description,
            targetUser: targetUser,
            isPublished: isPublished,
            accessToken: accessToken
        )
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(IdeaModel.self, from: data)
    }

    /// Deletes the idea with **`id`** for the authenticated user. **`204`** from the API is treated as success.
    func deleteIdea(id: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteIdea(id: id, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }

    /// Flips **`isPublished`** for **`idea`** via **`PATCH …/ideas/:id`** and returns the updated **`IdeaModel`**.
    func togglePublished(idea: IdeaModel, accessToken: String) async throws -> IdeaModel {
        try await editIdea(
            id: idea.id,
            title: idea.title,
            purpose: idea.purpose,
            description: idea.description,
            targetUser: idea.targetUser,
            isPublished: !idea.isPublished,
            accessToken: accessToken
        )
    }
}
