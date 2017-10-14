//
//  BuggerDelegate.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

protocol BuggerDelegate {
    func issueCreated()
    func errorUploadingData(error: Error)
    func errorCreatingIssue(error: Error)
}
