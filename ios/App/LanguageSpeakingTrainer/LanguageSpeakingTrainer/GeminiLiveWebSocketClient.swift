import AVFoundation
import Foundation

/// Gemini Live API client using the WebSockets-based Live protocol.
///
/// Protocol docs (WebSockets reference):
/// - https://ai.google.dev/api/live
///
/// Notes:
/// - This is a stateful WebSocket session.
/// - Audio input must be 16-bit PCM (little-endian). The API can resample if the rate is declared.
/// - Audio output is 24kHz 16-bit PCM.
final class GeminiLiveWebSocketClient: RealtimeSessionClient {
    var capturesMicrophone: Bool { true }

    private let modelPreference: GeminiLiveModelPreference
    private let learnerContext: LearnerContext

    private var onEvent: ((RealtimeEvent) -> Void)?
    private var webSocketTask: URLSessionWebSocketTask?

    private var topic: Topic?

    private var inputEngine: AVAudioEngine?
    private var didInstallInputTap = false
    private var inputConverter: AVAudioConverter?
    private var inputTargetFormat: AVAudioFormat?
    private let inputTargetSampleRate: Double = 16_000

    private let inputQueue = DispatchQueue(label: "com.languagespeakingtrainer.gemini.input")
    private var inputPCMQueue: [Data] = []
    private var inputQueuedFrames: Int = 0
    private var isSendingInput: Bool = false
    private let maxQueuedInputSeconds: Double = 0.25

    private var routeChangeObserver: NSObjectProtocol?

    private var outputEngine: AVAudioEngine?
    private var outputPlayer: AVAudioPlayerNode?
    private var outputFormat: AVAudioFormat?

    private let outputQueue = DispatchQueue(label: "com.languagespeakingtrainer.gemini.output")
    private var outputPCMQueue: [Data] = []
    private var outputQueuedFrames: Int = 0
    private var outputScheduledBuffers: Int = 0
    private let maxScheduledBuffers: Int = 6
    private let maxQueuedOutputSeconds: Double = 0.25

    private var stopped = false
    private var muted = false
    private var isSetupComplete = false

    // The Live API can stream partial transcriptions. If we emit a new chat message for every
    // partial update, the transcript becomes noisy (and can sound choppy when VoiceOver reads
    // each update). We buffer and only emit when the server marks the turn complete.
    private var pendingInputTranscript: String = ""
    private var pendingOutputTranscript: String = ""
    private var pendingModelText: String = ""

    init(modelPreference: GeminiLiveModelPreference, learnerContext: LearnerContext) {
        self.modelPreference = modelPreference
        self.learnerContext = learnerContext
    }

    func start(topic: Topic, onEvent: @escaping (RealtimeEvent) -> Void) {
        self.onEvent = onEvent
        self.topic = topic
        stopped = false
        isSetupComplete = false

        guard let apiKey = AppConfig.googleAPIKey else {
            onEvent(.error("Missing Google API key. Set it in Settings (Google/Gemini Live BYOK), or configure GOOGLE_API_KEY as an Xcode Scheme environment variable."))
            return
        }

        onEvent(.system("Starting Gemini Live session…"))

        Task {
            let ok = await requestMicrophonePermissionIfNeeded()
            guard !stopped else { return }
            guard ok else {
                onEvent(.error("Microphone permission denied. Enable microphone access in iOS Settings to use Gemini Live audio."))
                return
            }

            do {
                try configureCallAudioSession()
            } catch {
                onEvent(.error("Failed to configure audio session: \(error.localizedDescription)"))
            }

            connect(apiKey: apiKey)
        }
    }

    func stop() {
        stopped = true

        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            routeChangeObserver = nil
        }

        // Best-effort: tell the server we ended mic input.
        sendAudioStreamEndIfPossible()

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        inputEngine?.stop()
        inputEngine = nil
        didInstallInputTap = false
        inputConverter = nil
        inputTargetFormat = nil

        inputQueue.sync {
            inputPCMQueue.removeAll()
            inputQueuedFrames = 0
            isSendingInput = false
        }

