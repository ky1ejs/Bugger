//
//  StringExtensions.swift
//  Bugger
//
//  Created by Kyle McAlpine on 29/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

extension String {
    public func matchesRegex(_ regex: String) -> Bool {
        let pred = NSPredicate(format: "SELF MATCHES %@", regex)
        return pred.evaluate(with: self)
    }
}
