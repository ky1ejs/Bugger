//
//  Mocks.swift
//  Bugger
//
//  Created by Fabio Milano on 2/18/26.
//

#if DEBUG && canImport(SwiftUI)

extension Bugger {
    public static var preview: Self {
        return Self(
            bugReporterProvider: DefaultBugReporterProvider(),
            deviceInfoProvider: DefaultDeviceInfoProvider(),
            screenshotProvider: nil,
            categoriesProvider: nil,
            packer: JSONReportPacker(),
            submitter: NoopReportSubmitter()
        )
    }
}

extension BugReporter {
    public static func preview(
        id: String = "preview-reporter",
        displayName: String = "Preview Reporter",
        reachoutIdentifier: String? = "preview@bugger.local"
    ) -> Self {
        Self(
            id: id,
            displayName: displayName,
            reachoutIdentifier: reachoutIdentifier
        )
    }
}

#endif
