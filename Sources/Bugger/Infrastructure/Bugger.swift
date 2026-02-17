import Foundation

/// Orchestrator for gathering information from all relevant providers
/// and finally submit the information
public final class Bugger: Sendable {
    private let deviceInfoProvider: DeviceInfoProviding
    private let screenshotProvider: ScreenshotProviding?
    private let packer: BugReportPacking
    private let submitter: ReportSubmitting
    
    public static var onDevice: Self {
        return Self(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
    
    public init(
        deviceInfoProvider: DeviceInfoProviding,
        screenshotProvider: ScreenshotProviding?,
        packer: BugReportPacking,
        submitter: ReportSubmitting
    ) {
        self.deviceInfoProvider = deviceInfoProvider
        self.screenshotProvider = screenshotProvider
        self.packer = packer
        self.submitter = submitter
    }

    public func draftReport(description: String, screenshots: [Data] = []) async throws -> BugReport {
        let deviceInfo = await deviceInfoProvider.collect()
        let capturedScreenshots: [Data]

        if let screenshotProvider {
            capturedScreenshots = try await screenshotProvider.capture()
        } else {
            capturedScreenshots = []
        }

        let allScreenshots = screenshots + capturedScreenshots
        return BugReport(
            description: description,
            deviceInfo: deviceInfo,
            screenshotData: allScreenshots
        )
    }

    @discardableResult
    public func submit(_ report: BugReport) async throws -> BugReportPackage {
        let package = try await packer.pack(report)
        try await submitter.submit(package)
        return package
    }
}

extension Bugger {
    public static var preview: Self {
        return Self(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
}
