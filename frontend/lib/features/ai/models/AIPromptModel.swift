import Foundation

/// Client-side envelope for calling the LLM: **`toolType`** (backend prompt layout / system stance), **`query`**, keyed **`context`**, **`ideaId`** / optional **`conversationId`**, and model knobs.
///
/// Encode with **`JSONEncoder.keyEncodingStrategy = .convertToSnakeCase`** so **`toolType`**/**`maxTokens`**/**`llmModel`** become **`tool_type`**/**`max_tokens`**/**`llm_model`** on the wire. When **`maxTokens`** or **`conversationId`** is **`nil`**, that key is omitted (**`encodeIfPresent`**).
///
/// **`context`** is built freely from a view-model: any **`String`** keys and values. Non-string payloads belong as encoded strings (e.g. JSON text) unless you evolve this type toward a richer **`Codable`** wrapper.
struct AIPromptModel: Codable, Sendable {
    /// Selects backend prompt construction / system prompt; wire key **`tool_type`** with snake_case encoding.
    var toolType: String
    var query: String
    var context: [String: String]
    var llmModel: String
    var temperature: Double
    /// **`nil`** = no explicit output-token cap (**`LlmResponseSettings.defaultMaxTokens`**).
    var maxTokens: Int?
    var ideaId: String
    /// **`nil`** = first message in a thread; backend creates a conversation and returns its id (stream **`conversation`** chunk or JSON **`conversation_id`**).
    var conversationId: String?

    enum CodingKeys: String, CodingKey {
        case toolType
        case query
        case context
        case llmModel
        case temperature
        case maxTokens
        case ideaId
        case conversationId
    }

    init(
        toolType: String = AIToolType.highlightedSnippet.rawValue,
        query: String,
        context: [String: String] = [:],
        llmModel: String = LlmResponseSettings.defaultLlmModel,
        temperature: Double = LlmResponseSettings.defaultTemperature,
        maxTokens: Int? = LlmResponseSettings.defaultMaxTokens,
        ideaId: String,
        conversationId: String? = nil
    ) {
        self.toolType = toolType
        self.query = query
        self.context = context
        self.llmModel = llmModel
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.ideaId = ideaId
        self.conversationId = conversationId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toolType = try container.decodeIfPresent(String.self, forKey: .toolType)
            ?? AIToolType.highlightedSnippet.rawValue
        query = try container.decode(String.self, forKey: .query)
        context = try container.decode([String: String].self, forKey: .context)
        llmModel = try container.decode(String.self, forKey: .llmModel)
        temperature = try container.decode(Double.self, forKey: .temperature)
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens)
        ideaId = try container.decode(String.self, forKey: .ideaId)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toolType, forKey: .toolType)
        try container.encode(query, forKey: .query)
        try container.encode(context, forKey: .context)
        try container.encode(llmModel, forKey: .llmModel)
        try container.encode(temperature, forKey: .temperature)
        try container.encodeIfPresent(maxTokens, forKey: .maxTokens)
        try container.encode(ideaId, forKey: .ideaId)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
    }
}

struct AICompletionUsageModel: Codable, Sendable {
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
    var cachedPromptTokens: Int?
}

struct AICompletionResponseModel: Codable, Sendable {
    var content: String
    var model: String
    var conversationId: String?
    var usage: AICompletionUsageModel
}
