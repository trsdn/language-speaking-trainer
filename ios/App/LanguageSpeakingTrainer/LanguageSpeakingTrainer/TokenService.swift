import Foundation

struct EphemeralTokenResponse: Decodable {
    let value: String
    let expires_at: Int?
}

enum TokenServiceError: Error {
    case missingOpenAIAPIKey
    case invalidResponse
    case httpError(status: Int, body: String)
}

extension TokenServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingOpenAIAPIKey:
            return "Missing OpenAI API key. Set it in Settings (OpenAI BYOK), or configure OPENAI_API_KEY as an Xcode Scheme environment variable."
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

enum TokenService {
    static func fetchEphemeralToken(
        topic: Topic?,
        learner: String? = nil,
        mode: RealtimeModelPreference = .realtimeMini
    ) async throws -> EphemeralTokenResponse {
        guard let apiKey = AppConfig.openAIAPIKey else {
            throw TokenServiceError.missingOpenAIAPIKey
        }

        return try await OpenAIDirectTokenMinter.mintClientSecret(
            apiKey: apiKey,
            topic: topic,
            learner: learner,
            mode: mode
        )
    }
}

private enum OpenAIDirectTokenMinter {
    private struct OpenAIClientSecretResponse: Decodable {
        let value: String
        let expires_at: Int?
    }

    // Mirrors the backend's request body, but is client-owned for BYOK mode.
    private struct RequestBody: Encodable {
        struct ExpiresAfter: Encodable {
            let anchor: String
            let seconds: Int
        }
        struct Session: Encodable {
            struct Audio: Encodable {
                struct Output: Encodable {
                    let voice: String
                }
                let output: Output
            }

            let type: String
            let model: String
            let instructions: String
            let audio: Audio
        }

        let expires_after: ExpiresAfter
        let session: Session
    }

    static func mintClientSecret(
        apiKey: String,
        topic: Topic?,
        learner: String?,
        mode: RealtimeModelPreference
    ) async throws -> EphemeralTokenResponse {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TokenServiceError.missingOpenAIAPIKey
        }

        // Keep the mapping explicit and consistent with the backend defaults.
        let modelId: String
        switch mode {
        case .realtime:
            modelId = "gpt-realtime"
        case .realtimeMini:
            modelId = "gpt-realtime-mini"
        }

        // Keep these aligned with backend defaults. (Can be made configurable later.)
        let ttlSeconds = 600
        let voice = "alloy"

        var instructions = OpenAIRealtimeInstructions.base
        if let learner, !learner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            instructions += "\n\n\(learner)"
        }
        if let topic {
            instructions += "\n\nSelected topic: \(topic.title)"
        }

        let body = RequestBody(
            expires_after: .init(anchor: "created_at", seconds: max(60, min(ttlSeconds, 3600))),
            session: .init(
                type: "realtime",
                model: modelId,
                instructions: instructions,
                audio: .init(output: .init(voice: voice))
            )
        )

        guard let url = URL(string: "https://api.openai.com/v1/realtime/client_secrets") else {
            throw TokenServiceError.invalidResponse
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw TokenServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw TokenServiceError.httpError(status: http.statusCode, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(OpenAIClientSecretResponse.self, from: data)
        return EphemeralTokenResponse(value: decoded.value, expires_at: decoded.expires_at)
    }
}

private enum OpenAIRealtimeInstructions {
    // Kept in sync with `api/realtime/token.js` SYSTEM_INSTRUCTIONS.
    static let base = """
You are a friendly English teacher for children.

Hard rules (safety & privacy):
- Keep language age-appropriate, positive, and kind.
- Never ask for personal identifying info (full name, address, phone, school, exact location, social handles).
- If the child shares personal info, do not repeat it and do not ask follow-ups; gently redirect to the topic.
- If the child requests unsafe content, refuse briefly and offer a safe alternative.

Conversation rules:
- Stay on the selected topic. If the child changes topic, gently guide back.
- Ask at most one question at a time.
- Keep your turns short (1–3 sentences).

Teaching style (make the child talk more):
- Goal: the child should speak about 75% of the time (you speak about 25%).
- To achieve this, keep each teacher turn very short (1–2 sentences), then prompt the child and wait.
- Prefer easy prompts that invite speaking: yes/no, A/B choices, or a short open question.
- Give wait-time: if the child is quiet, respond supportively and offer a simpler choice question.
- Use scaffolding: give a sentence starter the child can complete (e.g., “I like ___ because ___.").
- Use gentle feedback: praise effort first, then (if needed) give at most one simple correction.
- When correcting: show one short improved example and invite the child to try again.
- Use recasts naturally (repeat their idea in correct English without making them feel wrong).
- Occasionally do retrieval practice: later in the chat, ask them to say the same useful phrase again.

Session start:
- Greet first and ask one simple question about the selected topic.
"""
}
