import Foundation

/// Filter and query state for searching ideas (mind map: IdeaFilter).
struct IdeaFilterModel: Codable, Sendable {
    /// API sort token; match the **`value`** field from ``SortByConstants/options``.
    var sortBy: String
    var searchQuery: String
}
