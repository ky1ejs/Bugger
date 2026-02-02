//
//  Report.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import BuggerImgurStore

struct Report: Sendable {
    let githubUsername: String?
    let summary: String
    let body: String
    let screenshot: UIImage
    let topViewController: String
    let deviceMeta: [KeyValue]

    @MainActor
    init(githubUsername: String?, summary: String?, body: String?, appWindow: UIWindow, screenshot: UIImage) throws {
        let summaryCount = summary?.count ?? 0
        let bodyCount = body?.count ?? 0

        guard let summary = summary, let body = body,
            summaryCount > 0, bodyCount > 0 else {
            switch (summaryCount, bodyCount) {
            case (0, 0):    throw ReportValidationError.summaryAndbodyLength
            case (0, _):    throw ReportValidationError.summaryLength
            default:        throw ReportValidationError.bodyLength
            }
        }

        self.githubUsername = githubUsername
        self.summary = summary
        self.body = body
        self.screenshot = screenshot
        self.topViewController = appWindow.topViewController()
        self.deviceMeta = Device.meta
    }

    func formattedBody(with imageURL: URL) -> String {
        let itemsPerRow = 3
        var tableData = [[KeyValue]]()

        var meta = deviceMeta
        meta.append((key: "Top View Controller", value: topViewController))

        var row = [KeyValue]()
        for i in 0..<meta.count {
            let cell = meta[i]
            row.append(cell)

            if (i + 1) % itemsPerRow == 0 || i == meta.count - 1 {
                tableData.append(row)
                row = [KeyValue]()
            }
        }

        var body = """
        Reporter: @\(githubUsername ?? "")

        <table>
        """

        for row in tableData {
            body += """

            <tr>
            """
            for cell in row {
                body += """

                <th>\(cell.key)</th><td>\(cell.value)</td>
                """
            }

            body += """

            </tr>
            """
        }

        body += """
        </table>

        ## Description
        \(self.body)

        ## Screenshot(s)
        ![](\(imageURL.absoluteString))
        """

        return body
    }

    func send(with config: GitHubConfig) async throws -> URL {
        let imageURL = try await uploadImage(config: config)
        return try await createGitHubIssue(config: config, imageURL: imageURL)
    }

    private func uploadImage(config: GitHubConfig) async throws -> URL {
        let store = BuggerImgurStore(clientID: config.imgurClientId)
        return try await store.uploadImage(image: screenshot)
    }

    private func createGitHubIssue(config: GitHubConfig, imageURL: URL) async throws -> URL {
        let issueData = ["title": summary, "body": formattedBody(with: imageURL)]
        let jsonData = try JSONSerialization.data(withJSONObject: issueData, options: [])

        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(config.owner)/\(config.repo)/issues")!)
        request.httpMethod = "POST"
        request.addValue("token \(config.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let issueUrlString = json["html_url"] as? String,
              let issueUrl = URL(string: issueUrlString) else {
            throw NetworkError.responseParseError
        }

        return issueUrl
    }
}

enum ReportValidationError: Error, Sendable {
    case summaryLength
    case bodyLength
    case summaryAndbodyLength
}

extension ReportValidationError: UserError {
    var userErrorMessage: String {
        switch self {
        case .summaryLength: return "Summary required"
        case .bodyLength: return "Description required"
        case .summaryAndbodyLength: return "Summary and Description required"
        }
    }
}
