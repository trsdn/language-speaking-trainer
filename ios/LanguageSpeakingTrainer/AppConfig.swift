import Foundation

/// App configuration hooks for the future token service.
///
/// In MVP scaffolding we keep this as a placeholder so the iOS app can compile/run without backend.
enum AppConfig {
    /// Example: https://your-vercel-app.vercel.app
    static var tokenServiceBaseURL: URL? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "TOKEN_SERVICE_BASE_URL") as? String,
            !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return URL(string: raw)
    }

    /// Shared secret sent to the token service to protect /api/realtime/token.
    /// NOTE: This is only MVP protection for a single-user / non-public deployment.
    static var tokenServiceSharedSecret: String? {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "TOKEN_SERVICE_SHARED_SECRET") as? String {
            let v = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty {
                return v
            }
        }

        if let env = ProcessInfo.processInfo.environment["TOKEN_SERVICE_SHARED_SECRET"] {
            let v = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty {
                return v
            }
        }

        return nil
    }
}
