import Foundation
import Combine

@MainActor
final class SessionModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isTeacherReady: Bool = false

    /// Latest user-visible error message (shown via alert).
    @Published var latestErrorMessage: String? = nil

    /// True while the session screen considers a session “in progress” (connecting or active).
    /// Used for UI logic such as keeping the screen awake.
    @Published private(set) var isSessionInProgress: Bool = false

    private let client: RealtimeSessionClient
    private var idleTimer: any IdleTimerControlling
    private let showSystemMessages: Bool

    var capturesMicrophone: Bool { client.capturesMicrophone }

    init(
        client: RealtimeSessionClient,
        showSystemMessages: Bool = true,
        idleTimer: (any IdleTimerControlling)? = nil
    ) {
        self.client = client
        self.showSystemMessages = showSystemMessages
        self.idleTimer = idleTimer ?? SystemIdleTimerController()
    }

    init(
        client: RealtimeSessionClient,
        showSystemMessages: Bool = true,
        idleTimer: any IdleTimerControlling
    ) {
        self.client = client
        self.showSystemMessages = showSystemMessages
        self.idleTimer = idleTimer
    }

    func start(topic: Topic) {
        messages = []
        isTeacherReady = false
        latestErrorMessage = nil
        isSessionInProgress = true

        // Keep the screen awake for the duration of an active/connecting session.
        idleTimer.isIdleTimerDisabled = true

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
        latestErrorMessage = nil
        isSessionInProgress = false

        // Always restore default behavior when leaving/stopping a session.
        idleTimer.isIdleTimerDisabled = false
    }

    func setMuted(_ muted: Bool) {
        client.setMuted(muted)
    }

    private func handle(_ event: RealtimeEvent) {
        switch event {
        case .connected:
            isTeacherReady = true
        case .teacherMessage(let text):
            messages.append(ChatMessage(role: .teacher, text: text))
        case .systemNote(let text, let kind):
            // Always surface errors. Informational notes are controlled by the user.
            guard showSystemMessages || kind == .error else { return }
            messages.append(ChatMessage(role: .system, text: text))
            if kind == .error {
                latestErrorMessage = text
            }
        }
    }

    func clearLatestError() {
        latestErrorMessage = nil
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
