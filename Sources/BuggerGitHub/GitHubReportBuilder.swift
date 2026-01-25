//
//  GitHubReportBuilder.swift
//  BuggerGitHub
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger

public struct GitHubReportBuilder: BuggerReportBuilder, Sendable {
    let config: GitHubConfig

    public init(config: GitHubConfig) {
        self.config = config
    }

    @MainActor
    public func buildViewController(params: ReportParams) -> UIViewController {
        return ReportViewController(reportParams: params, gitHubConfig: config)
    }
}
