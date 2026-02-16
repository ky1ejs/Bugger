import Foundation

public struct BugReportAttachmentFile: Sendable, Identifiable {
    public let id: UUID
    public let filename: String
    public let fileURL: URL
    public let mimeType: String

    public init(id: UUID = UUID(), filename: String, fileURL: URL, mimeType: String) {
        self.id = id
        self.filename = filename
        self.fileURL = fileURL
        self.mimeType = mimeType
    }
}

public struct BugReportAttachmentReference: Codable, Sendable, Identifiable {
    public let id: UUID
    public let filename: String
    public let temporaryPath: String
    public let mimeType: String

    public init(id: UUID, filename: String, temporaryPath: String, mimeType: String) {
        self.id = id
        self.filename = filename
        self.temporaryPath = temporaryPath
        self.mimeType = mimeType
    }
}

public struct BugReportJSONPayload: Codable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public let description: String
    public let deviceInfo: DeviceInfo
    public let attachments: [BugReportAttachmentReference]

    public init(
        id: UUID,
        createdAt: Date,
        description: String,
        deviceInfo: DeviceInfo,
        attachments: [BugReportAttachmentReference]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.description = description
        self.deviceInfo = deviceInfo
        self.attachments = attachments
    }
}

public struct BugReportPackage: Sendable {
    public let reportID: UUID
    public let payload: Data
    public let attachments: [BugReportAttachmentFile]

    public init(reportID: UUID, payload: Data, attachments: [BugReportAttachmentFile]) {
        self.reportID = reportID
        self.payload = payload
        self.attachments = attachments
    }
}

public protocol BugReportPacking: Sendable {
    func pack(_ report: BugReport) async throws -> BugReportPackage
}

public struct JSONReportPacker: BugReportPacking {
    private let baseDirectory: URL

    public init(baseDirectory: URL = FileManager.default.temporaryDirectory) {
        self.baseDirectory = baseDirectory
    }

    public func pack(_ report: BugReport) async throws -> BugReportPackage {
        let fileManager = FileManager.default
        let rootFolder = baseDirectory.appendingPathComponent("BuggerAttachments", isDirectory: true)
        let reportFolder = rootFolder.appendingPathComponent(report.id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)

        var attachmentFiles: [BugReportAttachmentFile] = []
        var attachmentReferences: [BugReportAttachmentReference] = []

        for (index, data) in report.screenshotData.enumerated() {
            let filename = "screenshot-\(index + 1).png"
            let fileURL = reportFolder.appendingPathComponent(filename)
            try data.write(to: fileURL, options: [.atomic])

            let attachment = BugReportAttachmentFile(
                filename: filename,
                fileURL: fileURL,
                mimeType: "image/png"
            )
            attachmentFiles.append(attachment)
            attachmentReferences.append(
                BugReportAttachmentReference(
                    id: attachment.id,
                    filename: filename,
                    temporaryPath: fileURL.path,
                    mimeType: attachment.mimeType
                )
            )
        }

        let payloadModel = BugReportJSONPayload(
            id: report.id,
            createdAt: report.createdAt,
            description: report.description,
            deviceInfo: report.deviceInfo,
            attachments: attachmentReferences
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let payload = try encoder.encode(payloadModel)

        return BugReportPackage(
            reportID: report.id,
            payload: payload,
            attachments: attachmentFiles
        )
    }
}
