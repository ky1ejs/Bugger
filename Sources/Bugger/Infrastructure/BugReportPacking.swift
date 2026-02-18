import Foundation

/// File-backed representation of an attachment during report submission.
///
/// Lifecycle:
/// 1. A `BugReportAttachment` starts as in-memory data on the draft report.
/// 2. `JSONReportPacker.pack(_:)` writes that data to a temporary file and creates this value.
/// 3. The value is returned in `BugReportPackage.attachments` for `ReportSubmitting` to read/upload.
/// 4. The file is temporary; Bugger does not delete it automatically, so the consumer should clean it up.
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
    public let reporter: BugReporter
    public let deviceInfo: DeviceInfo
    public let categories: [BugReportCategory]
    public let attachments: [BugReportAttachmentReference]

    public init(
        id: UUID,
        createdAt: Date,
        description: String,
        reporter: BugReporter,
        deviceInfo: DeviceInfo,
        categories: [BugReportCategory],
        attachments: [BugReportAttachmentReference]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.description = description
        self.reporter = reporter
        self.deviceInfo = deviceInfo
        self.categories = categories
        self.attachments = attachments
    }
}

// The in-memory representation of a bug report
// to be sent off to the bug report service.
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

// Defines the responsibilities for packaging a BugReport
// information to a `BugReportPackage`, the representation
// of a bug report, ready to be sent out to a server.
public protocol BugReportPacking: Sendable {
    func pack(_ report: BugReport) async throws -> BugReportPackage
}

public struct JSONReportPacker: BugReportPacking {
    private let destinationDirectory: URL

    public init(destinationDirectory: URL = FileManager.default.temporaryDirectory) {
        self.destinationDirectory = destinationDirectory
    }

    public func pack(_ report: BugReport) async throws -> BugReportPackage {
        let fileManager = FileManager.default
        let rootFolder = destinationDirectory.appendingPathComponent("BuggerAttachments", isDirectory: true)
        let reportFolder = rootFolder.appendingPathComponent(report.id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: reportFolder, withIntermediateDirectories: true, attributes: nil)

        var attachmentFiles: [BugReportAttachmentFile] = []
        var attachmentReferences: [BugReportAttachmentReference] = []

        for (index, payloadAttachment) in report.attachments.enumerated() {
            let filename = Self.resolveFilename(for: payloadAttachment, index: index)
            let fileURL = reportFolder.appendingPathComponent(filename)
            try payloadAttachment.data.write(to: fileURL, options: [.atomic])

            let attachment = BugReportAttachmentFile(
                id: payloadAttachment.id,
                filename: filename,
                fileURL: fileURL,
                mimeType: payloadAttachment.mimeType
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
            reporter: report.reporter,
            deviceInfo: report.deviceInfo,
            categories: report.categories,
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

    private static func resolveFilename(for attachment: BugReportAttachment, index: Int) -> String {
        if let provided = sanitizeFilename(attachment.filename), !provided.isEmpty {
            return provided
        }

        let fileExtension = defaultFileExtension(for: attachment.mimeType)
        return "attachment-\(index + 1).\(fileExtension)"
    }

    private static func sanitizeFilename(_ filename: String?) -> String? {
        guard let filename else { return nil }
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    private static func defaultFileExtension(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/png":
            return "png"
        case "image/jpeg":
            return "jpg"
        case "image/heic":
            return "heic"
        case "image/gif":
            return "gif"
        case "application/pdf":
            return "pdf"
        case "text/plain":
            return "txt"
        default:
            return "bin"
        }
    }
}
