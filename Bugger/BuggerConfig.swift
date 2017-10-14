//
//  BuggerConfig.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public struct BuggerConfig {
    let token: String
    let owner: String
    let repo: String
    let dataStore: DataStore
    let swizzleInvocation: Bool
    
    public init(token: String, owner: String, repo: String, dataStore: DataStore, swizzleInvocation: Bool = true) {
        self.token = token
        self.owner = owner
        self.repo = repo
        self.dataStore = dataStore
        self.swizzleInvocation = swizzleInvocation
    }
}
