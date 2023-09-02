//
//  TableViewController.swift
//  BuggerExample
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import BuggerGitHub
import BuggerLinear

class TableViewController: UITableViewController {
    override func viewDidAppear(_ animated: Bool) {
        Bugger.stop()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "GitHub":
            let gitHubConfig = GitHubConfig(token: "", owner: "", repo: "", imgurClientId: "")
            let config = BuggerConfig(
                reportSender: GitHubReportBuilder(config: gitHubConfig),
                enableShakeToTrigger: true
            )
            Bugger.start(with: config)
        case "Linear":
            let linearConfig = LinearConfig(teamId: "f8412081-c091-456c-b4ce-7930c032cfa9")
            let config = BuggerConfig(reportSender: LinearReportBuilder(config: linearConfig),
                enableShakeToTrigger: true
            )
            Bugger.start(with: config)
        default:
            break
        }
    }
}
