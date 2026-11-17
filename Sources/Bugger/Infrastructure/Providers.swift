import Foundation
import UIKit

// Defines the responsibilities to provide text attachment
// like the description of what went wrong,
// to a bug report.
public protocol TextInfoProviding: Sendable {
    func collect() -> String
}

// Defines the responsibilities to provide device information
// to attach to a bug report.
public protocol DeviceInfoProviding: Sendable {
    @MainActor
    func collect() -> DeviceInfo
}

// Defines the responsibilities to provide information about
// the author of a bug report.
public protocol BugReporterProviding: Sendable {
    @MainActor
    func collect() -> BugReporter
}

/// Adds attachments to every report when it is submitted, after the reporter has seen the form.
///
/// `Bugger.draftReport` calls it at submit time, while Bugger is on screen, so it isn't the place
/// to capture the app's screen: the reporter couldn't see, annotate or remove the result.
/// To attach a screenshot of the app, capture it with `BuggerScreenCapture.capture()` before
/// presenting `BuggerScreen` and pass it as `screenshots:`.
public protocol ScreenshotProviding: Sendable {
    func capture() async throws -> [BugReportAttachment]
}

// Defines the responsibilities to provide report categories.
public protocol CategoriesProviding: Sendable {
    func fetchCategories() async throws -> [BugReportCategory]
}

// Defines the responsibilities to submit a bug report.
public protocol ReportSubmitting: Sendable {
    func submit(_ package: BugReportPackage) async throws
}

public struct DefaultDeviceInfoProvider: DeviceInfoProviding {
    public init() {}

    @MainActor public func collect()  -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            model: device.model,
            localizedModel: device.localizedModel,
            identifierForVendor: device.identifierForVendor?.uuidString
        )
    }
}

public struct DefaultBugReporterProvider: BugReporterProviding {
    public init() {}

    @MainActor public func collect() -> BugReporter {
        let device = UIDevice.current
        return BugReporter(
            id: device.identifierForVendor?.uuidString ?? "unknown-reporter",
            displayName: device.name,
            reachoutIdentifier: nil
        )
    }
}

public struct NoopReportSubmitter: ReportSubmitting {
    public init() {}

    public func submit(_ package: BugReportPackage) async throws {
        _ = package
    }
}

public enum BuggerError: Error {
    case screenshotUnavailable
}

public struct NoScreenshotProvider: ScreenshotProviding {
    public init() {}

    public func capture() async throws -> [BugReportAttachment] {
        throw BuggerError.screenshotUnavailable
    }
}
