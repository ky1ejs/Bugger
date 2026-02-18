import Foundation

/// Orchestrator for gathering information from all relevant providers
/// and finally submit the information
public final class Bugger: Sendable {
    private let bugReporterProvider: BugReporterProviding
    private let deviceInfoProvider: DeviceInfoProviding
    private let screenshotProvider: ScreenshotProviding?
    private let categoriesProvider: CategoriesProviding?
    private let packer: BugReportPacking
    private let submitter: ReportSubmitting
    
    public static var onDevice: Self {
        return Self(
            bugReporterProvider: DefaultBugReporterProvider(),
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            categoriesProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
    
    public init(
        bugReporterProvider: BugReporterProviding = DefaultBugReporterProvider(),
        deviceInfoProvider: DeviceInfoProviding,
        screenshotProvider: ScreenshotProviding?,
        categoriesProvider: CategoriesProviding? = nil,
        packer: BugReportPacking,
        submitter: ReportSubmitting
    ) {
        self.bugReporterProvider = bugReporterProvider
        self.deviceInfoProvider = deviceInfoProvider
        self.screenshotProvider = screenshotProvider
        self.categoriesProvider = categoriesProvider
        self.packer = packer
        self.submitter = submitter
    }

    public func draftReport(
        description: String,
        attachments: [BugReportAttachment] = [],
        categories: [BugReportCategory]? = nil
    ) async throws -> BugReport {
        let reporter = await bugReporterProvider.collect()
        let deviceInfo = await deviceInfoProvider.collect()
        let capturedAttachments: [BugReportAttachment]
        let selectedCategories: [BugReportCategory]

        if let screenshotProvider {
            capturedAttachments = try await screenshotProvider.capture()
        } else {
            capturedAttachments = []
        }

        if let categories {
            selectedCategories = categories
        } else if let categoriesProvider {
            selectedCategories = try await categoriesProvider.fetchCategories()
        } else {
            selectedCategories = []
        }

        let allAttachments = attachments + capturedAttachments
        return BugReport(
            description: description,
            reporter: reporter,
            deviceInfo: deviceInfo,
            attachments: allAttachments,
            categories: selectedCategories
        )
    }

    public func availableCategories() async throws -> [BugReportCategory] {
        guard let categoriesProvider else {
            return []
        }
        return try await categoriesProvider.fetchCategories()
    }

    @discardableResult
    public func submit(_ report: BugReport) async throws -> BugReportPackage {
        let package = try await packer.pack(report)
        try await submitter.submit(package)
        return package
    }
}
