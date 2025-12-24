import SwiftUI

struct SessionView: View {
    let topic: Topic

    @Environment(\.dismiss) private var dismiss

    @StateObject private var mic = MicrophoneMonitor()
    @StateObject private var sessionModel: SessionModel

    init(topic: Topic) {
        self.topic = topic
        _sessionModel = StateObject(wrappedValue: SessionModel(client: RealtimeClientFactory.makeClient()))
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Topic: \(topic.title)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Your teacher")
                    .font(.largeTitle.weight(.bold))
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                ListeningSpeakingIndicator(isMuted: mic.isMuted, isTeacherReady: sessionModel.isTeacherReady)

                MicActivityView(level: mic.level, isMuted: mic.isMuted)
                    .frame(width: 72, height: 72)
            }

            transcript

            HStack(spacing: 12) {
                Button {
                    mic.toggleMute()
                } label: {
                    Text(mic.isMuted ? "Unmute" : "Mute")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    endSession()
                } label: {
                    Text("End")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Spacer(minLength: 8)
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            sessionModel.start(topic: topic)
            mic.startIfPossible()
        }
        .onDisappear {
            sessionModel.stop()
            mic.stop()
        }
    }

    private var transcript: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(sessionModel.messages) { msg in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(msg.roleLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(msg.text)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func endSession() {
        // Meets @SE-004 and @DA-001: stop mic capture; do not persist raw audio.
        mic.stop()
        sessionModel.stop()
        dismiss()
    }
}

private struct ListeningSpeakingIndicator: View {
    let isMuted: Bool
    let isTeacherReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isTeacherReady ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(isTeacherReady ? "Teacher ready" : "Connecting")
                    .font(.footnote.weight(.semibold))
            }

            Text(isMuted ? "Mic muted" : "Listening")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MicActivityView: View {
    let level: Float // 0...1
    let isMuted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)

            Circle()
                .strokeBorder(isMuted ? Color.gray : Color.blue, lineWidth: 6)
                .opacity(0.9)

            Circle()
                .fill(isMuted ? Color.gray.opacity(0.25) : Color.blue.opacity(0.25))
                .scaleEffect(0.55 + CGFloat(level) * 0.55)
                .animation(.easeOut(duration: 0.12), value: level)

            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isMuted ? .secondary : .primary)
        }
        .accessibilityLabel(isMuted ? "Microphone muted" : "Microphone active")
    }
}
