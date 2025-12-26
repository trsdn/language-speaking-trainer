@home
Feature: Home and topic selection
  As a child learner
  I want to start practice and choose a topic
  So that speaking sessions are easy to begin and focused

  @HO-001 @mvp @smoke
  Scenario: View start action on home screen
    Given I have installed the app
    And I am a single user on this device
    When I open the app
    Then I should see a Start action to begin practice
    And I should see a way to choose a topic

  @HO-002 @mvp
  Scenario: Select a specific topic
    Given I am on the home screen
    When I choose a topic
    Then the chosen topic should be confirmed
    And I should be able to start a speaking session for that topic

  @HO-003 @mvp
  Scenario: Start with a surprise topic
    Given I am on the home screen
    When I choose Surprise topic
    Then a topic should be selected for me
    And I should be able to start a speaking session

  @HO-004 @mvp
  Scenario: Specify a custom topic
    Given I am on the home screen
    When I specify a topic as "Space"
    Then the chosen topic should be confirmed as "Space"
    And I should be able to start a speaking session for that topic

  @HO-005 @mvp
  Scenario: Prevent specifying an empty topic
    Given I am on the home screen
    When I specify a topic as ""
    Then I should see a validation message
    And I should remain on the home screen

  @HO-006 @mvp
  Scenario: Topics are visible without horizontal scrolling
    Given I am on the home screen
    Then I should be able to see all preset topics at a glance without horizontal scrolling
    And the selected topic state should be clear and consistent
    And Surprise and Custom topic should still be available
    And the layout should work with larger text sizes without clipping