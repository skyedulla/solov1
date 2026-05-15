import Foundation

/// Mind map canvas: appearance, grid snap, and viewport.
struct MindmapCanvasModel: Codable, Sendable {
    /// When **`snapToGrid`** is enabled, **mindmap-node** positions are rounded to this increment (**5** pt).
    static let defaultSnapToGrid: Int = 5

    var id: String
    /// e.g. hex `"#1C1C1E"`; align with your color picker / `Color` mapping.
    var backgroundColor: String
    var backgroundDesign: BackgroundDesign
    /// When **`true`**, **mindmap-node** moves snap to **`defaultSnapToGrid`** (**5**).
    var snapToGrid: Bool
    var zoomLevel: Double
    var panPosition: PanPosition

    struct PanPosition: Codable, Sendable {
        var x: Double
        var y: Double
    }

    enum CodingKeys: String, CodingKey {
        case id
        case backgroundColor = "background_color"
        case backgroundDesign = "background_design"
        case snapToGrid = "snap_to_grid"
        case zoomLevel = "zoom_level"
        case panPosition = "pan_position"
    }
}
