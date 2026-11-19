import XCTest
import UIKit
@testable import Bugger

@MainActor
final class BuggerShakeDetectorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BuggerShakeDetector.install()
    }

    func testShakeOnWindowPostsNotificationWithThatWindow() {
        let window = UIWindow(frame: .zero)
        let posted = expectation(forNotification: .buggerWindowDidShake, object: window)

        window.motionEnded(.motionShake, with: nil)

        wait(for: [posted], timeout: 1)
    }

    func testOtherMotionsDoNotPost() {
        let window = UIWindow(frame: .zero)
        let posted = expectation(forNotification: .buggerWindowDidShake, object: window)
        posted.isInverted = true

        window.motionEnded(.none, with: nil)

        wait(for: [posted], timeout: 0.2)
    }

    func testOtherRespondersAreUnaffected() {
        let view = UIView()
        let posted = expectation(forNotification: .buggerWindowDidShake, object: nil)
        posted.isInverted = true

        // If the hook had been installed on UIResponder instead of UIWindow, these would post.
        view.motionEnded(.motionShake, with: nil)
        UIViewController().motionEnded(.motionShake, with: nil)

        wait(for: [posted], timeout: 0.2)
    }

    func testInstallingTwiceKeepsOneNotificationPerShake() {
        BuggerShakeDetector.install()
        let window = UIWindow(frame: .zero)
        var count = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .buggerWindowDidShake,
            object: window,
            queue: nil
        ) { _ in count += 1 }
        defer { NotificationCenter.default.removeObserver(observer) }

        window.motionEnded(.motionShake, with: nil)

        XCTAssertEqual(count, 1)
        XCTAssertTrue(BuggerShakeDetector.isInstalled)
    }
}

@MainActor
final class BuggerReportCoordinatorTests: XCTestCase {
    private var overlay: FakeOverlay!
    private var counter: CaptureCounter!
    private var coordinator: BuggerReportCoordinator!

    /// How many times the screen was captured.
    private var captures: Int { counter.count }

    override func setUp() async throws {
        try await super.setUp()
        overlay = FakeOverlay()
        let counter = CaptureCounter()
        self.counter = counter
        coordinator = BuggerReportCoordinator(
            overlay: overlay,
            captureScreen: {
                counter.count += 1
                return BugReportAttachment(data: Data([UInt8(counter.count)]), mimeType: "image/png")
            },
            promptDuration: { .seconds(60) }
        )
    }

    func testTriggerThatAsksCapturesNowAndShowsThePrompt() {
        coordinator.handleTrigger(configuration(), asksFirst: true)

        XCTAssertEqual(coordinator.state, .prompting)
        XCTAssertEqual(captures, 1)
        XCTAssertEqual(overlay.promptsShown, 1)
        XCTAssertTrue(overlay.presentedScreenshots.isEmpty)
    }

    func testAcceptingThePromptOpensTheReportWithTheTriggerScreenshot() throws {
        coordinator.handleTrigger(configuration(), asksFirst: true)

        try XCTUnwrap(overlay.onReport)()

        XCTAssertEqual(coordinator.state, .reporting)
        XCTAssertEqual(overlay.promptsHidden, 1)
        XCTAssertEqual(captures, 1, "The screenshot is the one taken when the trigger fired")
        XCTAssertEqual(overlay.presentedScreenshots, [[Data([1])]])
    }

    func testClosingThePromptOpensNothing() throws {
        coordinator.handleTrigger(configuration(), asksFirst: true)

        try XCTUnwrap(overlay.onClose)()

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(overlay.promptsHidden, 1)
        XCTAssertTrue(overlay.presentedScreenshots.isEmpty)
    }

    func testPromptClosesItselfAfterItsDuration() async throws {
        coordinator = BuggerReportCoordinator(
            overlay: overlay,
            captureScreen: { nil },
            promptDuration: { .milliseconds(50) }
        )
        coordinator.handleTrigger(configuration(), asksFirst: true)

        try await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(overlay.promptsHidden, 1)
    }

    func testTriggerThatDoesNotAskOpensStraightAway() {
        coordinator.handleTrigger(configuration(), asksFirst: false)

        XCTAssertEqual(coordinator.state, .reporting)
        XCTAssertEqual(overlay.promptsShown, 0)
        XCTAssertEqual(overlay.presentedScreenshots.count, 1)
    }

