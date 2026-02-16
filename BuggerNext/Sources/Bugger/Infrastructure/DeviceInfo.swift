import Foundation

public struct DeviceInfo: Codable, Sendable {
    public let systemName: String
    public let systemVersion: String
    public let model: String
    public let localizedModel: String
    public let identifierForVendor: String?

    public init(
        systemName: String,
        systemVersion: String,
        model: String,
        localizedModel: String,
        identifierForVendor: String?
    ) {
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.model = model
        self.localizedModel = localizedModel
        self.identifierForVendor = identifierForVendor
    }
}
