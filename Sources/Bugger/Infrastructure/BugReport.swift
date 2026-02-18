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
    public var reporter: BugReporter
    public var deviceInfo: DeviceInfo
    public var attachments: [BugReportAttachment]
    public var categories: [BugReportCategory]

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case description
        case reporter
        case deviceInfo
        case attachments
        case categories
    }

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        description: String,
        reporter: BugReporter = .unknown,
        deviceInfo: DeviceInfo,
        attachments: [BugReportAttachment] = [],
        categories: [BugReportCategory] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.description = description
        self.reporter = reporter
        self.deviceInfo = deviceInfo
        self.attachments = attachments
        self.categories = categories
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        description = try container.decode(String.self, forKey: .description)
        reporter = try container.decode(BugReporter.self, forKey: .reporter)
        deviceInfo = try container.decode(DeviceInfo.self, forKey: .deviceInfo)
        attachments = try container.decode([BugReportAttachment].self, forKey: .attachments)
        categories = try container.decodeIfPresent([BugReportCategory].self, forKey: .categories) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(description, forKey: .description)
        try container.encode(reporter, forKey: .reporter)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(categories, forKey: .categories)
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
        reporter: BugReporter = .unknown,
        deviceInfo: DeviceInfo,
        screenshotData: [Data],
        screenshotMimeType: String
    ) {
        self.init(
            id: id,
            createdAt: createdAt,
            description: description,
            reporter: reporter,
            deviceInfo: deviceInfo,
            attachments: screenshotData.map {
                BugReportAttachment.fromRawData($0, mimeType: screenshotMimeType)
            }
        )
    }
}
