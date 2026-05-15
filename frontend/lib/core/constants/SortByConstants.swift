/// Sort options for idea lists. Each entry is a dictionary with **`label`** (UI copy) and **`value`** (sent to the API as the sort parameter).
/// Align **`value`** strings with the backend ideas endpoint contract.
enum SortByConstants {
    static let options: [[String: String]] = [
        ["label": "A–Z", "value": "title_asc"],
        ["label": "Newest", "value": "created_desc"],
        ["label": "Oldest", "value": "created_asc"],
        ["label": "Last updated", "value": "updated_desc"],
    ]
}
