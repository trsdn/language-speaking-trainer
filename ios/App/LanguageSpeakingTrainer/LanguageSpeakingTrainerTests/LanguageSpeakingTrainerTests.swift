import XCTest
@testable import LanguageSpeakingTrainer

final class LanguageSpeakingTrainerTests: XCTestCase {
    func testTopicPresetsAreStable() {
        XCTAssertEqual(Topic.presets.map(\.id), ["animals", "school", "sports", "food", "space"])
    }
}
