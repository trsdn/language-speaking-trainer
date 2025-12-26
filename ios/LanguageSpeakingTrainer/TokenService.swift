import Foundation

struct EphemeralTokenResponse: Decodable {
    let value: String
    let expires_at: Int?
}

enum TokenServiceError: Error {
    case missingBaseURL
    case missingSharedSecret
    case invalidResponse
    case httpError(status: Int, body: String)
}

extension TokenServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "Missing TOKEN_SERVICE_BASE_URL"
        case .missingSharedSecret:
            return "Missing TOKEN_SERVICE_SHARED_SECRET"
        case .invalidResponse:
            return "Invalid response from token service"
        case .httpError(let status, let body):
            if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Token service HTTP error (status: \(status))"
            }
            return "Token service HTTP error (status: \(status)): \(body)"
        }
    }
}

/// Fetches an ephemeral Realtime client secret from your Vercel backend.
///
/// This is server-minted so the iOS app never ships a standard OpenAI API key.
enum TokenService {
    static func fetchEphemeralToken(topic: Topic?) async throws -> EphemeralTokenResponse {
        guard let base = AppConfig.tokenServiceBaseURL else {
            throw TokenServiceError.missingBaseURL
        }

        guard let sharedSecret = AppConfig.tokenServiceSharedSecret else {
            throw TokenServiceError.missingSharedSecret
        }

        // NOTE: Do not include a leading "/" in `appendingPathComponent`.
        // A leading slash can become percent-encoded and produce URLs like:
        //   https://example.com/%2Fapi%2Frealtime%2Ftoken
        let tokenURL = base
            .appendingPathComponent("api")
            .appendingPathComponent("realtime")
            .appendingPathComponent("token")

        var components = URLComponents(url: tokenURL, resolvingAgainstBaseURL: false)
        if let topic {
            components?.queryItems = [
                URLQueryItem(name: "topic", value: topic.title)
            ]
        }
        guard let url = components?.url else { throw TokenServiceError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue(sharedSecret, forHTTPHeaderField: "X-Token-Service-Secret")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw TokenServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TokenServiceError.httpError(status: http.statusCode, body: body)
        }

        return try JSONDecoder().decode(EphemeralTokenResponse.self, from: data)
    }
}
