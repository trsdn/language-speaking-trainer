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

  @ST-002 @mvp
  Scenario: Save learner context (age, school type, country)
    Given I am on the home screen
    When I open Settings
    And I enter age "9"
    And I select school type "Primary school"
    And I select country "United Kingdom"
    And I enter region/state "England"
    And I close and reopen the app
    Then Settings should still show age "9"
    And Settings should still show school type "Primary school"
    And Settings should still show country "United Kingdom"
    And Settings should still show region/state "England"

  @ST-003
  Scenario: Germany shows Bundesland selector
    Given I am on the home screen
    When I open Settings
    And I select country "Germany"
    Then I should see a Bundesland selector
    When I select Bundesland "Berlin"
    Then Settings should show Bundesland "Berlin"

  @ST-004
  Scenario: Age validation blocks invalid ages
    Given I am on the home screen
    When I open Settings
    And I enter age "3"
    Then I should see an age validation error
    When I enter age "17"
    Then I should see an age validation error
    When I enter age "10"
    Then I should not see an age validation error
