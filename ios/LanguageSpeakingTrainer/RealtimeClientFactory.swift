import Foundation

enum RealtimeClientFactory {
    static func makeClient() -> RealtimeSessionClient {
        // If a token service is configured, try the real client.
        if AppConfig.tokenServiceBaseURL != nil {
            return OpenAIRealtimeWebRTCClient()
        }
        return MockRealtimeSessionClient()
    }
}
