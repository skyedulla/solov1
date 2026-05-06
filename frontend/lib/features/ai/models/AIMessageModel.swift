import Foundation

/// One turn in an AI conversation: user **`prompt`** and model **`output`** (persisted or in-flight).
struct AIMessageModel: Codable, Sendable {
    var id: String
    var conversationId: String
    var prompt: String
    /// Model reply; empty while streaming until the completion is stitched in.
    var output: String
    /// Total tokens reported by the provider (prompt + completion), if available.
    var tokenCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case prompt
        case output
        case tokenCount = "token_count"
    }
}
