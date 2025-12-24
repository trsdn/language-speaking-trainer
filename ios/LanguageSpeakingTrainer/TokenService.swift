import Foundation

struct EphemeralTokenResponse: Decodable {
    let value: String
    let expires_at: Int?
}

enum TokenServiceError: Error {
    case missingBaseURL
    case invalidResponse
}

/// Fetches an ephemeral Realtime client secret from your Vercel backend.
///
/// This is server-minted so the iOS app never ships a standard OpenAI API key.
enum TokenService {
    static func fetchEphemeralToken(topic: Topic?) async throws -> EphemeralTokenResponse {
        guard let base = AppConfig.tokenServiceBaseURL else {
            throw TokenServiceError.missingBaseURL
        }

        var components = URLComponents(url: base.appendingPathComponent("/api/realtime/token"), resolvingAgainstBaseURL: false)
        if let topic {
            components?.queryItems = [
                URLQueryItem(name: "topic", value: topic.title)
            ]
        }
        guard let url = components?.url else { throw TokenServiceError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TokenServiceError.invalidResponse
        }

        return try JSONDecoder().decode(EphemeralTokenResponse.self, from: data)
    }
}
