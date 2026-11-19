import Foundation

/// Describes the device and app a report came from.
public struct DeviceInfo: Codable, Sendable {
    public let systemName: String
    public let systemVersion: String
    public let model: String
    public let localizedModel: String
    public let identifierForVendor: String?
    /// The app's version, `CFBundleShortVersionString`, e.g. "3.2".
    public let appVersion: String?
    /// The app's build number, `CFBundleVersion`, e.g. "412".
    public let appBuild: String?

    public init(
        systemName: String,
        systemVersion: String,
        model: String,
        localizedModel: String,
        identifierForVendor: String?,
        appVersion: String? = nil,
        appBuild: String? = nil
    ) {
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.model = model
        self.localizedModel = localizedModel
        self.identifierForVendor = identifierForVendor
        self.appVersion = appVersion
        self.appBuild = appBuild
    }
}
