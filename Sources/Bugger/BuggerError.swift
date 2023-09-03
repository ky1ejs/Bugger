//
//  BuggerError.swift
//  Bugger
//
//  Created by Kyle McAlpine on 29/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public protocol BuggerError: Error {}

public enum SerialisationError: BuggerError {
    case error(Error)
}

public enum NetworkError: BuggerError {
    case requestError(error: Error?)
    case responseParseError
    case noInternetConnection
}

public enum GeneralError: BuggerError {
    case unknown
}
