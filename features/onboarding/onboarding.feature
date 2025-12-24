@onboarding
Feature: First-run onboarding
  As a parent/guardian or child
  I want a simple first-run setup
  So that speaking practice is safe and age-appropriate

  Background:
    Given I have installed the app

  @ON-001 @mvp @smoke
  Scenario: First launch shows onboarding
    Given I have never completed onboarding
    When I open the app
    Then I should see an onboarding flow

  @ON-002 @mvp
  Scenario: Onboarding captures age band and level
    Given I am in onboarding
    When I select a child age band
    And I select an English level
    And I confirm onboarding
    Then onboarding should be marked as completed
    And I should land on the home screen

  @ON-003 @mvp
  Scenario: Returning user skips onboarding
    Given I have completed onboarding
    When I open the app
    Then I should land on the home screen