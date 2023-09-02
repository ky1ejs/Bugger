//
//  Error.swift
//  Bugger
//
//  Created by Kyle McAlpine on 17/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public protocol UserError {
    var userErrorMessage: String { get }
}

public extension Error {
    var errorMessage: String {
        if let stringConvertable = self as? UserError {
            return stringConvertable.userErrorMessage
        }
        return "Unknown error 😕"
    }
}
