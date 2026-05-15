import Foundation

/// Graph vertex shared by mind maps and decision maps. Type-specific fields live in **`nodeType`**.
struct NodeModel: Codable, Sendable, Equatable {
    enum NodeType: Sendable, Equatable {
        /// **`mindmap_id`** + **`text`** in API JSON.
        case mindmapNode(mindmapId: String, text: String)
        /// **`decision_map_id`** + **`icon`** in API JSON.
        case decisionMapNode(decisionMapId: String, icon: String)
    }

    var id: String
    var nodeType: NodeType
    var parentNodeId: String?
    var position: Position
    var dimensions: Dimensions

    struct Position: Codable, Sendable, Equatable {
        var x: Int
        var y: Int
    }

    struct Dimensions: Codable, Sendable, Equatable {
        var height: Int
        var width: Int
    }

    enum CodingKeys: String, CodingKey {
        case id
        case mindmapId = "mindmap_id"
        case decisionMapId = "decision_map_id"
        case parentNodeId = "parent_node_id"
        case position
        case text
        case dimensions
        case icon
    }

    init(
        id: String,
        nodeType: NodeType,
        parentNodeId: String?,
        position: Position,
        dimensions: Dimensions
    ) {
        self.id = id
        self.nodeType = nodeType
        self.parentNodeId = parentNodeId
        self.position = position
        self.dimensions = dimensions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        parentNodeId = try c.decodeIfPresent(String.self, forKey: .parentNodeId)
        position = try c.decode(Position.self, forKey: .position)
        dimensions = try c.decode(Dimensions.self, forKey: .dimensions)

        if let decisionMapId = try c.decodeIfPresent(String.self, forKey: .decisionMapId) {
            let icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? ""
            nodeType = .decisionMapNode(decisionMapId: decisionMapId, icon: icon)
        } else {
            let mindmapId = try c.decode(String.self, forKey: .mindmapId)
            let text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
            nodeType = .mindmapNode(mindmapId: mindmapId, text: text)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(parentNodeId, forKey: .parentNodeId)
        try c.encode(position, forKey: .position)
        try c.encode(dimensions, forKey: .dimensions)
        switch nodeType {
        case let .mindmapNode(mindmapId, text):
            try c.encode(mindmapId, forKey: .mindmapId)
            try c.encode(text, forKey: .text)
        case let .decisionMapNode(decisionMapId, icon):
            try c.encode(decisionMapId, forKey: .decisionMapId)
            try c.encode(icon, forKey: .icon)
        }
    }
}
