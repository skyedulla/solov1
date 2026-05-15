/// Render style for the mind map canvas background.
/// Raw values are stable for JSON and API use (`"none"`, `"dots"`).
enum BackgroundDesign: String, Codable, Sendable, CaseIterable {
    case none
    case dots
}

/// Labels and option sets for **`.dots`**-style UIs; **`BackgroundDesign`** is the value sent/stored.
enum BackgroundDesignConstants {
    static let options: [BackgroundDesign] = BackgroundDesign.allCases
}
