import Foundation

enum AppConfig {
    static var isUITesting: Bool {
        let raw = ProcessInfo.processInfo.environment["UITESTING"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return raw == "1" || raw == "true" || raw == "yes"
    }

    /// When true, the app should reset persistent state on launch (used by XCUITest).
    static var shouldResetStateOnLaunch: Bool {
        let raw = ProcessInfo.processInfo.environment["RESET_STATE"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return raw == "1" || raw == "true" || raw == "yes"
    }

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

        // Dev convenience: allow setting this via Xcode Scheme environment variables
        // without changing the checked-in Xcode project settings.
        if let env = ProcessInfo.processInfo.environment["TOKEN_SERVICE_SHARED_SECRET"] {
            let v = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty {
                return v
            }
        }

        return nil
    }
}
