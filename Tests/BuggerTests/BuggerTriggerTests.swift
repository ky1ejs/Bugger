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

        // Would crash with an unrecognized selector if the hook had replaced UIResponder's method.
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
final class BuggerReportPresenterTests: XCTestCase {
    func testWithoutAWindowNothingIsOwnedOrPresented() {
        let presenter = BuggerReportPresenter()

        XCTAssertFalse(presenter.owns(shakenWindow: UIWindow(frame: .zero)))
        XCTAssertFalse(presenter.owns(shakenWindow: nil))
        XCTAssertFalse(presenter.isInFrontmostScene)
        presenter.present(
            BuggerReportingConfiguration(
                bugger: .preview,
                attachesScreenshot: true,
                allowsPhotoLibrary: true,
                speechTranscriptionEngine: nil,
                onSubmit: nil
            )
        )
        XCTAssertFalse(BuggerReportPresenter.isPresenting)
    }

    func testTopViewControllerWithoutPresentationsIsTheRoot() {
        let root = UIViewController()

        XCTAssertIdentical(BuggerReportPresenter.topViewController(from: root), root)
        XCTAssertNil(BuggerReportPresenter.topViewController(from: nil))
    }

    func testTriggerSet() {
        XCTAssertEqual(BuggerTrigger.all, [.shake, .screenshot])
        XCTAssertFalse(BuggerTrigger([]).contains(.shake))
    }
}
