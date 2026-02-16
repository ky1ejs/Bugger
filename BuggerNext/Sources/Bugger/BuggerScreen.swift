import SwiftUI

public struct BuggerScreen: View {
    private let bugger: Bugger
    private let screenshotSource: BuggerScreenshotSource

    public init(bugger: Bugger = .onDevice) {
        self.bugger = bugger
        self.screenshotSource = .photoLibrary
    }

    public var body: some View {
        BuggerReporter(
            bugger: bugger,
            screenshotSource: screenshotSource
        )
    }
}

#Preview {
    BuggerScreen(bugger: .test)
}
