import Foundation

// MARK: - Events

enum RealtimeEvent {
    case connected
    case teacherMessage(String)
    case systemNote(String)
}

// MARK: - Protocol

/// Abstraction for the future OpenAI Realtime (WebRTC) client.
///
/// MVP scaffold uses a mock implementation so the UI can be built/tested first.
protocol RealtimeSessionClient {
    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void)
    func stop()
}

// MARK: - Mock

final class MockRealtimeSessionClient: RealtimeSessionClient {
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
}
