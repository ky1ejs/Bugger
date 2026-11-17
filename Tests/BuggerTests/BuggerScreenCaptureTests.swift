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

    func testInitialScreenshotsShowSectionWhenScreenshotsAreOff() {
        let screenshot = BugReportAttachment(data: Data([0]), mimeType: "image/png")

        let withScreenshot = BuggerReporterViewModel(
            bugger: .preview,
            includeScreenshots: false,
            screenshots: [screenshot]
        )
        let withoutScreenshot = BuggerReporterViewModel(
            bugger: .preview,
            includeScreenshots: false
        )

        XCTAssertEqual(withScreenshot.screenshots?.items.count, 1)
        XCTAssertNil(withoutScreenshot.screenshots)
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
