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
    When I tap the mute input button again
    Then the screen should return to normal sleep behavior
    Then the app should resume capturing microphone audio
    And the app should indicate that my microphone is unmuted

  @SE-006 @mvp
  Scenario: Use loudspeaker when no headphones are connected
    Given I am in an active speaking session
    And I do not have headphones connected
    Then the session audio output should use the device loudspeaker
    When I connect headphones
    Then the session audio output should route to the headphones

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

  @SE-007 @mvp
  Scenario: Encourage speaking with easy choice questions
    Given I am in an active speaking session
    When I seem unsure or answer with only one word
    Then the teacher should respond supportively
    And the teacher should offer an easy A/B choice question to help me speak more
    And the teacher should ask at most one question at a time

  @SE-008 @mvp
  Scenario: Use sentence starters to scaffold longer answers
    Given I am in an active speaking session
    When the teacher asks me to talk about the topic
    Then the teacher should provide a simple sentence starter I can complete
    And the teacher should keep their turns short
    And the teacher should ask at most one question at a time

  @SE-009
  Scenario: Use light retrieval practice to build memory
    Given I am in an active speaking session
    When I successfully use a useful phrase
    Then later in the conversation the teacher should ask me to say the phrase again

  @SE-004 @mvp
  Scenario: End a session
    Given I am in an active speaking session
    When I end the session
    Then the session should stop listening to my microphone
    And I should return to the home screen

  @SE-010 @mvp
  Scenario: Keep the screen awake during an active session
    When I start the speaking session
    Then the screen should not go to sleep while the session is active
    When I end the session
    Then the screen should return to normal sleep behavior