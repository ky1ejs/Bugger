import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let screenshotSource: BuggerScreenshotSource
    private let includeScreenshots: Bool
    private let speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)?
    private let onSubmit: (@MainActor (BugReportPackage) -> Void)?

    public init(
        bugger: Bugger = .onDevice,
        includeScreenshots: Bool = true,
        speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)? = nil,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.bugger = bugger
        self.includeScreenshots = includeScreenshots
        self.speechTranscriptionEngine = speechTranscriptionEngine
        self.onSubmit = onSubmit
        self.screenshotSource = .photoLibrary
    }

    public var body: some View {
        BuggerReporterView(
            bugger: bugger,
            screenshotSource: screenshotSource,
            includeScreenshots: includeScreenshots,
            speechTranscriptionEngine: speechTranscriptionEngine,
            onSubmit: onSubmit
        )
    }
}

#Preview {
    BuggerScreen(bugger: .preview)
}
