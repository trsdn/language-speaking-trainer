import XCTest

final class LanguageSpeakingTrainerUITests: XCTestCase {
    func testHappyPath_onboarding_chooseTopic_start_end() {
        // Scenario mapping (for spec coverage):
        // @ON-001 @HO-001 @SE-001

        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["RESET_STATE"] = "1"
        app.launch()

        // Onboarding: select required values (age band + English level) and wait for Continue
        // to become enabled before tapping.
        let ageBand = app.segmentedControls["onboarding.ageBand"]
        let englishLevel = app.segmentedControls["onboarding.englishLevel"]
        XCTAssertTrue(ageBand.waitForExistence(timeout: 5))
        XCTAssertTrue(englishLevel.waitForExistence(timeout: 5))

        // Even though the UI preselects defaults onAppear, CI can be fast enough that
        // we tap Continue before state is set. Explicitly tapping an option makes the
        // flow deterministic.
        if ageBand.buttons.count > 0 {
            ageBand.buttons.element(boundBy: 0).tap()
        }
        if englishLevel.buttons.count > 0 {
            englishLevel.buttons.element(boundBy: 0).tap()
        }

        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        let continueReady = NSPredicate(format: "exists == true && enabled == true && hittable == true")
        expectation(for: continueReady, evaluatedWith: continueButton)
        waitForExpectations(timeout: 5)
        continueButton.tap()

        XCTAssertTrue(app.buttons["home.topic.animals"].waitForExistence(timeout: 5))
        app.buttons["home.topic.animals"].tap()

        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
        app.buttons["home.start"].tap()

        XCTAssertTrue(app.staticTexts["session.topic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.end"].waitForExistence(timeout: 5))
        app.buttons["session.end"].tap()

        // Back on Home
        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
    }
}
