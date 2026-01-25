//
//  GitHubConfig.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Bugger

public struct GitHubConfig: Sendable {
    public let token: String
    public let owner: String
    public let repo: String
    public let imgurClientId: String

    public init(token: String, owner: String, repo: String, imgurClientId: String) {
        self.token = token
        self.owner = owner
        self.repo = repo
        self.imgurClientId = imgurClientId
    }
}
