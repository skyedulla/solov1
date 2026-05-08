import Foundation

/// Coordinates the full mind map document (**`MindmapModel`**) with remote persistence.
final class MindmapController: Sendable {
    private let remote: MindmapsRemoteDataSource

    init(remote: MindmapsRemoteDataSource = MindmapsRemoteDataSource()) {
        self.remote = remote
    }

    /// Creates a mind map on the server (**`POST …/mindmaps`**) and returns an empty local document whose **`id`** is the persisted **`mindmaps.id`**.
    func createMindmap(ideaId: String, accessToken: String) async throws -> MindmapModel {
        let (data, response) = try await remote.createMindmap(ideaId: ideaId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse, http.statusCode == 201 else {
            throw MindmapControllerError.unexpectedCreateResponse
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let created = try decoder.decode(MindmapCreatedResponse.self, from: data)
        return MindmapModel(
            id: created.id,
            ideaId: ideaId,
            title: created.title,
            nodes: [],
            connections: [],
            lastTransform: MindmapModel.MindmapViewTransform(scale: 1, translateX: 0, translateY: 0)
        )
    }

    /// Loads a full mind map (**`GET …/mindmaps/{id}?idea_id=…`**, **`200`**) — **`id`** and **`ideaId`** must match the server row for the current user.
    func loadMindmap(id: String, ideaId: String, accessToken: String) async throws -> MindmapModel {
        let (data, response) = try await remote.loadMindmap(id: id, ideaId: ideaId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse else {
            throw MindmapControllerError.unexpectedLoadResponse
        }
        switch http.statusCode {
        case 200:
            break
        case 404:
            throw MindmapControllerError.mindmapNotFound
        default:
            throw MindmapControllerError.unexpectedLoadResponse
        }
        let decoder = JSONDecoder()
        // Match **`MindmapModel`** and nested types: they use explicit snake_case **`CodingKeys`**; **`.convertFromSnakeCase`** would mis-resolve those keys.
        return try decoder.decode(MindmapModel.self, from: data)
    }

    /// Lists mind maps for an idea (**`GET …/mindmaps?idea_id=…`**, **`200`**) — newest **`last_updated_at`** first.
    func listMindmaps(ideaId: String, accessToken: String) async throws -> [MindmapSummaryModel] {
        let (data, response) = try await remote.listMindmaps(ideaId: ideaId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse else {
            throw MindmapControllerError.unexpectedListResponse
        }
        guard http.statusCode == 200 else {
            throw MindmapControllerError.unexpectedListResponse
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MindmapSummaryModel].self, from: data)
    }

    /// Regenerates **`summary`** from title + nodes + connections (**`POST …/mindmaps/{id}/generate-summary?idea_id=…`**) and returns the new text (**`200`**). Persists on the server.
    func generateMindmapSummary(id: String, ideaId: String, accessToken: String) async throws -> String {
        let (data, response) = try await remote.generateMindmapSummary(id: id, ideaId: ideaId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse else {
            throw MindmapControllerError.unexpectedGenerateSummaryResponse
        }
        switch http.statusCode {
        case 200:
            break
        case 404:
            throw MindmapControllerError.mindmapNotFound
        case 503:
            throw MindmapControllerError.summaryGenerationUnavailable
        default:
            throw MindmapControllerError.unexpectedGenerateSummaryResponse
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let body = try decoder.decode(MindmapGeneratedSummaryBody.self, from: data)
        return body.summary
    }

    /// Deletes a mind map and its nodes and connections (**`DELETE …/mindmaps/{id}?idea_id=…`**, **`204`**).
    func deleteMindmap(id: String, ideaId: String, accessToken: String) async throws {
        let (_, response) = try await remote.deleteMindmap(id: id, ideaId: ideaId, accessToken: accessToken)
        guard let http = response as? HTTPURLResponse else {
            throw MindmapControllerError.unexpectedDeleteResponse
        }
        switch http.statusCode {
        case 204:
            return
        case 404:
            throw MindmapControllerError.mindmapNotFound
        default:
            throw MindmapControllerError.unexpectedDeleteResponse
        }
    }
}

private struct MindmapCreatedResponse: Decodable {
    let id: String
    let title: String
}

private struct MindmapGeneratedSummaryBody: Decodable {
    let summary: String
}

enum MindmapControllerError: Error {
    case unexpectedCreateResponse
    case unexpectedLoadResponse
    case unexpectedListResponse
    case unexpectedGenerateSummaryResponse
    case summaryGenerationUnavailable
    case unexpectedDeleteResponse
    case mindmapNotFound
}
