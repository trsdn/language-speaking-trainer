# Testing Guide

## Overview

This guide explains how to run tests and check specification coverage for the Language Speaking Trainer iOS app.

## Spec Coverage Report

The spec coverage script compares BDD feature specifications with implementation status:

```bash
python3 scripts/spec-coverage.py
```

This produces a report showing:

- All scenarios found in `.feature` files
- Implementation status from `FEATURE_REGISTRY.md`
- Coverage percentage
- Recommendations for next steps

### Running in CI

The spec coverage report runs automatically in GitHub Actions on every push and pull request.

## iOS Tests (Unit + UI)

### Prerequisites

- macOS with Xcode installed
- iOS 17+ simulator

### Structure

Tests should be organized as:

- **Unit tests**: Test individual components and models
- **UI tests**: Test user flows matching BDD scenarios

### Recommended Test Coverage

Based on `features/FEATURE_REGISTRY.md`, prioritize tests for:

1. **Onboarding flow** (`@ON-001` to `@ON-003`)
   - Complete onboarding
   - Skip onboarding on subsequent launches
   - Persist user selections

2. **Home/topic selection** (`@HO-001` to `@HO-006`)
   - Select preset topic
   - Select surprise topic
   - Enter custom topic
   - Validate empty topic

3. **Session UI** (`@SE-001`, `@SE-004`, `@SE-005`)
   - Start session
   - Show listening/speaking indicators
   - Mute/unmute microphone
   - End session and return to home

### Accessibility Identifiers

For reliable UI tests, add accessibility identifiers to SwiftUI views:

```swift
Button("Start Session") {
    // action
}
.accessibilityIdentifier("startSessionButton")
```

### Running Tests Locally

```bash
cd ios/App/LanguageSpeakingTrainer

# Build for testing
xcodebuild build-for-testing \
  -project LanguageSpeakingTrainer.xcodeproj \
  -scheme LanguageSpeakingTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run tests
xcodebuild test \
  -project LanguageSpeakingTrainer.xcodeproj \
  -scheme LanguageSpeakingTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### UI test stability (CI + local)

UI tests launch the app with a deterministic “UI testing mode” so they:

- do not trigger microphone permission prompts
- use the mock realtime client (no network/token dependency)
- reset persisted state on launch so onboarding always appears

This is controlled via environment variables set by the UI test runner:

- `UITESTING=1`
- `RESET_STATE=1`

### CI/CD

Tests run automatically via GitHub Actions (`.github/workflows/ios-ci.yml`) on:

- Push to `main` branch
- Pull requests to `main`

The workflow:

1. Builds the iOS app for testing
2. Runs unit tests (fails the job on failure)
3. Runs UI tests (fails the job on failure)
4. Runs spec coverage report
5. Uploads `.xcresult` bundles as artifacts (even when tests fail)

## Next Steps

1. Expand UI tests to cover more scenario IDs
2. Add more accessibility identifiers as new screens are tested
3. Tighten spec coverage thresholds over time

See issue #16 for detailed implementation tracking.
