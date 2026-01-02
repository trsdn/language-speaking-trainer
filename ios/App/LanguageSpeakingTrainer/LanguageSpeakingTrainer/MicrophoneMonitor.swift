import AVFoundation
import Foundation
import Combine

/// Local-only microphone level monitor.
///
/// - Provides a simple “mic activity” signal (0...1) for UI animation.
/// - Does NOT record or persist audio (supports @DA-001).
@MainActor
final class MicrophoneMonitor: ObservableObject {
    @Published private(set) var level: Float = 0
    @Published private(set) var isMuted: Bool = false
    @Published private(set) var hasPermission: Bool = false

    private let engine = AVAudioEngine()
    private var didInstallTap = false

    func startIfPossible() {
        // UI tests must not trigger permission prompts or audio session work.
        if AppConfig.isUITesting {
            hasPermission = false
            level = 0
            return
        }
        Task {
            let ok = await requestPermissionIfNeeded()
            hasPermission = ok
            guard ok else { return }
            if isMuted { return }
            startEngineIfNeeded()
        }
    }

    func stop() {
        engine.stop()
        level = 0
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stop()
        } else {
            startIfPossible()
        }
    }

    private func requestPermissionIfNeeded() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    AVAudioApplication.requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
    }

    private func startEngineIfNeeded() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let input = engine.inputNode
            let format = input.inputFormat(forBus: 0)

            if !didInstallTap {
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                    guard let self else { return }
                    let rms = Self.rmsLevel(buffer: buffer)
                    Task { @MainActor in
                        // Map to 0...1-ish for UI
                        self.level = min(max(rms * 8, 0), 1)
                    }
                }
                didInstallTap = true
            }

            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            // If the audio session fails, keep UI stable and non-crashy.
            level = 0
        }
    }

    private static func rmsLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channel = channelData[0]
        let frameCount = Int(buffer.frameLength)
        if frameCount == 0 { return 0 }

        var sum: Float = 0
        for i in 0..<frameCount {
            let x = channel[i]
            sum += x * x
        }
        return sqrt(sum / Float(frameCount))
    }
}