        outputPlayer?.stop()
        outputEngine?.stop()
        outputPlayer = nil
        outputEngine = nil
        outputFormat = nil

        outputQueue.sync {
            outputPCMQueue.removeAll()
            outputQueuedFrames = 0
            outputScheduledBuffers = 0
        }

        onEvent = nil
        topic = nil
    }

    func setMuted(_ muted: Bool) {
        self.muted = muted

        if muted {
            inputEngine?.pause()
            // Hint to the server that we're done speaking (end of current audio stream/turn).
            sendAudioStreamEndIfPossible()
        } else {
            // Resume mic capture if we're connected.
            if isSetupComplete {
                startMicCaptureIfNeeded()
            }
        }
    }

    private func connect(apiKey: String) {
        guard let url = URL(string: "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent") else {
            onEvent?(.error("Invalid Gemini Live WebSocket URL."))
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let task = URLSession.shared.webSocketTask(with: request)
        webSocketTask = task
        task.resume()

        sendSetup()
        receiveLoop()
    }

    private func sendSetup() {
        let topicTitle = topic?.title ?? ""
        let learner = learnerContext.settingsSnippet()

        // Keep a similar behavior to the OpenAI flow: teacher greets first and uses the selected topic.
        let systemText = GeminiLiveInstructions.system(topicTitle: topicTitle, learnerSnippet: learner)

        let setup = Setup(
            model: modelPreference.resourceName,
            generationConfig: .init(
                // One response modality per session. We want audio (and we can also enable transcription).
                responseModalities: ["AUDIO"]
            ),
            systemInstruction: .init(role: "system", parts: [.init(text: systemText)]),
            realtimeInputConfig: .init(
                automaticActivityDetection: .init(disabled: false)
            ),
            inputAudioTranscription: .init(),
            outputAudioTranscription: .init(),
            sessionResumption: .init(handle: nil)
        )

        send(ClientMessage(setup: setup))
    }

    private func sendInitialGreetingTurnIfPossible() {
        guard let t = topic else { return }

        let greeting = "Greet the learner warmly and start the conversation about: \(t.title). Ask one short question and wait." 

        let userTurn = Content(role: "user", parts: [.init(text: greeting)])
        let clientContent = ClientContent(turns: [userTurn], turnComplete: true)
        send(ClientMessage(clientContent: clientContent))
    }

    private func receiveLoop() {
        guard let task = webSocketTask else { return }

        task.receive { [weak self] result in
            guard let self else { return }
            if self.stopped { return }

            switch result {
            case .failure(let error):
                self.onEvent?(.error("Gemini Live socket error: \(error.localizedDescription)"))
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleServerMessage(text)
                case .data(let data):
                    // The Live API docs describe JSON messages, but some WebSocket stacks may deliver
                    // frames as binary. Attempt UTF-8 decoding first.
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleServerMessage(text)
                    } else {
                        let prefix = Self.hexPrefix(data, maxBytes: 16)
                        self.onEvent?(.system("Gemini Live received non-UTF8 binary frame (\(data.count) bytes, hex prefix: \(prefix))."))
                    }
                @unknown default:
                    self.onEvent?(.system("Gemini Live received an unknown message type."))
                }

                // Continue listening.
                self.receiveLoop()
            }
        }
    }

    private static func hexPrefix(_ data: Data, maxBytes: Int) -> String {
        let n = min(maxBytes, data.count)
        if n == 0 { return "" }
        return data.prefix(n).map { String(format: "%02x", $0) }.joined(separator: " ")
    }

    private func handleServerMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        guard let msg = try? JSONDecoder().decode(ServerMessage.self, from: data) else {
            // Keep UI stable; avoid spamming full payloads.
            onEvent?(.error("Gemini Live: received unparseable server message."))
            return
        }

        if msg.setupComplete != nil {
            isSetupComplete = true
            onEvent?(.connected)
            onEvent?(.system("Gemini Live setup complete."))

            // Kick off a first assistant turn so the UX feels alive.
            sendInitialGreetingTurnIfPossible()

            // Start open-mic capture (unless muted).
            if !muted {
                startMicCaptureIfNeeded()
            }
            return
        }

        if let goAway = msg.goAway {
            onEvent?(.system("Gemini Live: server will disconnect soon (timeLeft: \(goAway.timeLeft ?? "unknown"))."))
            return
        }

        if let serverContent = msg.serverContent {
            if serverContent.interrupted == true {
                // Best-effort: stop playback and clear queued audio.
                outputQueue.async { [weak self] in
                    guard let self else { return }
                    self.outputPCMQueue.removeAll()
                    self.outputQueuedFrames = 0
                    self.outputScheduledBuffers = 0
                }

                outputPlayer?.stop()
                outputPlayer?.play()
            }

            if let inputTx = serverContent.inputTranscription?.text {
                let trimmed = inputTx.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    pendingInputTranscript = trimmed
                }
            }

            if let outputTx = serverContent.outputTranscription?.text {
                let trimmed = outputTx.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    pendingOutputTranscript = trimmed
                }
            }

            if let modelTurn = serverContent.modelTurn {
                for part in modelTurn.parts {
                    if let text = part.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Avoid emitting lots of tiny messages; coalesce into a single turn.
                        // We'll only emit this if we don't get an output transcription.
                        pendingModelText += text
                    }
                    if let inline = part.inlineData, inline.mimeType.lowercased().hasPrefix("audio/pcm") {
                        playPCM16LE_24kHz(inline.data)
                    }
                }
            }

            let isTurnComplete = (serverContent.turnComplete == true) || (serverContent.generationComplete == true)
            if isTurnComplete {
                // Emit a single user transcript (optional).
                if !pendingInputTranscript.isEmpty {
                    onEvent?(.system("You: \(pendingInputTranscript)"))
                }

                // Prefer output transcription (it matches the audio); fall back to model text.
                if !pendingOutputTranscript.isEmpty {
                    onEvent?(.teacherMessage(pendingOutputTranscript))
                } else if !pendingModelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onEvent?(.teacherMessage(pendingModelText.trimmingCharacters(in: .whitespacesAndNewlines)))
                }

                pendingInputTranscript = ""
                pendingOutputTranscript = ""
                pendingModelText = ""
            }
        }
    }

    private func send(_ message: ClientMessage) {
        send(message, completion: nil)
    }

    private func send(_ message: ClientMessage, completion: (() -> Void)?) {
        guard let task = webSocketTask else { return }
        guard !stopped else { return }

        do {
            let data = try JSONEncoder().encode(message)
            guard let text = String(data: data, encoding: .utf8) else { return }
            task.send(.string(text)) { [weak self] error in
                if let error {
                    self?.onEvent?(.error("Gemini Live send failed: \(error.localizedDescription)"))
                }
                completion?()
            }
        } catch {
            onEvent?(.error("Gemini Live encoding failed: \(error.localizedDescription)"))
            completion?()
        }
    }

    private func sendAudioStreamEndIfPossible() {
        guard isSetupComplete else { return }
        guard webSocketTask != nil else { return }
        // This is a best-effort hint for turn detection; safe to ignore failures.
        send(ClientMessage(realtimeInput: RealtimeInput(audioStreamEnd: true)))
    }

    private func startMicCaptureIfNeeded() {
        guard !muted else { return }
        guard webSocketTask != nil else { return }

        if inputEngine == nil {
            inputEngine = AVAudioEngine()
            didInstallInputTap = false
        }
        guard let engine = inputEngine else { return }

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        // Enable iOS voice processing (echo cancellation, noise suppression, AGC) when available.
        // This is the closest equivalent to the "free" audio processing you get with WebRTC.
        if #available(iOS 13.0, *) {
            do {
                if !input.isVoiceProcessingEnabled {
                    try input.setVoiceProcessingEnabled(true)
                }
            } catch {
                // Non-fatal; continue without voice processing.
            }
        }

        // Resample locally to a stable rate to reduce server-side resampling and keep chunking predictable.
        let mimeType = "audio/pcm;rate=\(Int(inputTargetSampleRate))"

        if inputTargetFormat == nil || inputConverter == nil {
            // Target: PCM16LE mono @ 16kHz. Non-interleaved makes it easier to access channel data.
            if let target = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: inputTargetSampleRate, channels: 1, interleaved: false) {
                inputTargetFormat = target
                inputConverter = AVAudioConverter(from: format, to: target)
            }
        }

        // Aim for ~20ms tap buffers to reduce overhead and latency.
        let tapBufferSize: AVAudioFrameCount = {
            let frames = max(256, Int(format.sampleRate / 50.0))
            return AVAudioFrameCount(frames)
        }()

        if !didInstallInputTap {
            input.installTap(onBus: 0, bufferSize: tapBufferSize, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                if self.stopped { return }
                if self.muted { return }
                guard self.isSetupComplete else { return }

                guard let pcm16 = self.convertToPCM16LE_16kHz(buffer) else { return }
                self.enqueueRealtimeAudioChunk(pcm16, mimeType: mimeType)
            }
            didInstallInputTap = true
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                onEvent?(.error("Failed to start microphone capture: \(error.localizedDescription)"))
            }
        }
    }

    private func sendRealtimeAudioChunk(_ data: Data, mimeType: String) {
        let blob = Blob(mimeType: mimeType, data: data)
        let realtime = RealtimeInput(audio: blob)
        send(ClientMessage(realtimeInput: realtime))
    }

    private func enqueueRealtimeAudioChunk(_ data: Data, mimeType: String) {
        // Serialize sends and apply backpressure: keep at most ~250ms of unsent mic audio.
        inputQueue.async { [weak self] in
            guard let self else { return }
            if self.stopped { return }

            self.inputPCMQueue.append(data)
            self.inputQueuedFrames += (data.count / 2)
            self.trimInputQueueIfNeeded()
            self.drainInputQueueIfNeeded(mimeType: mimeType)
        }
    }

    private func drainInputQueueIfNeeded(mimeType: String) {
        guard !isSendingInput else { return }
        guard !inputPCMQueue.isEmpty else { return }
        guard webSocketTask != nil, isSetupComplete, !muted, !stopped else {
            // If we can't send right now, keep queue trimmed but don't spin.
            trimInputQueueIfNeeded()
            return
        }

        isSendingInput = true

        let data = inputPCMQueue.removeFirst()
        let frameCount = data.count / 2
        inputQueuedFrames = max(0, inputQueuedFrames - frameCount)

        let blob = Blob(mimeType: mimeType, data: data)
        let realtime = RealtimeInput(audio: blob)
        send(ClientMessage(realtimeInput: realtime)) { [weak self] in
            guard let self else { return }
            self.inputQueue.async {
                self.isSendingInput = false
                self.drainInputQueueIfNeeded(mimeType: mimeType)
            }
        }
    }

    private func trimInputQueueIfNeeded() {
        let maxFrames = Int(inputTargetSampleRate * maxQueuedInputSeconds)
        guard inputQueuedFrames > maxFrames else { return }

        while inputQueuedFrames > maxFrames, !inputPCMQueue.isEmpty {
            let dropped = inputPCMQueue.removeFirst()
            inputQueuedFrames = max(0, inputQueuedFrames - (dropped.count / 2))
        }
    }

    private func ensureOutputAudioPipeline() {
        if outputEngine != nil, outputPlayer != nil, outputFormat != nil {
            return
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        // Output is documented as 24kHz 16-bit PCM, mono.
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: false)
        guard let format else {
            onEvent?(.error("Failed to create output audio format."))
            return
        }

        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
        } catch {
            onEvent?(.error("Failed to start output audio engine: \(error.localizedDescription)"))
            return
        }

        outputEngine = engine
        outputPlayer = player
        outputFormat = format
    }

    private func playPCM16LE_24kHz(_ pcmData: Data) {
        guard !pcmData.isEmpty else { return }

        // URLSession WebSocket delivery can be bursty. Queue and schedule a small amount ahead to
        // smooth playback and prevent runaway latency when buffers arrive faster than they can play.
        outputQueue.async { [weak self] in
            guard let self else { return }
            if self.stopped { return }

            self.outputPCMQueue.append(pcmData)
            self.outputQueuedFrames += (pcmData.count / 2)

            self.trimOutputQueueIfNeeded()
            self.drainOutputQueueIfNeeded()
        }
    }

    private func drainOutputQueueIfNeeded() {
        ensureOutputAudioPipeline()
        guard let player = outputPlayer, let format = outputFormat else { return }
        guard player.isPlaying else { return }

        while outputScheduledBuffers < maxScheduledBuffers, !outputPCMQueue.isEmpty {
            let data = outputPCMQueue.removeFirst()
            let frameCount = data.count / 2
            if frameCount <= 0 { continue }
            outputQueuedFrames -= frameCount

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { continue }
            buffer.frameLength = AVAudioFrameCount(frameCount)

            data.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                if let dst = buffer.int16ChannelData {
                    dst[0].update(from: base.assumingMemoryBound(to: Int16.self), count: frameCount)
                }
            }

            outputScheduledBuffers += 1
            player.scheduleBuffer(buffer, completionHandler: { [weak self] in
                guard let self else { return }
                self.outputQueue.async {
                    self.outputScheduledBuffers = max(0, self.outputScheduledBuffers - 1)
                    self.drainOutputQueueIfNeeded()
                }
            })
        }
    }

    private func trimOutputQueueIfNeeded() {
        // Cap the queued-but-not-yet-scheduled audio to avoid accumulating seconds of latency.
        // If we're over the cap, drop the oldest audio so we "catch up".
        let maxFrames = Int(24_000.0 * maxQueuedOutputSeconds)
        guard outputQueuedFrames > maxFrames else { return }

        while outputQueuedFrames > maxFrames, !outputPCMQueue.isEmpty {
            let dropped = outputPCMQueue.removeFirst()
            outputQueuedFrames -= (dropped.count / 2)
        }
    }

    private func configureCallAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setMode(.voiceChat)

        // Aim for low-latency I/O (best-effort; the system may not honor exactly).
        try? session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)

        applyPreferredOutputRoute()

        if routeChangeObserver == nil {
            routeChangeObserver = NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: .main
            ) { [weak self] _ in
                self?.applyPreferredOutputRoute()
            }
        }
    }

    private func applyPreferredOutputRoute() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs

        // If any external output is connected, do not override the route.
        if outputs.contains(where: { $0.portType.isExternalOutput }) {
            do {
                try session.overrideOutputAudioPort(.none)
            } catch {
                // Ignore: override isn't always supported for all routes.
            }
            return
        }

        // If we're currently using the built-in receiver, force speaker.
        if outputs.contains(where: { $0.portType == .builtInReceiver }) {
            do {
                try session.overrideOutputAudioPort(.speaker)
            } catch {
                // Ignore: override isn't always supported.
            }
        }
    }

    private func requestMicrophonePermissionIfNeeded() async -> Bool {
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

    private func convertToPCM16LE_16kHz(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let converter = inputConverter, let targetFormat = inputTargetFormat else {
            // Fallback: best-effort for float PCM (no resample).
            return Self.convertFloatBufferToPCM16LE(buffer)
        }

        // Estimate output frames for sample-rate conversion.
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let estimatedFrames = max(1, Int(Double(buffer.frameLength) * ratio) + 1)
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(estimatedFrames)) else {
            return nil
        }

        var error: NSError?
        let status = converter.convert(to: outBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error {
            return nil
        }

        let frames = Int(outBuffer.frameLength)
        if frames == 0 { return nil }

        // Non-interleaved Int16 mono.
        guard let ch = outBuffer.int16ChannelData?[0] else { return nil }
        return Data(bytes: ch, count: frames * MemoryLayout<Int16>.size)
    }

    private static func convertFloatBufferToPCM16LE(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let channel = channelData[0]
        let frameCount = Int(buffer.frameLength)
        if frameCount == 0 { return nil }

        var out = Data(count: frameCount * MemoryLayout<Int16>.size)
        out.withUnsafeMutableBytes { raw in
            guard let dst = raw.baseAddress?.assumingMemoryBound(to: Int16.self) else { return }
            for i in 0..<frameCount {
                let x = max(-1.0 as Float, min(1.0 as Float, channel[i]))
                dst[i] = Int16(x * Float(Int16.max))
            }
        }
        return out
    }
}

