//
//  LinearConfig.swift
//  BuggerLinear
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import Foundation

public struct LinearConfig: Sendable {
    public let teamId: String
    public let apiKey: String

    public init(teamId: String, apiKey: String) {
        self.teamId = teamId
        self.apiKey = apiKey
    }
}

