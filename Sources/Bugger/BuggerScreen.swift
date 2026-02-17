import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let screenshotSource: BuggerScreenshotSource
    private let includeScreenshots: Bool
    private let onSubmit: (@MainActor (BugReportPackage) -> Void)?

    public init(
        bugger: Bugger = .onDevice,
        includeScreenshots: Bool = true,
        onSubmit: (@MainActor (BugReportPackage) -> Void)? = nil
    ) {
        self.bugger = bugger
        self.includeScreenshots = includeScreenshots
        self.onSubmit = onSubmit
        self.screenshotSource = .photoLibrary
    }

    public var body: some View {
        BuggerReporterView(
            bugger: bugger,
            screenshotSource: screenshotSource,
            includeScreenshots: includeScreenshots,
            onSubmit: onSubmit
        )
    }
}

#Preview {
    BuggerScreen(bugger: .test)
}
