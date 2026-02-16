import Foundation

/// Orchestrator for gathering information from all relevant providers
/// and finally submit the information
public final class Bugger: Sendable {
    private let deviceInfoProvider: DeviceInfoProviding
    private let screenshotProvider: ScreenshotProviding?
    private let submitter: ReportSubmitting

    static var test: Self {
        return Self(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            submitter: NoopReportSubmitter()
        )
    }
    
    static var onDevice: Self {
        return Self(
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            submitter: NoopReportSubmitter()
        )
    }
    
    public init(
        deviceInfoProvider: DeviceInfoProviding,
        screenshotProvider: ScreenshotProviding?,
        submitter: ReportSubmitting
    ) {
        self.deviceInfoProvider = deviceInfoProvider
        self.screenshotProvider = screenshotProvider
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

    public func submit(_ report: BugReport) async throws {
        try await submitter.submit(report)
    }
}
