import Foundation

/// Realtime client that will connect via WebRTC using an ephemeral client secret.
///
/// This file is designed to keep the app runnable even before the WebRTC SDK is added:
/// - Without a `WebRTC` module present, it will fetch the ephemeral token (optional) and emit a helpful note.
/// - Once a `WebRTC` module is added to the Xcode project, the guarded implementation can be completed.
final class OpenAIRealtimeWebRTCClient: RealtimeSessionClient {
    private var stopped = false

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {
        stopped = false

        Task {
            do {
                // This demonstrates the full flow: server-minted client secret → client uses it for WebRTC.
                let token = try await TokenService.fetchEphemeralToken(topic: topic)
                guard !stopped else { return }

                #if canImport(WebRTC)
                // When the WebRTC SDK is present, this should:
                // 1) create a peer connection and local offer SDP
                // 2) POST the offer SDP to https://api.openai.com/v1/realtime/calls with Authorization: Bearer ek_...
                // 3) set remote description with returned answer SDP
                // 4) listen to data channel events and translate them into RealtimeEvent(s)
                onEvent(.systemNote("WebRTC SDK detected. WebRTC negotiation not wired yet (next step)."))
                onEvent(.connected)
                #else
                // Keep the UI stable even without the WebRTC dependency.
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
    }
}
