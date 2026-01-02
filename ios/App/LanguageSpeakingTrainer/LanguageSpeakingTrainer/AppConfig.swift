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
        // App override (stored locally). This is *not* a secret.
        if let raw = UserDefaults.standard.string(forKey: "token.service.baseURL.override.v1") {
            let v = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty, let url = URL(string: v) {
                return url
            }
        }

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
        // App override (stored securely). Never surface this in UI.
        if let v = KeychainStore.readString(for: .tokenServiceSharedSecret)?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
            return v
        }

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

    /// Standard OpenAI API key used for direct minting (BYOK / dev-only).
    ///
    /// Important: do not ship a production app that relies on a user-entered API key.
    /// This is intended for personal/dev usage.
    static var openAIAPIKey: String? {
        // App override (stored securely). Never surface this in UI.
        if let v = KeychainStore.readString(for: .openAIAPIKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty {
            return v
        }

        // Dev convenience: allow setting via Xcode Scheme env vars.
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            let v = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty {
                return v
            }
        }

        return nil
    }
}

