//
//  Store.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

public enum Store: Sendable {
    case image(any ImageStore)
    case imageAndVideo(any ImageStore & VideoStore)

    public var imageStore: any ImageStore {
        switch self {
        case .image(let store):         return store
        case .imageAndVideo(let store): return store
        }
    }
}

public protocol ImageStore: Sendable {
    func uploadImage(image: UIImage) async throws -> URL
}

public protocol VideoStore: Sendable {
    func uploadVideo(data: Data) async throws -> URL
}
