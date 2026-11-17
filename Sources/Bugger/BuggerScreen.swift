import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let screenshotSource: BuggerScreenshotSource
    private let includeScreenshots: Bool
    private let screenshots: [BugReportAttachment]
    private let speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)?
    private let onSubmit: (@MainActor (BugReportPackage) -> Void)?

    /// - Parameters:
    ///   - bugger: Builds, packs and submits the report.
    ///   - includeScreenshots: Shows the screenshots section, where the reporter can add images from the photo library.
    ///   - screenshots: Images already attached when the screen opens, such as one from
    ///     `BuggerScreenCapture.captureForegroundScene()`. The reporter can annotate or remove them.
    ///     Passing any shows the screenshots section even if `includeScreenshots` is false.
    ///   - speechTranscriptionEngine: Turns on dictation in the composer. `nil` hides the microphone button.
    ///   - onSubmit: Called with the package after it was submitted.
    public init(
        bugger: Bugger = .onDevice,
        includeScreenshots: Bool = true,
        screenshots: [BugReportAttachment] = [],
        speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)? = nil,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.bugger = bugger
        self.includeScreenshots = includeScreenshots
        self.screenshots = screenshots
        self.speechTranscriptionEngine = speechTranscriptionEngine
        self.onSubmit = onSubmit
        self.screenshotSource = .photoLibrary
    }

    public var body: some View {
        BuggerReporterView(
            bugger: bugger,
            screenshotSource: screenshotSource,
            includeScreenshots: includeScreenshots,
            screenshots: screenshots,
            speechTranscriptionEngine: speechTranscriptionEngine,
            onSubmit: onSubmit
        )
    }
}

#Preview {
    BuggerScreen(bugger: .preview)
}
