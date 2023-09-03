//
//  BuggerTests.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 18/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import XCTest
@testable import Bugger

private extension Bugger {
    static var isActive: Bool {
        if case .active = state { return true }
        return false
    }
    
    static var isWatching: Bool {
        if case .watching = state { return true }
        return false
    }
}

struct FakeReportBuilder: BuggerReportBuilder {
    func buildViewController(params: ReportParams) -> UIViewController {
        return UIViewController()
    }
}

class BuggerTests: XCTestCase {
    func testWith() {
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)

        let config = BuggerConfig(reportSender: FakeReportBuilder(), enableShakeToTrigger: true)
        Bugger.start(with: config)
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertTrue(Bugger.isWatching)
        
        Bugger.state = .notWatching
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
    }
    
    func testSetWatchState() {
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
        
        let config = BuggerConfig(reportSender: FakeReportBuilder(), enableShakeToTrigger: true)
        Bugger.state = .watching(config)
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertTrue(Bugger.isWatching)
        
        Bugger.state = .notWatching
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
    }
}
