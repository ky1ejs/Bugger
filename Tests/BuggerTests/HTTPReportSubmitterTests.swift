import XCTest
@testable import Bugger

final class HTTPReportSubmitterTests: XCTestCase {
    private let url = URL(string: "https://reports.example.com/bugs")!
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HTTPReportSubmitterTests-\(UUID().uuidString)", isDirectory: true)
        StubProtocol.reset()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        StubProtocol.reset()
    }

    func testPostsReportAndAttachmentsAsMultipart() async throws {
        let package = try await makePackage(attachments: [
            BugReportAttachment(data: Data("PNGDATA".utf8), mimeType: "image/png", filename: "screenshot.png"),
            BugReportAttachment(data: Data("second".utf8), mimeType: "image/png", filename: "screenshot.png"),
        ])
        StubProtocol.respond(status: 201)

        try await makeSubmitter(headers: ["Authorization": "Bearer abc"]).submit(package)

        let request = try XCTUnwrap(StubProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc")
        let contentType = try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type"))
        let boundary = try XCTUnwrap(contentType.components(separatedBy: "boundary=").last)
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))

        let parts = try parseMultipart(XCTUnwrap(StubProtocol.lastBody), boundary: boundary)
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0].name, "report")
        XCTAssertEqual(parts[0].contentType, "application/json")
        XCTAssertEqual(parts[0].body, package.payload)
        XCTAssertEqual(parts[1].name, "attachment")
        XCTAssertEqual(parts[1].filename, "screenshot.png")
        XCTAssertEqual(parts[1].contentType, "image/png")
        XCTAssertEqual(parts[1].body, Data("PNGDATA".utf8))
        XCTAssertEqual(parts[2].filename, "screenshot-2.png")
        XCTAssertEqual(parts[2].body, Data("second".utf8))
    }

    func testFilenamesInPayloadMatchUploadedParts() async throws {
        let package = try await makePackage(attachments: [
            BugReportAttachment(data: Data([1]), mimeType: "image/png", filename: "a.png"),
        ])
        StubProtocol.respond(status: 200)

        try await makeSubmitter().submit(package)

        let payload = try JSONDecoder.iso8601.decode(BugReportJSONPayload.self, from: package.payload)
        let contentType = try XCTUnwrap(StubProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type"))
        let boundary = try XCTUnwrap(contentType.components(separatedBy: "boundary=").last)
        let parts = try parseMultipart(XCTUnwrap(StubProtocol.lastBody), boundary: boundary)
        XCTAssertEqual(payload.attachments.map(\.filename), parts.dropFirst().map(\.filename))
    }

    func testNon2xxThrowsWithStatusAndBody() async throws {
        let package = try await makePackage(attachments: [])
        StubProtocol.respond(status: 503, body: Data("down".utf8))

        do {
            try await makeSubmitter().submit(package)
            XCTFail("Expected an error")
        } catch let error as HTTPReportSubmitter.Error {
            XCTAssertEqual(error, .unexpectedStatus(503, body: Data("down".utf8)))
        }
    }

    func testTemporaryFilesAreDeletedAfterSuccessAndFailure() async throws {
        for status in [200, 500] {
            let package = try await makePackage(attachments: [
                BugReportAttachment(data: Data([1]), mimeType: "image/png", filename: "a.png"),
            ])
            let file = try XCTUnwrap(package.attachments.first?.fileURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
            StubProtocol.respond(status: status)

            try? await makeSubmitter().submit(package)

            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path), "status \(status)")
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path),
                "The empty report folder is removed too (status \(status))"
            )
        }
    }

    func testHeaderProviderFailureSendsNothing() async throws {
        struct TokenUnavailable: Error {}
        let package = try await makePackage(attachments: [])
        StubProtocol.respond(status: 200)
        let submitter = HTTPReportSubmitter(url: url, session: makeSession(), headers: { throw TokenUnavailable() })

        do {
            try await submitter.submit(package)
            XCTFail("Expected an error")
        } catch is TokenUnavailable {}

        XCTAssertNil(StubProtocol.lastRequest)
    }

    func testHeaderProviderIsReadForEachSubmit() async throws {
        let counter = Counter()
        let submitter = HTTPReportSubmitter(url: url, session: makeSession(), headers: {
            ["Authorization": "Bearer \(await counter.next())"]
        })
        StubProtocol.respond(status: 200)

        try await submitter.submit(try await makePackage(attachments: []))
        try await submitter.submit(try await makePackage(attachments: []))

        XCTAssertEqual(StubProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer 2")
    }

    func testQuotesAndLineBreaksInFilenamesCantBreakTheHeader() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data([1]).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let package = BugReportPackage(
            reportID: UUID(),
            payload: Data("{}".utf8),
            attachments: [
                BugReportAttachmentFile(filename: "a\"b\r\nX-Injected: 1.png", fileURL: file, mimeType: "image/png"),
            ]
        )
        let bodyURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        try HTTPReportSubmitter.writeMultipartBody(for: package, boundary: "B", to: bodyURL)

        let body = try String(contentsOf: bodyURL, encoding: .utf8)
        XCTAssertTrue(body.contains("filename=\"a\\\"b  X-Injected: 1.png\""))
        XCTAssertFalse(body.contains("\r\nX-Injected"))
    }

    /// Uploads a real report to `BUGGER_LIVE_SUBMIT_URL`, if set, to check a server accepts the format.
    /// Skipped otherwise. Run with: `TEST_RUNNER_BUGGER_LIVE_SUBMIT_URL=http://... xcodebuild test ...`
    func testLiveServerIfConfigured() async throws {
        guard
            let value = ProcessInfo.processInfo.environment["BUGGER_LIVE_SUBMIT_URL"],
            let liveURL = URL(string: value)
        else {
            throw XCTSkip("Set BUGGER_LIVE_SUBMIT_URL to run against a server")
        }
        let package = try await makePackage(attachments: [
            BugReportAttachment(data: Data("first".utf8), mimeType: "image/png", filename: "screenshot.png"),
            BugReportAttachment(data: Data("second".utf8), mimeType: "image/png", filename: "screenshot.png"),
        ])

        try await HTTPReportSubmitter(url: liveURL, headers: ["Authorization": "Bearer live-test"]).submit(package)
    }

    // MARK: - Helpers

    private func makeSubmitter(headers: [String: String] = [:]) -> HTTPReportSubmitter {
        HTTPReportSubmitter(url: url, session: makeSession(), headers: headers)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makePackage(attachments: [BugReportAttachment]) async throws -> BugReportPackage {
        let report = BugReport(
            description: "It froze",
            deviceInfo: DeviceInfo(
                systemName: "iOS",
                systemVersion: "26.0",
                model: "iPhone",
                localizedModel: "iPhone",
                identifierForVendor: nil
            ),
            attachments: attachments
        )
        return try await JSONReportPacker(destinationDirectory: directory).pack(report)
    }

    private struct Part {
        let name: String?
        let filename: String?
        let contentType: String?
        let body: Data
    }

    /// A small multipart parser, enough to check what the submitter wrote.
    private func parseMultipart(_ data: Data, boundary: String) throws -> [Part] {
        let delimiter = Data("--\(boundary)".utf8)
        var parts: [Part] = []
        var searchStart = data.startIndex
        var ranges: [Range<Data.Index>] = []
        while let range = data.range(of: delimiter, in: searchStart..<data.endIndex) {
            ranges.append(range)
            searchStart = range.upperBound
        }
        for (current, next) in zip(ranges, ranges.dropFirst()) {
            // Skip the CRLF after the delimiter, and drop the CRLF before the next one.
            let section = data[(current.upperBound + 2)..<(next.lowerBound - 2)]
            let separator = Data("\r\n\r\n".utf8)
            let headerEnd = try XCTUnwrap(section.range(of: separator))
            let headers = String(decoding: section[section.startIndex..<headerEnd.lowerBound], as: UTF8.self)
            let body = Data(section[headerEnd.upperBound..<section.endIndex])
            func value(_ key: String) -> String? {
                guard let range = headers.range(of: "\(key)=\"") else { return nil }
                return String(headers[range.upperBound...].prefix { $0 != "\"" })
            }
            let contentType = headers.components(separatedBy: "\r\n")
                .first { $0.hasPrefix("Content-Type: ") }?
                .replacingOccurrences(of: "Content-Type: ", with: "")
            parts.append(Part(name: value("name"), filename: value("filename"), contentType: contentType, body: body))
        }
        return parts
    }
}

private actor Counter {
    private var value = 0

    func next() -> Int {
        value += 1
        return value
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

/// Answers every request with a canned response and records the request and its body.
private final class StubProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var responseBody = Data()
    nonisolated(unsafe) private(set) static var lastRequest: URLRequest?
    nonisolated(unsafe) private(set) static var lastBody: Data?

    static func respond(status: Int, body: Data = Data()) {
        lock.withLock {
            self.status = status
            self.responseBody = body
        }
    }

    static func reset() {
        lock.withLock {
            status = 200
            responseBody = Data()
            lastRequest = nil
            lastBody = nil
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.readAll)
        let (status, responseBody) = Self.lock.withLock {
            Self.lastRequest = request
            Self.lastBody = body
            return (Self.status, Self.responseBody)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
