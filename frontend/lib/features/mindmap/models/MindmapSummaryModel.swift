import Foundation

/// One row from **`GET …/mindmaps?idea_id=`** — metadata only (no graph).
struct MindmapSummaryModel: Codable, Sendable {
    var id: String
    var ideaId: String
    var title: String
    var summary: String
    var createdAt: Date
    var lastUpdatedAt: Date
}
