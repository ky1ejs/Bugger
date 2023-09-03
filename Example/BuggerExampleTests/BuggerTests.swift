//
//  BuggerTests.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 26/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import XCTest
@testable import Bugger
@testable import BuggerExample

class BuggerTests: XCTestCase {
    func testInvocation() {
        let isBuggerActive: () -> Bool = {
            if case .active = Bugger.state { return true }
            return false
        }
        
        XCTAssertFalse(isBuggerActive())
        UIApplication.shared.delegate?.window??.motionEnded(UIEventSubtype.motionShake, with: UIEvent())
        XCTAssertTrue(isBuggerActive())
    }
}
