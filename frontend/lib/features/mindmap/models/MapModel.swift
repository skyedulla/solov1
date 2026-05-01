import Foundation

/// Full mind map document: graph plus last-known viewport.
struct MapModel: Codable, Sendable {
    var id: String
    var nodes: [NodeModel]
    var connections: [ConnectionModel]
    var lastTransform: MapViewTransform

    /// Last pan and zoom for restoring the canvas view.
    struct MapViewTransform: Codable, Sendable {
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
        case nodes
        case connections
        case lastTransform = "last_transform"
    }
}
