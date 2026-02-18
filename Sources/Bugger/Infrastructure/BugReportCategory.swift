import Foundation

public struct BugReportCategory: Codable, Sendable, Hashable {
    public let identifier: String
    public let displayName: String

    public init(identifier: String, displayName: String) {
        self.identifier = identifier
        self.displayName = displayName
    }
}
