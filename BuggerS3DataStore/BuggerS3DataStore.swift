//
//  BuggerS3DataStore.swift
//  BuggerS3DataStore
//
//  Created by Kyle McAlpine on 29/09/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation
import Bugger

public struct BuggerS3DataStore: DataStore {
    public init() {}
    public func uploadData(data: Data, completion: (UploadResult) -> ()) {}
}
