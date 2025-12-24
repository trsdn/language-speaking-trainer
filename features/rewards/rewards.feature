@rewards
Feature: Rewards and motivation
  As a child learner
  I want simple rewards
  So that I feel motivated to practice again

  @RW-001 @nice_to_have
  Scenario: Earn stars for completing a session
    Given I am in an active speaking session
    When I end the session
    Then I should see that I earned stars for completing it

  @RW-002 @nice_to_have
  Scenario: Earn a badge for a streak
    Given I have completed practice sessions on multiple days
    When I complete another session today
    Then I may earn a streak badge