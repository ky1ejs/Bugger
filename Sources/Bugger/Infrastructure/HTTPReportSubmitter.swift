import Foundation

/// Sends each report to your server as one `multipart/form-data` POST.
///
/// The request has one part named `report`, holding the JSON payload (`application/json`),
/// then one part named `attachment` per attachment file, with its filename and MIME type.
/// The payload's `attachments` list names each file by `filename`, which is unique within a
/// report. See "Sending reports to your server" in the README for the full format.
///
/// Any 2xx response counts as success. Anything else throws `HTTPReportSubmitter.Error`,
/// and the reporter sees "Submit failed" and can try again.
///
/// After each attempt, successful or not, the submitter deletes the package's temporary
/// attachment files. A retry packs the report again, so they are not needed after.
public struct HTTPReportSubmitter: ReportSubmitting {
    public enum Error: Swift.Error, Equatable {
        /// The server answered with a status outside 200-299. `body` is what it sent back.
        case unexpectedStatus(Int, body: Data)
        /// The response wasn't an HTTP response.
        case invalidResponse
    }

    private let url: URL
    private let session: URLSession
    private let headers: @Sendable () async throws -> [String: String]

    /// - Parameters:
    ///   - url: Where to POST reports.
    ///   - session: The URL session to upload with.
    ///   - headers: Extra request headers, read before each upload. Use it for an auth token that
    ///     can change, e.g. `{ ["Authorization": "Bearer \(try await auth.token())"] }`. If it
    ///     throws, nothing is sent and the error is the submit's error.
    public init(
        url: URL,
        session: URLSession = .shared,
        headers: @escaping @Sendable () async throws -> [String: String] = { [:] }
    ) {
        self.url = url
        self.session = session
        self.headers = headers
    }

    /// Sends the same headers with every report.
    public init(url: URL, session: URLSession = .shared, headers: [String: String]) {
        self.init(url: url, session: session, headers: { headers })
    }

    public func submit(_ package: BugReportPackage) async throws {
        defer { Self.removeTemporaryFiles(of: package) }

        let extraHeaders = try await headers()
        let boundary = "Bugger-\(UUID().uuidString)"
        let bodyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuggerUpload-\(package.reportID.uuidString)-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: bodyURL) }
        try Self.writeMultipartBody(for: package, boundary: boundary, to: bodyURL)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        for (name, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.upload(for: request, fromFile: bodyURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw Error.unexpectedStatus(httpResponse.statusCode, body: data)
        }
    }

    /// Writes the multipart body to `fileURL`, copying attachment files in chunks
    /// so large screenshots aren't all held in memory at once.
    static func writeMultipartBody(for package: BugReportPackage, boundary: String, to fileURL: URL) throws {
        guard FileManager.default.createFile(atPath: fileURL.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: fileURL.path])
        }
        let output = try FileHandle(forWritingTo: fileURL)
        defer { try? output.close() }

        func write(_ string: String) throws {
            try output.write(contentsOf: Data(string.utf8))
        }

        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"report\"; filename=\"report.json\"\r\n")
        try write("Content-Type: application/json\r\n\r\n")
        try output.write(contentsOf: package.payload)
        try write("\r\n")

        for attachment in package.attachments {
            try write("--\(boundary)\r\n")
            try write(
                "Content-Disposition: form-data; name=\"attachment\"; filename=\"\(quoted(attachment.filename))\"\r\n"
            )
            try write("Content-Type: \(headerSafe(attachment.mimeType))\r\n\r\n")
            let input = try FileHandle(forReadingFrom: attachment.fileURL)
            defer { try? input.close() }
            while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
                try output.write(contentsOf: chunk)
            }
            try write("\r\n")
        }

        try write("--\(boundary)--\r\n")
    }

    /// Escapes a value for a quoted header parameter.
    private static func quoted(_ value: String) -> String {
        headerSafe(value)
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Removes line breaks, which would end the header early.
    private static func headerSafe(_ value: String) -> String {
        value.components(separatedBy: .newlines).joined(separator: " ")
    }

    /// Deletes the package's attachment files, and their folder once it's empty.
    static func removeTemporaryFiles(of package: BugReportPackage) {
        let fileManager = FileManager.default
        var folders: Set<URL> = []
        for attachment in package.attachments {
            try? fileManager.removeItem(at: attachment.fileURL)
            folders.insert(attachment.fileURL.deletingLastPathComponent())
        }
        for folder in folders where (try? fileManager.contentsOfDirectory(atPath: folder.path))?.isEmpty == true {
            try? fileManager.removeItem(at: folder)
        }
    }
}
