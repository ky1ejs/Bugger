import AVFoundation
import Foundation
import os
import Speech
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Records the reporter's voice and turns it into text for the report description.
///
/// Pass an engine to `BuggerScreen(speechTranscriptionEngine:)` to show the microphone
/// button in the composer. Without one, the composer has no speech input.
///
/// An engine that uses the microphone or Apple's speech recognizer needs these keys in the
/// host app's Info.plist. iOS terminates the app on the first permission request if either
/// is missing:
/// - `NSMicrophoneUsageDescription`
/// - `NSSpeechRecognitionUsageDescription`
public protocol BuggerSpeechTranscriptionEngine: Sendable {
    /// Requests permission if needed, then starts recording.
    /// Throws `BuggerSpeechTranscriptionError` when permission is denied or recognition is unavailable.
    func startRecording() async throws
    /// Stops recording and returns the transcription.
    func stopRecordingAndTranscribe() async throws -> String
    /// Stops recording, if it is running, and discards what was recorded.
    func cancelRecording() async
}

public enum BuggerSpeechTranscriptionError: Error {
    /// No speech recognizer is available for the engine's locale right now.
    case recognizerUnavailable
    /// The recognizer for the engine's locale can't run on this device without sending audio to Apple.
    case onDeviceRecognitionUnsupported
    /// The user denied speech recognition, or it is restricted on this device.
    case speechAuthorizationDenied
    /// The user denied microphone access.
    case microphoneAuthorizationDenied
    /// No microphone input is available, for example during a phone call.
    case audioInputUnavailable
    case recordingNotStarted
    /// Recording finished without any recognized speech.
    case emptyTranscription
    /// The recognizer failed before producing any text.
    case recognitionFailed(any Error)
}

