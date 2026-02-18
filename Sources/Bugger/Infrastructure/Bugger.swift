import Foundation

/// Orchestrator for gathering information from all relevant providers
/// and finally submit the information
public final class Bugger: Sendable {
    private let bugReporterProvider: BugReporterProviding
    private let deviceInfoProvider: DeviceInfoProviding
    private let screenshotProvider: ScreenshotProviding?
    private let packer: BugReportPacking
    private let submitter: ReportSubmitting
    
    public static var onDevice: Self {
        return Self(
            bugReporterProvider: DefaultBugReporterProvider(),
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
    
    public init(
        bugReporterProvider: BugReporterProviding = DefaultBugReporterProvider(),
        deviceInfoProvider: DeviceInfoProviding,
        screenshotProvider: ScreenshotProviding?,
        packer: BugReportPacking,
        submitter: ReportSubmitting
    ) {
        self.bugReporterProvider = bugReporterProvider
        self.deviceInfoProvider = deviceInfoProvider
        self.screenshotProvider = screenshotProvider
        self.packer = packer
        self.submitter = submitter
    }

    public func draftReport(
        description: String,
        attachments: [BugReportAttachment] = []
    ) async throws -> BugReport {
        let reporter = await bugReporterProvider.collect()
        let deviceInfo = await deviceInfoProvider.collect()
        let capturedAttachments: [BugReportAttachment]

        if let screenshotProvider {
            capturedAttachments = try await screenshotProvider.capture()
        } else {
            capturedAttachments = []
        }

        let allAttachments = attachments + capturedAttachments
        return BugReport(
            description: description,
            reporter: reporter,
            deviceInfo: deviceInfo,
            attachments: allAttachments
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
            bugReporterProvider: DefaultBugReporterProvider(),
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
}
