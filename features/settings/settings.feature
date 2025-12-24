@settings
Feature: Settings
  As a parent or developer
  I want to adjust session settings
  So that I can tune quality vs latency/cost

  @ST-001 @mvp
  Scenario: Switch between Realtime Mini and Realtime
    Given I am on the home screen
    When I open Settings
    Then I should see a Realtime model selector
    When I select "Realtime"
    And I close and reopen the app
    Then Settings should still show "Realtime" as selected
    When I start a speaking session
    Then the session should use the selected Realtime model
