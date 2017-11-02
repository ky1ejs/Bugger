//
//  DummyStore.swift
//  BuggerTests
//
//  Created by Kyle McAlpine on 02/11/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation
@testable import Bugger

struct DummyStore {}

extension DummyStore: ImageStore {
    func uploadImage(image: UIImage, completion: @escaping (UploadResult) -> ()) {
        completion(.success(URL(string: "https://test.com")!))
    }
}
