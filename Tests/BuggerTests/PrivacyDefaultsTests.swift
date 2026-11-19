import XCTest
import UIKit
@testable import Bugger

@MainActor
final class PrivacyDefaultsTests: XCTestCase {
    func testDeviceInfoLeavesOutIdentifierForVendorByDefault() {
        let info = DefaultDeviceInfoProvider().collect()

        XCTAssertNil(info.identifierForVendor)
        XCTAssertEqual(info.systemVersion, UIDevice.current.systemVersion)
        XCTAssertEqual(info.model, UIDevice.current.model)
    }

    func testDeviceInfoIncludesIdentifierForVendorWhenAsked() throws {
        let expected = try XCTUnwrap(UIDevice.current.identifierForVendor?.uuidString)

        let info = DefaultDeviceInfoProvider(includesIdentifierForVendor: true).collect()

        XCTAssertEqual(info.identifierForVendor, expected)
    }

    func testReporterIsAnonymousByDefault() {
        let reporter = DefaultBugReporterProvider().collect()

        XCTAssertEqual(reporter.id, "anonymous")
        XCTAssertEqual(reporter.displayName, "Anonymous")
        XCTAssertNil(reporter.reachoutIdentifier)
    }

    func testReporterUsesOnlyTheDetailsAskedFor() throws {
        let identifierForVendor = try XCTUnwrap(UIDevice.current.identifierForVendor?.uuidString)

        let idOnly = DefaultBugReporterProvider(including: .identifierForVendor).collect()
        let nameOnly = DefaultBugReporterProvider(including: .deviceName).collect()

        XCTAssertEqual(idOnly.id, identifierForVendor)
        XCTAssertEqual(idOnly.displayName, "Anonymous")
        XCTAssertEqual(nameOnly.id, "anonymous")
        XCTAssertEqual(nameOnly.displayName, UIDevice.current.name)
    }

    func testCustomReporterProviderIsCalledForEachReport() {
        let counter = CallCounter()
        let provider = BugReporterProvider {
            counter.count += 1
            return BugReporter(id: "user-\(counter.count)", displayName: "Sam", reachoutIdentifier: "sam@example.com")
        }

        XCTAssertEqual(provider.collect().id, "user-1")
        XCTAssertEqual(provider.collect().id, "user-2")
        XCTAssertEqual(provider.collect().reachoutIdentifier, "sam@example.com")
    }

    func testDefaultReportPayloadContainsNoDeviceIdentifiers() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let bugger = Bugger(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(destinationDirectory: directory),
            submitter: NoopReportSubmitter()
        )

        let report = try await bugger.draftReport(description: "It froze")
        let package = try await bugger.submit(report)

        let json = String(decoding: package.payload, as: UTF8.self)
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
            XCTAssertFalse(json.contains(identifierForVendor), json)
        }
        XCTAssertFalse(json.contains("identifierForVendor"), json)
        XCTAssertTrue(json.contains("\"id\" : \"anonymous\""), json)
    }
}

@MainActor
private final class CallCounter: Sendable {
    nonisolated(unsafe) var count = 0
}
