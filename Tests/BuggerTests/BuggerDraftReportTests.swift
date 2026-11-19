import XCTest
@testable import Bugger

final class BuggerDraftReportTests: XCTestCase {
    func testDraftCombinesDescriptionReporterDeviceAndAttachments() async throws {
        let passed = BugReportAttachment(data: Data([1]), mimeType: "image/png", filename: "passed.png")
        let captured = BugReportAttachment(data: Data([2]), mimeType: "image/png", filename: "captured.png")
        let bugger = makeBugger(screenshots: StubScreenshots(result: .success([captured])))

        let report = try await bugger.draftReport(description: "It froze", attachments: [passed])

        XCTAssertEqual(report.description, "It froze")
        XCTAssertEqual(report.reporter.id, "user-1")
        XCTAssertEqual(report.deviceInfo.systemName, "TestOS")
        XCTAssertEqual(report.attachments.map(\.id), [passed.id, captured.id], "Passed attachments come first")
    }

    func testExplicitCategoriesWinOverTheProvider() async throws {
        let chosen = BugReportCategory(identifier: "ui", displayName: "UI")
        let bugger = makeBugger(categories: StubCategories(result: .success([
            BugReportCategory(identifier: "network", displayName: "Network"),
        ])))

        let explicit = try await bugger.draftReport(description: "x", categories: [chosen])
        let fromProvider = try await bugger.draftReport(description: "x")

        XCTAssertEqual(explicit.categories.map(\.identifier), ["ui"])
        XCTAssertEqual(fromProvider.categories.map(\.identifier), ["network"])
    }

    func testNoProvidersMeansNoCategoriesOrCapturedScreenshots() async throws {
        let bugger = makeBugger()

        let report = try await bugger.draftReport(description: "x")
        let categories = try await bugger.availableCategories()

        XCTAssertTrue(report.categories.isEmpty)
        XCTAssertTrue(report.attachments.isEmpty)
        XCTAssertTrue(categories.isEmpty)
    }

    func testProviderErrorsFailTheDraft() async throws {
        struct Unavailable: Error {}
        let bugger = makeBugger(screenshots: StubScreenshots(result: .failure(Unavailable())))

        do {
            _ = try await bugger.draftReport(description: "x")
            XCTFail("Expected an error")
        } catch is Unavailable {}
    }

    func testSubmitPacksThenSubmitsTheSamePackage() async throws {
        let submitter = RecordingSubmitter()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let bugger = makeBugger(packer: JSONReportPacker(destinationDirectory: directory), submitter: submitter)
        let report = try await bugger.draftReport(description: "It froze")

        let package = try await bugger.submit(report)

        let submittedIDs = await submitter.reportIDs
        XCTAssertEqual(package.reportID, report.id)
        XCTAssertEqual(submittedIDs, [report.id])
    }

    @MainActor
    func testDeviceInfoIncludesAppVersionAndBuild() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }
        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.example.test",
            "CFBundleShortVersionString": "3.2",
            "CFBundleVersion": "412",
        ]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: bundleURL.appendingPathComponent("Info.plist"))
        let bundle = try XCTUnwrap(Bundle(url: bundleURL))

        let info = DefaultDeviceInfoProvider(bundle: bundle).collect()

        XCTAssertEqual(info.appVersion, "3.2")
        XCTAssertEqual(info.appBuild, "412")
    }

    private func makeBugger(
        screenshots: (any ScreenshotProviding)? = nil,
        categories: (any CategoriesProviding)? = nil,
        packer: any BugReportPacking = JSONReportPacker(),
        submitter: any ReportSubmitting = NoopReportSubmitter()
    ) -> Bugger {
        Bugger(
            bugReporterProvider: BugReporterProvider {
                BugReporter(id: "user-1", displayName: "Sam")
            },
            deviceInfoProvider: StubDeviceInfo(),
            screenshotProvider: screenshots,
            categoriesProvider: categories,
            packer: packer,
            submitter: submitter
        )
    }
}

private struct StubDeviceInfo: DeviceInfoProviding {
    @MainActor func collect() -> DeviceInfo {
        DeviceInfo(systemName: "TestOS", systemVersion: "1", model: "Test", localizedModel: "Test", identifierForVendor: nil)
    }
}

private struct StubScreenshots: ScreenshotProviding {
    let result: Result<[BugReportAttachment], any Error>

    func capture() async throws -> [BugReportAttachment] {
        try result.get()
    }
}

private struct StubCategories: CategoriesProviding {
    let result: Result<[BugReportCategory], any Error>

    func fetchCategories() async throws -> [BugReportCategory] {
        try result.get()
    }
}

private actor RecordingSubmitter: ReportSubmitting {
    private(set) var reportIDs: [UUID] = []

    func submit(_ package: BugReportPackage) async throws {
        reportIDs.append(package.reportID)
    }
}
