import Foundation

final class OpenAIRealtimeWebRTCClient: RealtimeSessionClient {
    var capturesMicrophone: Bool {
        #if canImport(WebRTC)
        true
        #else
        false
        #endif
    }

    private var stopped = false
    private var isMuted = false
    private let modelPreference: RealtimeModelPreference

    #if canImport(WebRTC)
    private var session: OpenAIWebRTCSession?
    #endif

    init(modelPreference: RealtimeModelPreference = .realtimeMini) {
        self.modelPreference = modelPreference
    }

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {
        stopped = false

        Task {
            do {
                #if DEBUG
                if let base = AppConfig.tokenServiceBaseURL {
                    onEvent(.systemNote("Token service: \(base.absoluteString)"))
                } else {
                    onEvent(.systemNote("Token service not configured (missing TOKEN_SERVICE_BASE_URL in Info.plist)."))
                }
                #endif

                let token = try await TokenService.fetchEphemeralToken(topic: topic, mode: modelPreference)
                guard !stopped else { return }

                #if canImport(WebRTC)
                let s = OpenAIWebRTCSession(
                    ephemeralKey: token.value,
                    topic: topic,
                    isMuted: isMuted,
                    onEvent: onEvent
                )
                self.session = s
                s.start()
                #else
                onEvent(.systemNote("Token fetched (ephemeral client secret). Add a WebRTC SDK module named 'WebRTC' to enable realtime audio."))
                onEvent(.systemNote("(Ephemeral token expires at: \(token.expires_at ?? 0))"))
                onEvent(.connected)
                onEvent(.teacherMessage("Hi! (Mocked) I’m ready, but WebRTC isn’t enabled yet. Once enabled, I’ll speak first about \(topic.title)."))
                #endif
            } catch {
                guard !stopped else { return }
                onEvent(.systemNote("Failed to start realtime session: \(error.localizedDescription)"))
            }
        }
    }

    func stop() {
        stopped = true

        #if canImport(WebRTC)
        session?.stop()
        session = nil
        #endif
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted

        #if canImport(WebRTC)
        session?.setMuted(muted)
        #endif
    }
}
