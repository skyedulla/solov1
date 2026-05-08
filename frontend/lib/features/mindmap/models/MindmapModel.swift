import Foundation

/// Full mind map document: graph plus last-known viewport.
struct MindmapModel: Codable, Sendable {
    var id: String
    var ideaId: String
    /// Display title from **`mindmaps.title`** (same key in **`GET`** / **`POST`** JSON).
    var title: String
    var nodes: [NodeModel]
    var connections: [ConnectionModel]
    var lastTransform: MindmapViewTransform

    /// Last pan and zoom for restoring the canvas view.
    struct MindmapViewTransform: Codable, Sendable {
        var scale: Double
        var translateX: Double
        var translateY: Double

        enum CodingKeys: String, CodingKey {
            case scale
            case translateX = "translate_x"
            case translateY = "translate_y"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ideaId = "idea_id"
        case title
        case nodes
        case connections
        case lastTransform = "last_transform"
    }
}
