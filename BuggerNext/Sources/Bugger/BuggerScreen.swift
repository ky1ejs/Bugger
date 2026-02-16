import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let screenshotSource: BuggerScreenshotSource
    private let includeScreenshots: Bool

    public init(
        bugger: Bugger = .onDevice,
        includeScreenshots: Bool = true
    ) {
        self.bugger = bugger
        self.includeScreenshots = includeScreenshots
        self.screenshotSource = .photoLibrary
    }

    public var body: some View {
        BuggerReporter(
            bugger: bugger,
            screenshotSource: screenshotSource,
            includeScreenshots: includeScreenshots
        )
    }
}

#Preview {
    BuggerScreen(bugger: .test)
}
