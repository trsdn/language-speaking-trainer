# iOS WebRTC via SwiftPM

This project uses **Swift Package Manager** (SwiftPM) to add a WebRTC SDK to the Xcode project.

## Goal

Provide a `WebRTC` module so the guarded code path in:

- `ios/LanguageSpeakingTrainer/OpenAIRealtimeWebRTCClient.swift`

can compile and the app can establish a Realtime **WebRTC** connection.

## Requirements

- Xcode installed (full Xcode, not only Command Line Tools)
- A SwiftPM package that exports an importable module named `WebRTC`

You can verify this by checking that the following compiles:

- `#if canImport(WebRTC)`

## Recommended approach (SwiftPM)

In Xcode:

1. Open your app project.
2. Go to **File → Add Package Dependencies…**
3. Add a WebRTC SwiftPM package URL.
4. Add the product that provides the `WebRTC` module to your app target.
5. Build once to confirm the module is available.

## Candidate packages

Because WebRTC packaging changes over time, prefer a package that:

- ships an `XCFramework`
- exports the module name `WebRTC`
- is actively maintained (or pinned to a known-good tag)

Two repositories that have historically shipped WebRTC as a Swift package:

- `https://github.com/klever-io/WebRTC-swift`
- `https://github.com/highfidelity/HiFi-WebRTC-iOS`

If the chosen package exports a different module name, we can adjust the guard in code (e.g. `canImport(SomeOtherModule)`).

## After WebRTC is available

Next implementation steps in code:

1. Fetch an ephemeral client secret from your backend:
   - `GET /api/realtime/token?topic=...`
2. Create a peer connection and offer SDP.
3. POST offer SDP to OpenAI:
   - `POST https://api.openai.com/v1/realtime/calls`
   - `Authorization: Bearer ek_...`
   - `Content-Type: application/sdp`
4. Apply returned answer SDP.
5. Use a data channel (`oai-events`) to receive server events.

## Notes

- Running both a separate mic monitor (`AVAudioEngine` tap) and WebRTC mic capture can conflict on some devices.
  For the real WebRTC path, we should migrate the mic animation to a WebRTC-derived signal (or a lightweight synthetic animation while unmuted).
