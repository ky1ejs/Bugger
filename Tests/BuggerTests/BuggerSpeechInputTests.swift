import XCTest
@testable import Bugger

@MainActor
final class BuggerComposerAppendTranscriptionTests: XCTestCase {
    func testAppendToEmptyTextReplacesIt() {
        let composer = BuggerReporterComposerViewModel()

        composer.appendTranscription("  The app froze.  ")

        XCTAssertEqual(composer.text, "The app froze.")
        XCTAssertEqual(composer.scrollToEndTrigger, 1)
    }

    func testAppendToWhitespaceOnlyTextReplacesIt() {
        let composer = BuggerReporterComposerViewModel()
        composer.text = " \n "

        composer.appendTranscription("The app froze.")

        XCTAssertEqual(composer.text, "The app froze.")
    }

    func testAppendToExistingTextAddsParagraph() {
        let composer = BuggerReporterComposerViewModel()
        composer.text = "Tapped Save."

        composer.appendTranscription("The app froze.")

        XCTAssertEqual(composer.text, "Tapped Save.\n\nThe app froze.")
        XCTAssertEqual(composer.scrollToEndTrigger, 1)
    }

    func testAppendEmptyTranscriptionChangesNothing() {
        let composer = BuggerReporterComposerViewModel()
        composer.text = "Tapped Save."

        composer.appendTranscription("   ")

        XCTAssertEqual(composer.text, "Tapped Save.")
        XCTAssertEqual(composer.scrollToEndTrigger, 0)
    }
}

@MainActor
final class BuggerComposerSpeechInputViewModelTests: XCTestCase {
    func testRecordThenStopDeliversTranscription() async {
        let engine = FakeSpeechEngine(transcription: "The app froze.")
        var received: [String] = []
        let viewModel = BuggerComposerSpeechInputViewModel(engine: engine) { received.append($0) }

        viewModel.toggleRecording()
        XCTAssertEqual(viewModel.state, .startingRecording)
        await viewModel.waitForPendingWork()
        XCTAssertEqual(viewModel.state, .recording)

        viewModel.toggleRecording()
        XCTAssertEqual(viewModel.state, .transcribing)
        await viewModel.waitForPendingWork()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(received, ["The app froze."])
        XCTAssertNil(viewModel.failure)
    }

    func testToggleWhileStartingIsIgnored() async {
        let viewModel = BuggerComposerSpeechInputViewModel(engine: FakeSpeechEngine()) { _ in }

        viewModel.toggleRecording()
        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()

        XCTAssertEqual(viewModel.state, .recording)
    }

    func testDeniedPermissionShowsFailureWithSettingsLink() async {
        let engine = FakeSpeechEngine(startError: BuggerSpeechTranscriptionError.microphoneAuthorizationDenied)
        let viewModel = BuggerComposerSpeechInputViewModel(engine: engine) { _ in }

        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.failure?.offersSettings, true)
        let cancelCount = await engine.cancelCount
        XCTAssertEqual(cancelCount, 1)
    }

    func testEmptyTranscriptionShowsFailure() async {
        let engine = FakeSpeechEngine(stopError: BuggerSpeechTranscriptionError.emptyTranscription)
        var received: [String] = []
        let viewModel = BuggerComposerSpeechInputViewModel(engine: engine) { received.append($0) }

        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()
        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.failure, .init(message: "No speech was detected. Try again."))
        XCTAssertTrue(received.isEmpty)
    }

    func testCancellationShowsNoFailure() async {
        let engine = FakeSpeechEngine(startError: CancellationError())
        let viewModel = BuggerComposerSpeechInputViewModel(engine: engine) { _ in }

        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.failure)
    }

    func testStartingAgainClearsFailure() async {
        let engine = FakeSpeechEngine(startError: BuggerSpeechTranscriptionError.recognizerUnavailable)
        let viewModel = BuggerComposerSpeechInputViewModel(engine: engine) { _ in }
        viewModel.toggleRecording()
        await viewModel.waitForPendingWork()
        XCTAssertNotNil(viewModel.failure)

        viewModel.toggleRecording()

        XCTAssertNil(viewModel.failure)
        await viewModel.waitForPendingWork()
    }
}

private actor FakeSpeechEngine: BuggerSpeechTranscriptionEngine {
    private let transcription: String
    private let startError: (any Error)?
    private let stopError: (any Error)?
    private(set) var cancelCount = 0

    init(transcription: String = "", startError: (any Error)? = nil, stopError: (any Error)? = nil) {
        self.transcription = transcription
        self.startError = startError
        self.stopError = stopError
    }

    func startRecording() async throws {
        if let startError { throw startError }
    }

    func stopRecordingAndTranscribe() async throws -> String {
        if let stopError { throw stopError }
        return transcription
    }

    func cancelRecording() async {
        cancelCount += 1
    }
}
