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
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case prompt
        case output
        case tokenCount
        case createdAt
    }

    init(
        id: String,
        conversationId: String,
        prompt: String,
        output: String,
        tokenCount: Int? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.conversationId = conversationId
        self.prompt = prompt
        self.output = output
        self.tokenCount = tokenCount
        self.createdAt = createdAt
    }
}
