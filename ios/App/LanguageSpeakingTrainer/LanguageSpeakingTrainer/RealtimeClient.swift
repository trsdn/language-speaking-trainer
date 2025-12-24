import Foundation

// MARK: - Events

enum RealtimeEvent {
    case connected
    case teacherMessage(String)
    case systemNote(String)
}

// MARK: - Protocol

/// Abstraction for the future OpenAI Realtime (WebRTC) client.
protocol RealtimeSessionClient {
    /// True when the realtime client will capture microphone audio itself (e.g. WebRTC).
    /// If true, the UI should not start any other microphone capture (like `MicrophoneMonitor`).
    var capturesMicrophone: Bool { get }

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void)
    func stop()

    /// Best-effort mute control. Implementations should stop sending mic audio when muted.
    func setMuted(_ muted: Bool)
}

// MARK: - Mock

final class MockRealtimeSessionClient: RealtimeSessionClient {
    var capturesMicrophone: Bool { false }

    private var onEvent: ((RealtimeEvent) -> Void)?

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {
        self.onEvent = onEvent

        // Simulate “connected/teacher ready” then greeting (teacher greets first).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onEvent(.connected)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onEvent(.teacherMessage("Hi! I’m your English teacher. Let’s talk about \(topic.title). What do you like about it?"))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onEvent(.systemNote("(Realtime/WebRTC not connected yet — this is a mock.)"))
        }
    }

    func stop() {
        onEvent = nil
    }

    func setMuted(_ muted: Bool) {
        // No-op for mock.
    }
}
