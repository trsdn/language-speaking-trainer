import XCTest
@testable import LanguageSpeakingTrainer

final class LanguageSpeakingTrainerTests: XCTestCase {
    func testTopicPresetsAreStable() {
        XCTAssertEqual(Topic.presets.map(\.id), ["animals", "school", "sports", "food", "space"])
    }

    func testSessionModelDisablesIdleTimerWhileSessionInProgress() async {
        @MainActor
        final class TestIdleTimerController: IdleTimerControlling {
            var isIdleTimerDisabled: Bool = false
        }

        final class TestRealtimeClient: RealtimeSessionClient {
            var capturesMicrophone: Bool { false }
            func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {}
            func stop() {}
            func setMuted(_ muted: Bool) {}
        }

        let idleTimer = await TestIdleTimerController()
        let model = await SessionModel(client: TestRealtimeClient(), idleTimer: idleTimer)

        await model.start(topic: Topic.presets[0])
        let inProgressAfterStart = await MainActor.run { model.isSessionInProgress }
        let idleDisabledAfterStart = await MainActor.run { idleTimer.isIdleTimerDisabled }
        XCTAssertTrue(idleDisabledAfterStart)
        XCTAssertTrue(inProgressAfterStart)

        await model.stop()
        let inProgressAfterStop = await MainActor.run { model.isSessionInProgress }
        let idleDisabledAfterStop = await MainActor.run { idleTimer.isIdleTimerDisabled }
        XCTAssertFalse(idleDisabledAfterStop)
        XCTAssertFalse(inProgressAfterStop)
    }
}
