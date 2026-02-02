//
//  BuggerReportBuilder.swift
//  Bugger
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit

@MainActor
public protocol BuggerReportBuilder: Sendable {
    func buildViewController(params: ReportParams) -> UIViewController
}
