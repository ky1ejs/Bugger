import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let allowsPhotoLibrary: Bool
    private let screenshots: [BugReportAttachment]
    private let speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)?
    private let onSubmit: (@MainActor (BugReportPackage) -> Void)?

    /// The arguments are read once, when the screen first appears. Later changes from the
    /// parent view don't reset what the reporter has typed, attached or removed.
    ///
    /// - Parameters:
    ///   - bugger: Builds, packs and submits the report.
    ///   - allowsPhotoLibrary: Shows an "Add" tile that attaches screenshots from the photo library.
    ///   - screenshots: Images already attached when the screen opens, such as one from
    ///     `BuggerScreenCapture.capture()`. The reporter can annotate or remove them.
    ///   - speechTranscriptionEngine: Turns on dictation in the composer. `nil` hides the microphone button.
    ///   - onSubmit: Called with the package after it was submitted.
    ///
    /// The screenshots section appears when `allowsPhotoLibrary` is true or `screenshots` isn't empty.
    public init(
        bugger: Bugger = .onDevice,
        allowsPhotoLibrary: Bool = true,
        screenshots: [BugReportAttachment] = [],
        speechTranscriptionEngine: (any BuggerSpeechTranscriptionEngine)? = nil,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.bugger = bugger
        self.allowsPhotoLibrary = allowsPhotoLibrary
        self.screenshots = screenshots
        self.speechTranscriptionEngine = speechTranscriptionEngine
        self.onSubmit = onSubmit
    }

    public var body: some View {
        BuggerReporterView(
            bugger: bugger,
            screenshotSource: allowsPhotoLibrary ? .photoLibrary : nil,
            screenshots: screenshots,
            speechTranscriptionEngine: speechTranscriptionEngine,
            onSubmit: onSubmit
        )
    }
}

#Preview {
    BuggerScreen(bugger: .preview)
}
