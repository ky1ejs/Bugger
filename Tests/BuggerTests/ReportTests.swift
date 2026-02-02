//
//  ReportTests.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 26/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import XCTest
@testable import Bugger
@testable import BuggerGitHub

@MainActor
class ReportTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        let report = try! Report(githubUsername: "test", summary: "test", body: "test", appWindow: UIWindow(), screenshot: UIImage())
        print(report.formattedBody(with: URL(string: "https://test.com")!))
    }

    func testPerformanceExample() {
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
