import Foundation

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
    
    /// Shared secret for token service authentication
    static var tokenServiceSharedSecret: String? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "TOKEN_SERVICE_SHARED_SECRET") as? String,
            !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return raw
    }
}
