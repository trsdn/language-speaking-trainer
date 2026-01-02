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

