import XCTest
import UIKit
@testable import Bugger

@MainActor
final class BuggerScreenCaptureTests: XCTestCase {
    private let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)

    func testCaptureProducesPNGAtBoundsTimesScale() throws {
        let window = makeWindow(frame: bounds, color: .red)

        let attachment = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [window], bounds: bounds, scale: 2)
        )

        XCTAssertEqual(attachment.mimeType, "image/png")
        XCTAssertEqual(attachment.filename, "screenshot.png")
        let image = try XCTUnwrap(UIImage(data: attachment.data)?.cgImage)
        XCTAssertEqual(image.width, 200)
        XCTAssertEqual(image.height, 400)
    }

    func testCaptureDrawsWindowContent() throws {
        let window = makeWindow(frame: bounds, color: .red)

        let attachment = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [window], bounds: bounds, scale: 1)
        )

        let pixel = try pixel(in: attachment, x: 50, y: 100)
        XCTAssertGreaterThan(pixel.red, 200)
        XCTAssertLessThan(pixel.green, 50)
        XCTAssertLessThan(pixel.blue, 50)
    }

    func testHigherWindowLevelIsDrawnOnTop() throws {
        let alertLevel = makeWindow(frame: bounds, color: .blue)
        alertLevel.windowLevel = .alert
        let normalLevel = makeWindow(frame: bounds, color: .red)

        // The higher-level window is listed first; it must still end up on top.
        let attachment = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [alertLevel, normalLevel], bounds: bounds, scale: 1)
        )

        let pixel = try pixel(in: attachment, x: 50, y: 100)
        XCTAssertGreaterThan(pixel.blue, 200)
        XCTAssertLessThan(pixel.red, 50)
    }

    func testHiddenWindowsAreSkipped() throws {
        let visible = makeWindow(frame: bounds, color: .red)
        let hidden = makeWindow(frame: bounds, color: .blue)
        hidden.windowLevel = .alert
        hidden.isHidden = true

        let attachment = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [visible, hidden], bounds: bounds, scale: 1)
        )

        let pixel = try pixel(in: attachment, x: 50, y: 100)
        XCTAssertGreaterThan(pixel.red, 200)
        XCTAssertLessThan(pixel.blue, 50)
    }

    func testNoVisibleWindowsReturnsNil() {
        let hidden = makeWindow(frame: bounds, color: .red)
        hidden.isHidden = true

        XCTAssertNil(BuggerScreenCapture.capture(windows: [hidden], bounds: bounds, scale: 1))
        XCTAssertNil(BuggerScreenCapture.capture(windows: [], bounds: bounds, scale: 1))
    }

    func testCarouselStartsWithInitialScreenshots() async throws {
        let window = makeWindow(frame: bounds, color: .red)
        let screenshot = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [window], bounds: bounds, scale: 1)
        )

        let viewModel = BuggerScreenshotCarouselViewModel(
            source: .previewMock,
            initialAttachments: [screenshot]
        )

        XCTAssertEqual(viewModel.items.map(\.attachment.id), [screenshot.id])
        XCTAssertTrue(try XCTUnwrap(viewModel.items.first).isAnnotatable)
        let draft = try await viewModel.apply(to: BuggerReportDraft())
        XCTAssertEqual(draft.attachments.map(\.id), [screenshot.id])
    }

    func testPhotoLibraryOffWithScreenshotsShowsOnlyThoseScreenshots() throws {
        let screenshot = BugReportAttachment(data: Data([0]), mimeType: "image/png")

        let withScreenshot = BuggerReporterViewModel(
            bugger: .preview,
            screenshotSource: nil,
            screenshots: [screenshot]
        )
        let withoutScreenshot = BuggerReporterViewModel(bugger: .preview, screenshotSource: nil)

        let carousel = try XCTUnwrap(withScreenshot.screenshots)
        XCTAssertEqual(carousel.items.count, 1)
        guard case .attachedOnly = carousel.source.mode else {
            return XCTFail("Expected no Add tile when the photo library is off")
        }
        XCTAssertNil(withoutScreenshot.screenshots)
    }

    func testEachWindowIsDrawnOnceInLevelOrder() throws {
        let alert = makeWindow(frame: bounds, color: .blue)
        alert.windowLevel = .alert
        let normal = makeWindow(frame: bounds, color: .red)
        let hidden = makeWindow(frame: bounds, color: .green)
        hidden.isHidden = true
        var drawn: [UIWindow] = []

        _ = BuggerScreenCapture.capture(
            windows: [alert, hidden, normal],
            bounds: bounds,
            scale: 1,
            draw: { window, _ in drawn.append(window) }
        )

        XCTAssertEqual(drawn.map(ObjectIdentifier.init), [normal, alert].map(ObjectIdentifier.init))
    }

    func testRedactedViewIsBlackedOut() throws {
        let window = makeWindow(frame: bounds, color: .red)
        let secret = UIView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
        secret.backgroundColor = .red
        window.addSubview(secret)
        BuggerScreenCapture.redact(secret)
        defer { BuggerScreenCapture.unredact(secret) }

        let attachment = try XCTUnwrap(
            BuggerScreenCapture.capture(windows: [window], bounds: bounds, scale: 1)
        )

        XCTAssertEqual(BuggerScreenCapture.redactedRects(in: [window]), [secret.frame])
        let inside = try pixel(in: attachment, x: 25, y: 40)
        XCTAssertLessThan(Int(inside.red) + Int(inside.green) + Int(inside.blue), 30)
        let outside = try pixel(in: attachment, x: 80, y: 150)
        XCTAssertGreaterThan(outside.red, 200)
    }

    func testRedactedRectAccountsForWindowOffsetAndSkipsHiddenViews() {
        let window = makeWindow(frame: CGRect(x: 0, y: 50, width: 100, height: 150), color: .red)
        let secret = UIView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        let hiddenSecret = UIView(frame: CGRect(x: 40, y: 40, width: 20, height: 20))
        hiddenSecret.isHidden = true
        window.addSubview(secret)
        window.addSubview(hiddenSecret)
        BuggerScreenCapture.redact(secret)
        BuggerScreenCapture.redact(hiddenSecret)
        defer {
            BuggerScreenCapture.unredact(secret)
            BuggerScreenCapture.unredact(hiddenSecret)
        }

        XCTAssertEqual(
            BuggerScreenCapture.redactedRects(in: [window]),
            [CGRect(x: 10, y: 60, width: 20, height: 20)]
        )
        XCTAssertEqual(BuggerScreenCapture.redactedRects(in: []), [])
    }

    func testUnredactStopsRedacting() {
        let window = makeWindow(frame: bounds, color: .red)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        window.addSubview(view)
        BuggerScreenCapture.redact(view)

        BuggerScreenCapture.unredact(view)

        XCTAssertEqual(BuggerScreenCapture.redactedRects(in: [window]), [])
    }

    func testKeyboardWindowsAreNotAppWindows() throws {
        XCTAssertTrue(BuggerScreenCapture.isAppWindow(UIWindow(frame: bounds)))
        let textEffectsClass = try XCTUnwrap(NSClassFromString("UITextEffectsWindow") as? UIWindow.Type)
        XCTAssertFalse(BuggerScreenCapture.isAppWindow(textEffectsClass.init(frame: bounds)))
    }

    // MARK: - Helpers

    private func makeWindow(frame: CGRect, color: UIColor) -> UIWindow {
        let window = UIWindow(frame: frame)
        window.backgroundColor = color
        window.isHidden = false
        return window
    }

    private func pixel(in attachment: BugReportAttachment, x: Int, y: Int) throws -> (red: UInt8, green: UInt8, blue: UInt8) {
        let image = try XCTUnwrap(UIImage(data: attachment.data)?.cgImage)
        var bytes = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(
            data: &bytes,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        // Draw the image so that pixel (x, y), counted from the top left, lands on the 1x1 context.
        context.draw(
            image,
            in: CGRect(
                x: -CGFloat(x),
                y: -CGFloat(image.height - 1 - y),
                width: CGFloat(image.width),
                height: CGFloat(image.height)
            )
        )
        return (bytes[0], bytes[1], bytes[2])
    }
}
