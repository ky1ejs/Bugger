//
//  Store.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

public enum Store {
    case image(ImageStore)
    case imageAndVideo(ImageStore & VideoStore)
    
    var imageStore: ImageStore {
        switch self {
        case .image(let store):         return store
        case .imageAndVideo(let store): return store
        }
    }
}

public protocol ImageStore {
    func uploadImage(image: UIImage, completion: @escaping (UploadResult) -> ())
}

public protocol VideoStore {
    func uploadImage(videoData: Data, completion: @escaping (UploadResult) -> ())
}

public enum UploadResult {
    case success(URL)
    case failure(Error)
}
