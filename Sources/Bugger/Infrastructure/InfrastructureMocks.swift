#if DEBUG && canImport(SwiftUI)

extension Bugger {
    public static var preview: Self {
        return Self(
            bugReporterProvider: DefaultBugReporterProvider(),
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            categoriesProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
}

extension BugReporter {
    public static func preview(
        id: String = "preview-reporter",
        displayName: String = "Preview Reporter",
        reachoutIdentifier: String? = "preview@bugger.local"
    ) -> Self {
        Self(
            id: id,
            displayName: displayName,
            reachoutIdentifier: reachoutIdentifier
        )
    }
}

public actor DemoSpeechTranscriptionEngine: BuggerSpeechTranscriptionEngine {
    private let transcription: String
    private let processingDelayNanoseconds: UInt64

    public init(
        transcription: String = """
        I can reliably reproduce this issue by opening Settings and tapping Save.
        The screen freezes for around five seconds and then the app becomes unresponsive.
        """,
        processingDelayNanoseconds: UInt64 = 1_400_000_000
    ) {
        self.transcription = transcription
        self.processingDelayNanoseconds = processingDelayNanoseconds
    }

    public func startRecording() async throws {}

    public func stopRecordingAndTranscribe() async throws -> String {
        try await Task.sleep(nanoseconds: processingDelayNanoseconds)
        return transcription
    }

    public func cancelRecording() async {}
}

#endif
