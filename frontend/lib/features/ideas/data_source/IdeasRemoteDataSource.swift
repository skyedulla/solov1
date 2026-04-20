import Foundation

/// Sends ideas list requests over the network via **`URLSession`** only — no routing or response interpretation here.
final class IdeasRemoteDataSource: Sendable {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AppConfiguration.apiBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    /// **`GET {base}/ideas?sort=…&q=…`** with **`Authorization: Bearer`** — returns the raw **`URLSession`** result.
    func fetchIdeas(filter: IdeaFilterModel, accessToken: String) async throws -> (Data, URLResponse) {
        let resourceURL = baseURL.appendingPathComponent("ideas", isDirectory: false)
        var components = URLComponents(url: resourceURL, resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "sort", value: filter.sortBy)]
        let q = filter.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: q))
        }
        components.queryItems = queryItems
        let url = components.url!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await session.data(for: request)
    }
}