/// Transcribes speech with `SFSpeechRecognizer`, keeping the audio on the device.
///
/// Recognition requires on-device support for the engine's locale. When the device has none,
/// `startRecording()` throws `BuggerSpeechTranscriptionError.onDeviceRecognitionUnsupported`
/// rather than sending audio to Apple's servers. The iOS Simulator usually has no on-device support.
///
/// When Apple's Foundation Models are available (iOS 26 and later), the transcription is rewritten
/// on the device into a short bug report. Otherwise the raw transcription is returned.
///
/// While recording, the engine sets the shared `AVAudioSession` to `.playAndRecord`. When recording
/// ends, it deactivates the session and restores the category, mode and options it found.
///
/// The host app needs `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`
/// in its Info.plist.
public actor OnDeviceSpeechTranscriptionEngine: BuggerSpeechTranscriptionEngine {
    private struct SavedAudioSession {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    /// How long to wait, after audio ends, for the recognizer's final result.
    private static let finalResultTimeout: Duration = .seconds(2)

    private let locale: Locale
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var results: RecognitionResults?
    private var savedAudioSession: SavedAudioSession?
    private var isTapInstalled = false
    private var isRecording = false

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func startRecording() async throws {
        guard !isRecording else { return }
        guard await Self.hasSpeechPermission() else {
            throw BuggerSpeechTranscriptionError.speechAuthorizationDenied
        }
        try Task.checkCancellation()

        guard await Self.hasMicrophonePermission() else {
            throw BuggerSpeechTranscriptionError.microphoneAuthorizationDenied
        }
        try Task.checkCancellation()

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw BuggerSpeechTranscriptionError.recognizerUnavailable
        }
        guard recognizer.supportsOnDeviceRecognition else {
            throw BuggerSpeechTranscriptionError.onDeviceRecognitionUnsupported
        }
        try Task.checkCancellation()

        do {
            try configureAudioSession()

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true
            recognitionRequest = request

            let results = RecognitionResults()
            self.results = results

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            // installTap raises an Objective-C exception, which Swift can't catch, for a format
            // with no sample rate or channels. That happens when no microphone input is available.
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw BuggerSpeechTranscriptionError.audioInputUnavailable
            }
            inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }
            isTapInstalled = true

            // The recognizer calls this serially. Recording each result synchronously keeps them in order.
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                results.receive(
                    transcription: result?.bestTranscription.formattedString,
                    isFinal: result?.isFinal ?? false,
                    error: error
                )
            }

            try Task.checkCancellation()
            audioEngine.prepare()
            try audioEngine.start()
            try Task.checkCancellation()
            isRecording = true
        } catch {
            cleanupRecordingResources()
            throw error
        }
    }

    public func stopRecordingAndTranscribe() async throws -> String {
        guard isRecording, let results else {
            throw BuggerSpeechTranscriptionError.recordingNotStarted
        }
        defer { cleanupRecordingResources() }

        audioEngine.stop()
        removeTapIfNeeded()
        recognitionRequest?.endAudio()

        // Wait for the recognizer to deliver its final result, so the last phrase isn't cut off.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await results.waitUntilFinished() }
            group.addTask {
                try? await Task.sleep(for: Self.finalResultTimeout)
                results.finish()
            }
            await group.next()
            group.cancelAll()
        }
        try Task.checkCancellation()

        let (rawTranscription, error) = results.snapshot()
        let transcription = rawTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcription.isEmpty else {
            if let error {
                throw BuggerSpeechTranscriptionError.recognitionFailed(error)
            }
            throw BuggerSpeechTranscriptionError.emptyTranscription
        }
        return await rewriteForDeveloperReportIfPossible(transcription)
    }

    public func cancelRecording() async {
        cleanupRecordingResources()
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        savedAudioSession = SavedAudioSession(
            category: session.category,
            mode: session.mode,
            options: session.categoryOptions
        )
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Safe to call more than once, and when nothing was started.
    /// Only touches the audio session if this engine changed it.
    private func cleanupRecordingResources() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        removeTapIfNeeded()
        recognitionRequest = nil
        recognitionTask = nil
        results?.finish()
        results = nil
        isRecording = false
        restoreAudioSession()
    }

    private func removeTapIfNeeded() {
        guard isTapInstalled else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isTapInstalled = false
    }

    private func restoreAudioSession() {
        guard let savedAudioSession else { return }
        self.savedAudioSession = nil
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(
            savedAudioSession.category,
            mode: savedAudioSession.mode,
            options: savedAudioSession.options
        )
    }

    private static func hasSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private static func hasMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func rewriteForDeveloperReportIfPossible(_ rawTranscription: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            if let rewritten = await rewriteWithFoundationModel(rawTranscription) {
                return rewritten
            }
        }
        #endif
        return rawTranscription
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func rewriteWithFoundationModel(_ rawTranscription: String) async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            return nil
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            Rewrite user speech transcription into a concise bug report for software developers.
            Keep facts only, no speculation.
            Prioritize what happened and what was expected.
            Keep output short, scannable, and actionable.

            Do not add any title to the response.
            """
        )

        let prompt = """
        Rewrite this transcription as a bug report summary.

        Output format:
        What happened:
        - <1-3 bullets describing observed behavior and trigger steps>

        Expected:
        - <1 bullet for expected behavior>

        Raw transcription:
        \(rawTranscription)
        """

        do {
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(maximumResponseTokens: 220)
            )
            let rewritten = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return rewritten.isEmpty ? nil : rewritten
        } catch {
            return nil
        }
    }
    #endif
}

/// Collects recognizer callbacks in the order they arrive, and lets the engine wait for the final one.
private final class RecognitionResults: Sendable {
    private struct State {
        var transcription = ""
        var error: (any Error)?
        var isFinished = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func receive(transcription: String?, isFinal: Bool, error: (any Error)?) {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            guard !state.isFinished else { return [] }
            if let transcription {
                state.transcription = transcription
            }
            if let error {
                state.error = error
            }
            guard isFinal || error != nil else { return [] }
            return Self.markFinished(&state)
        }
        waiters.forEach { $0.resume() }
    }

    /// Marks recognition as finished, keeping whatever has arrived so far.
    func finish() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            guard !state.isFinished else { return [] }
            return Self.markFinished(&state)
        }
        waiters.forEach { $0.resume() }
    }

    func waitUntilFinished() async {
        await withCheckedContinuation { continuation in
            let isFinished = state.withLock { state -> Bool in
                if state.isFinished { return true }
                state.waiters.append(continuation)
                return false
            }
            if isFinished {
                continuation.resume()
            }
        }
    }

    func snapshot() -> (transcription: String, error: (any Error)?) {
        state.withLock { ($0.transcription, $0.error) }
    }

    private static func markFinished(_ state: inout State) -> [CheckedContinuation<Void, Never>] {
        state.isFinished = true
        let waiters = state.waiters
        state.waiters = []
        return waiters
    }
}
