import SwiftUI
import XCTest
import Bugger

/// Compiles the README's examples against the public API (`import Bugger`, not `@testable`),
/// so a breaking change to the API also breaks this file.
@MainActor
final class ReadmeExamplesTests: XCTestCase {
    func testQuickStart() {
        let bugger = Bugger(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: HTTPReportSubmitter(url: URL(string: "https://api.example.com/bug-reports")!)
        )

        _ = Text("Content").buggerReporting(bugger)
    }

    func testOpeningOptionsAndButton() {
        _ = Text("Content").buggerReporting(
            .onDevice,
            isEnabled: false,
            triggers: [.shake, .screenshot],
            asksBeforeOpening: false,
            attachesScreenshot: false,
            allowsPhotoLibrary: false,
            speechTranscriptionEngine: OnDeviceSpeechTranscriptionEngine(),
            onSubmit: { _ in }
        )
        _ = ReportButton()
    }

    func testScreenshotsAndRedaction() {
        let screenshot = BuggerScreenCapture.capture()
        _ = BuggerScreen(bugger: .onDevice, screenshots: [screenshot].compactMap { $0 })
        _ = Text("Account 1234").buggerRedacted()
        _ = BuggerScreenCapture.capture(scene: nil, includingWindow: BuggerScreenCapture.isAppWindow)
    }

    func testIdentifyingReporters() {
        _ = Bugger(
            bugReporterProvider: BugReporterProvider {
                BugReporter(id: "user-1", displayName: "Sam", reachoutIdentifier: "sam@example.com")
            },
            deviceInfoProvider: DefaultDeviceInfoProvider(includesIdentifierForVendor: true),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: HTTPReportSubmitter(
                url: URL(string: "https://api.example.com/bug-reports")!,
                headers: { ["Authorization": "Bearer token"] }
            )
        )
        _ = DefaultBugReporterProvider(including: [.identifierForVendor, .deviceName])
    }
}

private struct ReportButton: View {
    @Environment(\.buggerReport) private var buggerReport

    var body: some View {
        if let buggerReport {
            Button("Report a bug") { buggerReport() }
        }
    }
}
