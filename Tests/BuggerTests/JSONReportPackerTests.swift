import XCTest
@testable import Bugger

final class JSONReportPackerTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("JSONReportPackerTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testAttachmentsWithTheSameFilenameAreAllKept() async throws {
        let attachments = [
            BugReportAttachment(data: Data([1]), mimeType: "image/png", filename: "screenshot.png"),
            BugReportAttachment(data: Data([2]), mimeType: "image/png", filename: "screenshot.png"),
            BugReportAttachment(data: Data([3]), mimeType: "image/png", filename: "Screenshot.PNG"),
        ]

        let package = try await JSONReportPacker(destinationDirectory: directory).pack(makeReport(attachments))

        XCTAssertEqual(
            package.attachments.map(\.filename),
            ["screenshot.png", "screenshot-2.png", "Screenshot-3.PNG"]
        )
        let contents = try package.attachments.map { try Data(contentsOf: $0.fileURL) }
        XCTAssertEqual(contents, [Data([1]), Data([2]), Data([3])])
    }

    func testMissingOrDotFilenamesGetGeneratedNames() async throws {
        let attachments = [
            BugReportAttachment(data: Data([1]), mimeType: "image/png"),
            BugReportAttachment(data: Data([2]), mimeType: "image/jpeg", filename: ".."),
        ]

        let package = try await JSONReportPacker(destinationDirectory: directory).pack(makeReport(attachments))

        XCTAssertEqual(package.attachments.map(\.filename), ["attachment-1.png", "attachment-2.jpg"])
    }

    func testUniqueFilenameWithoutExtension() {
        var used: Set<String> = []

        XCTAssertEqual(JSONReportPacker.uniqueFilename("log", usedFilenames: &used), "log")
        XCTAssertEqual(JSONReportPacker.uniqueFilename("log", usedFilenames: &used), "log-2")
        XCTAssertEqual(JSONReportPacker.uniqueFilename("log-2", usedFilenames: &used), "log-2-2")
    }

    private func makeReport(_ attachments: [BugReportAttachment]) -> BugReport {
        BugReport(
            description: "Test",
            deviceInfo: DeviceInfo(
                systemName: "iOS",
                systemVersion: "26.0",
                model: "iPhone",
                localizedModel: "iPhone",
                identifierForVendor: nil
            ),
            attachments: attachments
        )
    }
}
