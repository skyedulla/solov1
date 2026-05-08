import Foundation

/// Mind map node fields (**`idea_id`** lives on **`MindmapModel`**, not each node).
struct NodeModel: Codable, Sendable {
    var id: String
    var mindmapId: String
    var parentNodeId: String?
    var position: Position
    var text: String
    var dimensions: Dimensions

    struct Position: Codable, Sendable {
        var x: Int
        var y: Int
    }

    struct Dimensions: Codable, Sendable {
        var height: Int
        var width: Int
    }

    enum CodingKeys: String, CodingKey {
        case id
        case mindmapId = "mindmap_id"
        case parentNodeId = "parent_node_id"
        case position
        case text
        case dimensions
    }
}