    func testTriggersWhilePromptingOrReportingAreIgnored() throws {
        coordinator.handleTrigger(configuration(), asksFirst: true)
        coordinator.handleTrigger(configuration(), asksFirst: true)
        XCTAssertEqual(overlay.promptsShown, 1)

        try XCTUnwrap(overlay.onReport)()
        coordinator.handleTrigger(configuration(), asksFirst: false)
        coordinator.open(configuration())

        XCTAssertEqual(overlay.presentedScreenshots.count, 1)
        XCTAssertEqual(captures, 1)
    }

    func testFinishingTheReportAllowsAnotherOne() throws {
        coordinator.handleTrigger(configuration(), asksFirst: false)
        try XCTUnwrap(overlay.onFinish)()
        XCTAssertEqual(coordinator.state, .idle)

        coordinator.handleTrigger(configuration(), asksFirst: false)

        XCTAssertEqual(overlay.presentedScreenshots.count, 2)
    }

    func testOpeningFromCodeReplacesThePromptWithAFreshCapture() {
        coordinator.handleTrigger(configuration(), asksFirst: true)

        coordinator.open(configuration())

        XCTAssertEqual(coordinator.state, .reporting)
        XCTAssertEqual(overlay.promptsHidden, 1)
        XCTAssertEqual(overlay.presentedScreenshots, [[Data([2])]])
    }

    func testNoScreenshotIsCapturedWhenTurnedOff() {
        coordinator.handleTrigger(configuration(attachesScreenshot: false), asksFirst: false)

        XCTAssertEqual(captures, 0)
        XCTAssertEqual(overlay.presentedScreenshots, [[]])
    }

    func testDisablingClosesThePrompt() {
        coordinator.handleTrigger(configuration(), asksFirst: true)

        coordinator.disable()

        XCTAssertEqual(coordinator.state, .idle)
        XCTAssertEqual(overlay.promptsHidden, 1)
    }

    func testDisablingDismissesAnOpenReport() throws {
        coordinator.handleTrigger(configuration(), asksFirst: false)

        coordinator.disable()
        XCTAssertEqual(overlay.reportsDismissed, 1)
        try XCTUnwrap(overlay.onFinish)()

        XCTAssertEqual(coordinator.state, .idle)
    }

    func testTriggerGating() {
        typealias Modifier = BuggerReportingModifier
        XCTAssertTrue(Modifier.responds(to: .shake, isEnabled: true, triggers: .all))
        XCTAssertTrue(Modifier.responds(to: .screenshot, isEnabled: true, triggers: [.screenshot]))
        XCTAssertFalse(Modifier.responds(to: .shake, isEnabled: true, triggers: [.screenshot]))
        XCTAssertFalse(Modifier.responds(to: .shake, isEnabled: true, triggers: []))
        XCTAssertFalse(Modifier.responds(to: .shake, isEnabled: false, triggers: .all))
        XCTAssertFalse(Modifier.responds(to: .screenshot, isEnabled: false, triggers: .all))
    }

    func testOverlayWindowIsNeverCaptured() {
        XCTAssertFalse(BuggerScreenCapture.isAppWindow(BuggerOverlayWindow(frame: .zero)))
    }

    func testSceneReaderWithoutAWindowOwnsNothing() {
        let reader = BuggerSceneReader()

        XCTAssertFalse(reader.owns(UIWindow(frame: .zero)))
        XCTAssertFalse(reader.owns(nil))
        XCTAssertFalse(reader.isFrontmost)
        XCTAssertNil(reader.coordinator)
    }

    private func configuration(attachesScreenshot: Bool = true) -> BuggerReportingConfiguration {
        BuggerReportingConfiguration(
            bugger: .preview,
            attachesScreenshot: attachesScreenshot,
            allowsPhotoLibrary: true,
            speechTranscriptionEngine: nil,
            onSubmit: nil
        )
    }
}

@MainActor
private final class CaptureCounter {
    var count = 0
}

@MainActor
private final class FakeOverlay: BuggerOverlayPresenting {
    var promptsShown = 0
    var promptsHidden = 0
    var reportsDismissed = 0
    var presentedScreenshots: [[Data]] = []
    var onReport: (@MainActor () -> Void)?
    var onClose: (@MainActor () -> Void)?
    var onFinish: (@MainActor () -> Void)?

    func showPrompt(onReport: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) {
        promptsShown += 1
        self.onReport = onReport
        self.onClose = onClose
    }

    func hidePrompt() {
        promptsHidden += 1
    }

    func presentReport(
        configuration: BuggerReportingConfiguration,
        screenshots: [BugReportAttachment],
        onFinish: @escaping @MainActor () -> Void
    ) {
        presentedScreenshots.append(screenshots.map(\.data))
        self.onFinish = onFinish
    }

    func dismissReport() {
        reportsDismissed += 1
    }
}
