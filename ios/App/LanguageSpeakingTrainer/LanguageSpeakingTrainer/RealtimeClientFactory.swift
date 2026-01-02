import Foundation

enum RealtimeClientFactory {
    static func makeClient(
        providerPreference: RealtimeProviderPreference = .openAI,
        modelPreference: RealtimeModelPreference = .realtimeMini,
        geminiModelPreference: GeminiLiveModelPreference = .gemini25FlashNativeAudioPreview_2025_12,
        learnerContext: LearnerContext
    ) -> RealtimeSessionClient {
        if AppConfig.isUITesting {
            return MockRealtimeSessionClient()
        }
        // Avoid silently falling back to the mock, because it looks like “WebRTC is broken”
        // when it’s really just misconfiguration. If you want the mock, build with:
        //   SWIFT_ACTIVE_COMPILATION_CONDITIONS += USE_MOCK_REALTIME
        #if USE_MOCK_REALTIME
        return MockRealtimeSessionClient()
        #else
        switch providerPreference {
        case .openAI:
            return OpenAIRealtimeWebRTCClient(modelPreference: modelPreference, learnerContext: learnerContext)
        case .geminiLive:
            return GeminiLiveWebSocketClient(modelPreference: geminiModelPreference, learnerContext: learnerContext)
        }
        #endif
    }
}
