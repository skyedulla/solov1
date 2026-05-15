import Foundation

/// Idea-level mind map list: create, list summaries, regenerate summary, delete. Use **`MindmapViewModel`** when opening the canvas.
final class MindmapManagementViewModel: Sendable {
    private let controller: MindmapController

    init(controller: MindmapController = MindmapController()) {
        self.controller = controller
    }

    func createMindmap(ideaId: String, accessToken: String) async throws -> MindmapModel {
        try await controller.createMindmap(ideaId: ideaId, accessToken: accessToken)
    }

    func listMindmaps(ideaId: String, accessToken: String) async throws -> [MindmapSummaryModel] {
        try await controller.listMindmaps(ideaId: ideaId, accessToken: accessToken)
    }

    func generateMindmapSummary(id: String, ideaId: String, accessToken: String) async throws -> String {
        try await controller.generateMindmapSummary(id: id, ideaId: ideaId, accessToken: accessToken)
    }

    func deleteMindmap(id: String, ideaId: String, accessToken: String) async throws {
        try await controller.deleteMindmap(id: id, ideaId: ideaId, accessToken: accessToken)
    }
}
