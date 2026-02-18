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

import UIKit
extension BuggerScreenshotSource {
    static var previewMock: BuggerScreenshotSource {
        BuggerScreenshotSource(
            mode: .manual,
            addTitle: "Add Sample",
            loadFromPicker: { _ in [] },
            loadFromManual: {
                await MainActor.run {
                    [
                        makeSample(color: .systemBlue),
                        makeSample(color: .systemGreen),
                        makeSample(color: .systemOrange)
                    ].compactMap { data in
                        guard let data else { return nil }
                        return BugReportAttachment(data: data, mimeType: "image/png")
                    }
                }
            }
        )
    }

    private static func makeSample(color: UIColor) -> Data? {
        let size = CGSize(width: 300, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()
    }
}

#endif
