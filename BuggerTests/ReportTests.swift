//
//  ReportTests.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 26/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import XCTest
@testable import Bugger

class ReportTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let report = try! Report(githubUsername: "test", summary: "test", body: "test", appWindow: UIWindow(), screenshot: UIImage())
        print(report.formattedBody(with: URL(string: "https://test.com")!))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
