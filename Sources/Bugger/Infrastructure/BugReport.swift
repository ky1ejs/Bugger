import Foundation

public struct BugReportAttachment: Codable, Sendable, Identifiable {
    public let id: UUID
    public let data: Data
    public let mimeType: String
    public let filename: String?

    public init(
        id: UUID = UUID(),
        data: Data,
        mimeType: String,
        filename: String? = nil
    ) {
        self.id = id
        self.data = data
        self.mimeType = mimeType
        self.filename = filename
    }

    public static func fromRawData(
        _ data: Data,
        mimeType: String,
        filename: String? = nil
    ) -> Self {
        Self(
            data: data,
            mimeType: mimeType,
            filename: filename
        )
    }
}

public struct BugReport: Codable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public var description: String
    public var deviceInfo: DeviceInfo
    public var attachments: [BugReportAttachment]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        description: String,
        deviceInfo: DeviceInfo,
        attachments: [BugReportAttachment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.description = description
        self.deviceInfo = deviceInfo
        self.attachments = attachments
    }

    @available(*, deprecated, message: "Use attachments instead.")
    public var screenshotData: [Data] {
        attachments.map(\.data)
    }

    @available(*, deprecated, message: "Use init(..., attachments:) instead.")
    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        description: String,
        deviceInfo: DeviceInfo,
        screenshotData: [Data],
        screenshotMimeType: String
    ) {
        self.init(
            id: id,
            createdAt: createdAt,
            description: description,
            deviceInfo: deviceInfo,
            attachments: screenshotData.map {
                BugReportAttachment.fromRawData($0, mimeType: screenshotMimeType)
            }
        )
    }
}
