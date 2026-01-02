import XCTest
@testable import LanguageSpeakingTrainer

final class LanguageSpeakingTrainerTests: XCTestCase {
    override func setUp() {
        super.setUp()

        // Keep tests independent from previous runs.
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "realtime.provider.preference.v1")
        defaults.removeObject(forKey: "realtime.model.preference.v1")
        defaults.removeObject(forKey: "gemini.live.model.preference.v1")
        defaults.removeObject(forKey: "session.showSystemMessages.v1")
        defaults.synchronize()
    }

    func testTopicPresetsAreStable() {
        XCTAssertEqual(
            Topic.presets.map(\.id),
            [
                "classroom-talk",
                "friends",
                "making-plans",
                "sorry-and-solutions",
                "school-day",
                "food-ordering",
                "shopping-clothes",
                "my-town",
                "public-transport",
                "directions",
                "animals-nature",
                "trips-holidays"
            ]
        )
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

    func testRealtimeProviderAndGeminiModelPreferencesPersist() async {
        // Given
        let model1 = await MainActor.run { AppModel() }

        // When
        await MainActor.run {
            model1.realtimeProviderPreference = .geminiLive
            model1.geminiLiveModelPreference = .geminiLive25FlashPreview
        }

        // Then (new instance reads persisted defaults)
        let model2 = await MainActor.run { AppModel() }
        let provider = await MainActor.run { model2.realtimeProviderPreference }
        let geminiModel = await MainActor.run { model2.geminiLiveModelPreference }
        XCTAssertEqual(provider, .geminiLive)
        XCTAssertEqual(geminiModel, .geminiLive25FlashPreview)
    }

    func testShowSystemMessagesPreferencePersists() async {
        // Given
        let model1 = await MainActor.run { AppModel() }

        // When
        await MainActor.run {
            model1.showSystemMessages = false
        }

        // Then
        let model2 = await MainActor.run { AppModel() }
        let value = await MainActor.run { model2.showSystemMessages }
        XCTAssertEqual(value, false)
    }
}
