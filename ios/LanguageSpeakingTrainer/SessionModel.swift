import Foundation

@MainActor
final class SessionModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isTeacherReady: Bool = false

    private let client: RealtimeSessionClient

    init(client: RealtimeSessionClient) {
        self.client = client
    }

    func start(topic: Topic) {
        messages = []
        isTeacherReady = false

        client.start(topic: topic) { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                self.handle(event)
            }
        }
    }

    func stop() {
        client.stop()
        isTeacherReady = false
    }

    private func handle(_ event: RealtimeEvent) {
        switch event {
        case .connected:
            isTeacherReady = true
        case .teacherMessage(let text):
            messages.append(ChatMessage(role: .teacher, text: text))
        case .systemNote(let text):
            messages.append(ChatMessage(role: .system, text: text))
        }
    }
}

enum ChatRole: String {
    case teacher
    case system
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String

    var roleLabel: String {
        switch role {
        case .teacher: return "Teacher"
        case .system: return "System"
        }
    }
}
