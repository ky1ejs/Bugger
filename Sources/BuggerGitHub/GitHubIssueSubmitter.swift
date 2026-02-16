import Foundation
import Bugger

public struct GitHubIssueConfiguration: Sendable {
    public let owner: String
    public let repository: String
    public let token: String
    public let apiBaseURL: URL
    public let defaultLabels: [String]

    public init(
        owner: String,
        repository: String,
        token: String,
        apiBaseURL: URL = URL(string: "https://api.github.com")!,
        defaultLabels: [String] = []
    ) {
        self.owner = owner
        self.repository = repository
        self.token = token
        self.apiBaseURL = apiBaseURL
        self.defaultLabels = defaultLabels
    }
}

public struct GitHubIssueSubmitter: ReportSubmitting {
    public enum SubmitError: Error {
        case invalidResponse
        case requestFailed(statusCode: Int, message: String)
        case payloadDecodingFailed
    }

    private let configuration: GitHubIssueConfiguration

    public init(configuration: GitHubIssueConfiguration) {
        self.configuration = configuration
    }

    public func submit(_ package: BugReportPackage) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let payloadModel = try? decoder.decode(BugReportJSONPayload.self, from: package.payload) else {
            throw SubmitError.payloadDecodingFailed
        }

        let requestBody = IssueRequest(
            title: buildIssueTitle(from: payloadModel),
            body: buildIssueBody(from: payloadModel, payload: package.payload),
            labels: configuration.defaultLabels.isEmpty ? nil : configuration.defaultLabels
        )

        var request = URLRequest(url: issueURL())
        request.httpMethod = "POST"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubmitError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SubmitError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func issueURL() -> URL {
        configuration.apiBaseURL
            .appendingPathComponent("repos")
            .appendingPathComponent(configuration.owner)
            .appendingPathComponent(configuration.repository)
            .appendingPathComponent("issues")
    }

    private func buildIssueTitle(from payload: BugReportJSONPayload) -> String {
        let trimmed = payload.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Bug Report \(payload.id.uuidString.prefix(8))"
        }

        let firstLine = trimmed.split(whereSeparator: \.isNewline).first.map(String.init) ?? trimmed
        if firstLine.count <= 80 {
            return firstLine
        }

        let index = firstLine.index(firstLine.startIndex, offsetBy: 77)
        return "\(firstLine[..<index])..."
    }

    private func buildIssueBody(from payload: BugReportJSONPayload, payload data: Data) -> String {
        var lines: [String] = []
        lines.append("## Bug Report")
        lines.append("")
        lines.append("**Description**")
        lines.append(payload.description.isEmpty ? "_No description provided._" : payload.description)
        lines.append("")
        lines.append("**Created At**")
        lines.append(format(date: payload.createdAt))
        lines.append("")
        lines.append("**Device**")
        lines.append("- System: \(payload.deviceInfo.systemName) \(payload.deviceInfo.systemVersion)")
        lines.append("- Model: \(payload.deviceInfo.model)")
        lines.append("- Localized Model: \(payload.deviceInfo.localizedModel)")
        if let identifier = payload.deviceInfo.identifierForVendor {
            lines.append("- Identifier: \(identifier)")
        }

        if payload.attachments.isEmpty {
            lines.append("")
            lines.append("**Attachments**")
            lines.append("None")
        } else {
            lines.append("")
            lines.append("**Attachments (staged)**")
            for attachment in payload.attachments {
                lines.append("- \(attachment.filename) (temp: \(attachment.temporaryPath))")
            }
        }

        if let payloadString = String(data: data, encoding: .utf8) {
            lines.append("")
            lines.append("**Payload (JSON)**")
            lines.append("```json")
            lines.append(payloadString)
            lines.append("```")
        }

        return lines.joined(separator: "\n")
    }

    private func format(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private struct IssueRequest: Encodable {
        let title: String
        let body: String
        let labels: [String]?
    }
}
