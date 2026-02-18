import Foundation

public struct BugReporter: Codable, Sendable {
    public var id: String
    public var displayName: String
    public var reachoutIdentifier: String?

    public init(
        id: String,
        displayName: String,
        reachoutIdentifier: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.reachoutIdentifier = reachoutIdentifier
    }

    public static var unknown: Self {
        Self(
            id: "unknown-reporter",
            displayName: "Unknown Reporter",
            reachoutIdentifier: nil
        )
    }

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
