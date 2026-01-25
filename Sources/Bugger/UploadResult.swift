//
//  UploadResult.swift
//  Bugger
//
//  Created by Kyle McAlpine on 18/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public enum UploadResult: Sendable {
    case success(URL)
    case error(any BuggerError)
}
