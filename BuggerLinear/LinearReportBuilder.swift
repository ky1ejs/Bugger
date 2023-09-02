//
//  LinearReportBuilder.swift
//  BuggerLinear
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import Bugger

public struct LinearReportBuilder: BuggerReportBuilder {
    let config: LinearConfig

    public init(config: LinearConfig) {
        self.config = config
    }

    public func buildViewController(params: ReportParams) -> UIViewController {
        return ReportViewController(reportParams: params, linearConfig: config)
    }
}
