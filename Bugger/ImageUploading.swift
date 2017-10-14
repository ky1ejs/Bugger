//
//  ImageUploading.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public enum UploadResult {
    case success(URL)
    case failure(Error)
}

public protocol DataStore {
    func uploadData(data: Data, completion: (UploadResult) -> ())
}
