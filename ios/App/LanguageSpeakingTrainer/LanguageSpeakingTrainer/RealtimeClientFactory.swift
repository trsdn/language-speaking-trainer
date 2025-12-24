import Foundation

enum RealtimeClientFactory {
    static func makeClient(
        modelPreference: RealtimeModelPreference = .realtimeMini,
        learnerContext: LearnerContext
    ) -> RealtimeSessionClient {
        // Avoid silently falling back to the mock, because it looks like “WebRTC is broken”
        // when it’s really just misconfiguration. If you want the mock, build with:
        //   SWIFT_ACTIVE_COMPILATION_CONDITIONS += USE_MOCK_REALTIME
        #if USE_MOCK_REALTIME
        return MockRealtimeSessionClient()
        #else
        return OpenAIRealtimeWebRTCClient(modelPreference: modelPreference, learnerContext: learnerContext)
        #endif
    }
}
