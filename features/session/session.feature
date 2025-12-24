@session
Feature: Realtime speaking session
  As a child learner
  I want to speak with a virtual English teacher in real time
  So that I can practice conversation and pronunciation

  Background:
    Given I am on the home screen
    And I have selected a topic

  @SE-001 @mvp @smoke
  Scenario: Start a session and see turn-taking indicators
    When I start the speaking session
    Then the app should show that the teacher is ready
    And the app should show a clear listening/speaking indicator
    And the session should use an open-mic WebRTC connection
    And I should see an animation that indicates microphone input activity
    And I should see a mute input button

  @SE-005 @mvp
  Scenario: Mute and unmute microphone input
    Given I am in an active speaking session
    When I tap the mute input button
    Then the app should stop capturing microphone audio
    And the app should indicate that my microphone is muted
    When I tap the mute input button again
    Then the app should resume capturing microphone audio
    And the app should indicate that my microphone is unmuted

  @SE-002 @mvp
  Scenario: Child speaks and teacher responds
    Given I am in an active speaking session
    When I speak a short sentence in English
    Then the teacher should respond with an age-appropriate reply
    And the teacher should ask at most one question at a time

  @SE-003 @mvp
  Scenario: Provide gentle correction without overwhelming
    Given I am in an active speaking session
    When I make a small grammar or pronunciation mistake
    Then the teacher should encourage me first
    And the teacher should provide at most one simple correction at a time
    And the teacher should prompt me to try again with an example

  @SE-004 @mvp
  Scenario: End a session
    Given I am in an active speaking session
    When I end the session
    Then the session should stop listening to my microphone
    And I should return to the home screen