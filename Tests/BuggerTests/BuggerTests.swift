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

class BuggerTests: XCTestCase {
    func testWith() {
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
        
        let config = BuggerConfig(token: "", owner: "", repo: "", store: .image(DummyStore()))
        Bugger.with(config: config)
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertTrue(Bugger.isWatching)
        
        Bugger.state = .notWatching
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
    }
    
    func testSetWatchState() {
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
        
        let config = BuggerConfig(token: "", owner: "", repo: "", store: .image(DummyStore()))
        Bugger.state = .watching(config)
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertTrue(Bugger.isWatching)
        
        Bugger.state = .notWatching
        
        XCTAssertFalse(Bugger.isActive)
        XCTAssertFalse(Bugger.isWatching)
    }
}