// MARK: - Live API message models (minimal)

private struct ClientMessage: Encodable {
    let setup: Setup?
    let clientContent: ClientContent?
    let realtimeInput: RealtimeInput?

    init(setup: Setup) {
        self.setup = setup
        clientContent = nil
        realtimeInput = nil
    }

    init(clientContent: ClientContent) {
        setup = nil
        self.clientContent = clientContent
        realtimeInput = nil
    }

    init(realtimeInput: RealtimeInput) {
        setup = nil
        clientContent = nil
        self.realtimeInput = realtimeInput
    }
}

private struct Setup: Encodable {
    struct GenerationConfig: Encodable {
        let responseModalities: [String]?
    }

    struct RealtimeInputConfig: Encodable {
        struct AutomaticActivityDetection: Encodable {
            let disabled: Bool?
        }

        let automaticActivityDetection: AutomaticActivityDetection?
    }

    struct AudioTranscriptionConfig: Encodable { }

    struct SessionResumptionConfig: Encodable {
        let handle: String?
    }

    let model: String
    let generationConfig: GenerationConfig?
    let systemInstruction: Content?
    let realtimeInputConfig: RealtimeInputConfig?
    let inputAudioTranscription: AudioTranscriptionConfig?
    let outputAudioTranscription: AudioTranscriptionConfig?
    let sessionResumption: SessionResumptionConfig?
}

