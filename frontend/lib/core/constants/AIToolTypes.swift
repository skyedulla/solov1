import Foundation

enum AIToolType: String, Codable, Sendable, CaseIterable {
    case highlightedSnippet = "ai.highlighted_snippet"
    case planning = "ai.planning"
    case mindmap = "ai.mindmap"
    case research = "ai.research"
}
