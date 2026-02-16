import Foundation
import UIKit

public protocol TextInfoProviding: Sendable {
    func collect() -> String
}

public protocol DeviceInfoProviding: Sendable {
    @MainActor
    func collect() -> DeviceInfo
}

public protocol ScreenshotProviding: Sendable {
    func capture() async throws -> [Data]
}

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

    public func capture() async throws -> [Data] {
        throw BuggerError.screenshotUnavailable
    }
}