private struct ClientContent: Encodable {
    let turns: [Content]?
    let turnComplete: Bool?
}

private struct RealtimeInput: Encodable {
    let audio: Blob?
    let audioStreamEnd: Bool?
    let text: String? = nil

    init(audio: Blob) {
        self.audio = audio
        audioStreamEnd = nil
    }

    init(audioStreamEnd: Bool) {
        audio = nil
        self.audioStreamEnd = audioStreamEnd
    }
}

private extension AVAudioSession.Port {
    var isExternalOutput: Bool {
        switch self {
        case .headphones,
             .bluetoothA2DP,
             .bluetoothHFP,
             .bluetoothLE,
             .airPlay,
             .carAudio,
             .usbAudio,
             .HDMI:
            return true
        default:
            return false
        }
    }
}

private struct Blob: Encodable {
    let mimeType: String
    let data: Data
}

private struct Content: Codable {
    struct Part: Codable {
        let text: String?
        let inlineData: InlineData?

        init(text: String) {
            self.text = text
            inlineData = nil
        }
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: Data
    }

    let role: String?
    let parts: [Part]
}

private struct ServerMessage: Decodable {
    struct GoAway: Decodable {
        // Duration is represented as a string in JSON (e.g. "10s") in many Google APIs.
        // The docs are not explicit for Live; keep it as an optional string for display.
        let timeLeft: String?
    }

    struct Transcription: Decodable {
        let text: String
    }

    struct ServerContent: Decodable {
        let generationComplete: Bool?
        let turnComplete: Bool?
        let interrupted: Bool?
        let inputTranscription: Transcription?
        let outputTranscription: Transcription?
        let modelTurn: Content?
    }

    let setupComplete: Empty?
    let serverContent: ServerContent?
    let goAway: GoAway?
}

private struct Empty: Decodable { }

private enum GeminiLiveInstructions {
    static func system(topicTitle: String, learnerSnippet: String) -> String {
        var s = """
You are a friendly English teacher for children.

Hard rules (safety & privacy):
- Keep language age-appropriate, positive, and kind.
- Do not ask for or store personal data (full name, address, school name, phone number).
- If the learner shares personal data, remind them to keep it private.

Teaching style:
- Speak in short sentences.
- Ask one question at a time.
- Encourage the learner to answer out loud.
"""

        if !learnerSnippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            s += "\n\nLearner context:\n\(learnerSnippet)"
        }
        if !topicTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            s += "\n\nSelected topic: \(topicTitle)"
        }

        return s
    }
}
