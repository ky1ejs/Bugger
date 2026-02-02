//
//  BuggerState.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

public struct BuggerConfig: Sendable {
    let reportSender: any BuggerReportBuilder
    let enableShakeToTrigger: Bool

    public init(reportSender: any BuggerReportBuilder, enableShakeToTrigger: Bool) {
        self.reportSender = reportSender
        self.enableShakeToTrigger = enableShakeToTrigger
    }
}

@MainActor
enum BuggerState {
    case watching(BuggerConfig)
    case active(window: UIWindow, config: BuggerConfig)
    case notWatching
}
