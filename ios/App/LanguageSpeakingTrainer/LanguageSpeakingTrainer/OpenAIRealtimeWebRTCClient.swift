import Foundation

#if canImport(WebRTC)
import os.log

private let logger = Logger(subsystem: "com.languagespeakingtrainer", category: "realtime")
#endif

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
    private let learnerContext: LearnerContext

    #if canImport(WebRTC)
    private var session: OpenAIWebRTCSession?
    #endif

    init(modelPreference: RealtimeModelPreference = .realtimeMini, learnerContext: LearnerContext) {
        self.modelPreference = modelPreference
        self.learnerContext = learnerContext
    }

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {
        stopped = false

        Task {
            do {
                #if DEBUG && canImport(WebRTC)
                // Log configuration info to OSLog for debugging (not visible in UI)
                if AppConfig.openAIAPIKey != nil {
                    logger.debug("OpenAI BYOK key is configured (will mint client secrets directly)")
                } else {
                    logger.warning("OpenAI BYOK key is not configured (Settings → OpenAI (BYOK))")
                }
                #endif

                let learner = learnerContext.settingsSnippet()
                let token = try await TokenService.fetchEphemeralToken(
                    topic: topic,
                    learner: learner,
                    mode: modelPreference
                )
                guard !stopped else { return }

                #if canImport(WebRTC)
                let s = OpenAIWebRTCSession(
                    ephemeralKey: token.value,
                    topic: topic,
                    learnerContext: learnerContext,
                    isMuted: isMuted,
                    onEvent: onEvent
                )
                self.session = s
                s.start()
                #else
                onEvent(.system("Token fetched (ephemeral client secret). Add a WebRTC SDK module named 'WebRTC' to enable realtime audio."))
                onEvent(.system("(Ephemeral token expires at: \(token.expires_at ?? 0))"))
                onEvent(.connected)
                onEvent(.teacherMessage("Hi! (Mocked) I’m ready, but WebRTC isn’t enabled yet. Once enabled, I’ll speak first about \(topic.title)."))
                #endif
            } catch {
                guard !stopped else { return }
                onEvent(.error("Failed to start realtime session: \(error.localizedDescription)"))
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
