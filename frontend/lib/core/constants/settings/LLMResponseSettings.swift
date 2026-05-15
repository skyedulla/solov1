/// Preset **`label`** / **`value`** rows for future LLM settings UI (**same shape as **`SortByConstants.options`**). Persistence and **`UserDefaults`** keys belong in the settings flow when you build the menu.
enum LlmResponseSettings {
    /// Default model when nothing is persisted (**`AIPromptModel.llmModel`**).
    static let defaultLlmModel = "gpt-4o-mini"
    /// Default sampling temperature.
    static let defaultTemperature = 0.7
    /// **`nil`** = no explicit output-token cap (**`AIPromptModel.maxTokens`** / **`max_tokens`** left unset unless the user chooses a limit).
    static let defaultMaxTokens: Int? = nil

    /// **`value`** = provider model identifier (**`AIPromptModel.llmModel`**).
    static let llmModelOptions: [[String: String]] = [
        ["label": "GPT-4o mini", "value": "gpt-4o-mini"],
    ]

    /// **`value`** as decimal string (**`Double`** when parsed).
    static let temperatureOptions: [[String: String]] = [
        ["label": "Precise", "value": "0.2"],
        ["label": "Balanced", "value": "0.7"],
        ["label": "Creative", "value": "1.2"],
    ]

    /// **`value`** as integer string (**`Int`** when parsed).
    static let maxTokenOptions: [[String: String]] = [
        ["label": "2K", "value": "2048"],
        ["label": "4K", "value": "4096"],
        ["label": "8K", "value": "8192"],
    ]
}
