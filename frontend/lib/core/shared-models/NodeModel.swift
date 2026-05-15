import Foundation

/// Graph vertex shared by mind maps and decision maps. Type-specific fields live in **`nodeType`**.
struct NodeModel: Codable, Sendable, Equatable {
    enum NodeType: Sendable, Equatable {
        case mindmapNode(MindmapNodeModel)
        case decisionMapNode(DecisionNodeModel)
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
        parentNodeId: String? = nil,
        position: Position,
        dimensions: Dimensions? = nil
    ) {
        self.id = id
        self.nodeType = nodeType
        self.parentNodeId = parentNodeId
        self.position = position
        self.dimensions = dimensions ?? Self.defaultDimensions(for: nodeType)
    }

    private static func defaultDimensions(for nodeType: NodeType) -> Dimensions {
        switch nodeType {
        case .mindmapNode:
            return MindmapNodeModel.defaultDimensions
        case .decisionMapNode:
            return DecisionNodeModel.defaultDimensions
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        parentNodeId = try c.decodeIfPresent(String.self, forKey: .parentNodeId)
        position = try c.decode(Position.self, forKey: .position)

        let resolvedNodeType: NodeType
        if let decisionMapId = try c.decodeIfPresent(String.self, forKey: .decisionMapId) {
            let icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? ""
            resolvedNodeType = .decisionMapNode(DecisionNodeModel(decisionMapId: decisionMapId, icon: icon))
        } else {
            let mindmapId = try c.decode(String.self, forKey: .mindmapId)
            let text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
            resolvedNodeType = .mindmapNode(MindmapNodeModel(mindmapId: mindmapId, text: text))
        }
        nodeType = resolvedNodeType
        dimensions = try c.decodeIfPresent(Dimensions.self, forKey: .dimensions)
            ?? Self.defaultDimensions(for: resolvedNodeType)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(parentNodeId, forKey: .parentNodeId)
        try c.encode(position, forKey: .position)
        try c.encode(dimensions, forKey: .dimensions)
        switch nodeType {
        case let .mindmapNode(payload):
            try c.encode(payload.mindmapId, forKey: .mindmapId)
            try c.encode(payload.text, forKey: .text)
        case let .decisionMapNode(payload):
            try c.encode(payload.decisionMapId, forKey: .decisionMapId)
            try c.encode(payload.icon, forKey: .icon)
        }
    }
}
