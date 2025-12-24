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
}
