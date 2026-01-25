//
//  DummyStore.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 02/11/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
@testable import Bugger

struct DummyStore: Sendable {}

extension DummyStore: ImageStore {
    func uploadImage(image: UIImage) async throws -> URL {
        return URL(string: "https://test.com")!
    }
}
