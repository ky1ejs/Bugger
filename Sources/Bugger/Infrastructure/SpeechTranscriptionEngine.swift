import AVFoundation
import Foundation
import Speech
#if canImport(FoundationModels)
import FoundationModels
#endif

public protocol BuggerSpeechTranscriptionEngine: Sendable {
    func startRecording() async throws
    func stopRecordingAndTranscribe() async throws -> String
}

public enum SpeechTranscriptionError: Error {
    case recognizerUnavailable
    case speechAuthorizationDenied
    case microphoneAuthorizationDenied
    case recordingNotStarted
    case emptyTranscription
}

public actor OnDeviceSpeechTranscriptionEngine: BuggerSpeechTranscriptionEngine {
    private let locale: Locale
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var latestTranscription = ""
    private var isRecording = false

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func startRecording() async throws {
        guard !isRecording else { return }
        guard await Self.hasSpeechPermission() else {
            throw SpeechTranscriptionError.speechAuthorizationDenied
        }
        guard await Self.hasMicrophonePermission() else {
            throw SpeechTranscriptionError.microphoneAuthorizationDenied
        }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw SpeechTranscriptionError.recognizerUnavailable
        }

        try configureAudioSession()
        latestTranscription = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            let transcription = result?.bestTranscription.formattedString
            let hasError = error != nil
            Task {
                await self.handleRecognitionCallback(
                    transcription: transcription,
                    hasError: hasError
                )
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    public func stopRecordingAndTranscribe() async throws -> String {
        guard isRecording else {
            throw SpeechTranscriptionError.recordingNotStarted
        }

        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // Give recognizer a short window to flush the final phrase.
        try? await Task.sleep(nanoseconds: 650_000_000)

        recognitionTask?.cancel()

        let transcription = latestTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanupRecordingResources()

        guard !transcription.isEmpty else {
            throw SpeechTranscriptionError.emptyTranscription
        }
        return await rewriteForDeveloperReportIfPossible(transcription)
    }

    private func handleRecognitionCallback(
        transcription: String?,
        hasError: Bool
    ) {
        if let formattedString = transcription {
            latestTranscription = formattedString
        }

        if hasError {
            // Keep the latest partial transcription and let stop return what it has.
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func cleanupRecordingResources() {
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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
