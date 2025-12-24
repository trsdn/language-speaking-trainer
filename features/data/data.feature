@data
Feature: Local-first data and minimal retention
  As a parent/guardian
  I want the app to retain minimal data by default
  So that my child’s privacy is protected

  @DA-001 @mvp
  Scenario: No long-term raw audio storage by default
    Given I have completed a speaking session
    When the session ends
    Then the app should not store raw audio recordings long-term by default

  @DA-002 @post_mvp
  Scenario: Store only minimal session summary
    Given I have completed a speaking session
    When the session ends
    Then the app may store a minimal session summary locally
    And the summary should not include personal identifying information

  @DA-003 @post_mvp
  Scenario: Delete local data
    Given the app has stored local session summaries
    When I choose to delete child profile data
    Then all local session summaries should be deleted
    And the app should return to a fresh state