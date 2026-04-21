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
}
