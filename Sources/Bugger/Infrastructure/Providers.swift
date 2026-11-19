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

/// Describes the device: OS name and version, and the model ("iPhone", "iPad").
///
/// The identifier-for-vendor, a stable ID for this device across your apps, is left out unless
/// you turn it on: with it, every report from a device can be linked together.
public struct DefaultDeviceInfoProvider: DeviceInfoProviding {
    private let includesIdentifierForVendor: Bool

    /// - Parameter includesIdentifierForVendor: Adds `UIDevice.identifierForVendor` to each report.
    public init(includesIdentifierForVendor: Bool = false) {
        self.includesIdentifierForVendor = includesIdentifierForVendor
    }

    @MainActor public func collect() -> DeviceInfo {
        let device = UIDevice.current
        return DeviceInfo(
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            model: device.model,
            localizedModel: device.localizedModel,
            identifierForVendor: includesIdentifierForVendor ? device.identifierForVendor?.uuidString : nil
        )
    }
}

/// Reports come from an anonymous reporter unless you opt in to identifying details.
///
/// For signed-in users, use `BugReporterProvider` with your own user's ID and contact details instead.
public struct DefaultBugReporterProvider: BugReporterProviding {
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Uses `UIDevice.identifierForVendor` as the reporter ID, linking every report from a device.
        public static let identifierForVendor = Options(rawValue: 1 << 0)
        /// Uses `UIDevice.name` as the display name. Since iOS 16 this is a generic name such as
        /// "iPhone", unless the app has Apple's user-assigned device name entitlement.
        public static let deviceName = Options(rawValue: 1 << 1)
    }

    private let options: Options

    /// - Parameter including: Identifying details to add. None by default.
    public init(including options: Options = []) {
        self.options = options
    }

    @MainActor public func collect() -> BugReporter {
        let device = UIDevice.current
        let anonymous = BugReporter.anonymous
        return BugReporter(
            id: options.contains(.identifierForVendor)
                ? device.identifierForVendor?.uuidString ?? anonymous.id
                : anonymous.id,
            displayName: options.contains(.deviceName) ? device.name : anonymous.displayName,
            reachoutIdentifier: nil
        )
    }
}

/// Supplies the reporter from your app, such as the signed-in user:
///
/// ```swift
/// BugReporterProvider {
///     BugReporter(id: session.userID, displayName: session.name, reachoutIdentifier: session.email)
/// }
/// ```
///
/// The closure runs on the main actor each time a report is drafted.
public struct BugReporterProvider: BugReporterProviding {
    private let reporter: @MainActor @Sendable () -> BugReporter

    public init(_ reporter: @escaping @MainActor @Sendable () -> BugReporter) {
        self.reporter = reporter
    }

    @MainActor public func collect() -> BugReporter {
        reporter()
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
