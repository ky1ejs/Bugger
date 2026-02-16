import Foundation

public struct BugReport: Codable, Sendable, Identifiable {
    public let id: UUID
    public let createdAt: Date
    public var description: String
    public var deviceInfo: DeviceInfo
    public var screenshotData: [Data]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        description: String,
        deviceInfo: DeviceInfo,
        screenshotData: [Data] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.description = description
        self.deviceInfo = deviceInfo
        self.screenshotData = screenshotData
    }
}
