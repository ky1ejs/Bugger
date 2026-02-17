import XCTest
import UIKit
@testable import Bugger

@MainActor
final class BuggerScreenshotAnnotationTests: XCTestCase {
    func testAnnotatableIsTrueForImageMimeTypeWithDecodableData() {
        let attachment = BugReportAttachment(
            data: makeImageData(color: .systemBlue),
            mimeType: "image/png",
            filename: "screenshot.png"
        )
        let item = BuggerScreenshotItem(attachment: attachment, thumbnail: nil)

        XCTAssertTrue(item.isAnnotatable)
    }

    func testAnnotatableIsFalseForVideoMimeType() {
        let attachment = BugReportAttachment(
            data: makeImageData(color: .systemBlue),
            mimeType: "video/mp4",
            filename: "capture.mp4"
        )
        let item = BuggerScreenshotItem(attachment: attachment, thumbnail: nil)

        XCTAssertFalse(item.isAnnotatable)
    }

    func testAnnotatableIsFalseForImageMimeTypeWithUndecodableData() {
        let attachment = BugReportAttachment(
            data: Data("not-an-image".utf8),
            mimeType: "image/png",
            filename: "broken.png"
        )
        let item = BuggerScreenshotItem(attachment: attachment, thumbnail: nil)

        XCTAssertFalse(item.isAnnotatable)
    }

    func testReplacingAnnotatedImagePreservesCountAndAttachmentID() {
        let originalAttachmentID = UUID()
        let originalAttachment = BugReportAttachment(
            id: originalAttachmentID,
            data: makeImageData(color: .systemBlue),
            mimeType: "image/jpeg",
            filename: "screen.jpg"
        )

        let viewModel = BuggerScreenshotCarouselViewModel(source: .previewMock)
        viewModel.add([originalAttachment])
        let itemID = tryUnwrap(viewModel.items.first?.id)

        let replaced = viewModel.replaceAnnotatedImage(for: itemID, with: makeImage(color: .systemRed))
        XCTAssertTrue(replaced)
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items[0].attachment.id, originalAttachmentID)
    }

    func testReplacingAnnotatedImageSetsMimeTypeToPNG() {
        let originalAttachment = BugReportAttachment(
            data: makeImageData(color: .systemBlue),
            mimeType: "image/jpeg",
            filename: "screen.jpg"
        )

        let viewModel = BuggerScreenshotCarouselViewModel(source: .previewMock)
        viewModel.add([originalAttachment])
        let itemID = tryUnwrap(viewModel.items.first?.id)

        let replaced = viewModel.replaceAnnotatedImage(for: itemID, with: makeImage(color: .systemRed))
        XCTAssertTrue(replaced)
        XCTAssertEqual(viewModel.items[0].attachment.mimeType, "image/png")
    }

    private func makeImageData(color: UIColor) -> Data {
        let image = makeImage(color: color)
        return tryUnwrap(image.pngData())
    }

    private func makeImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func tryUnwrap<T>(_ value: T?) -> T {
        guard let value else {
            XCTFail("Expected non-nil value.")
            fatalError("Unexpected nil value.")
        }
        return value
    }
}
