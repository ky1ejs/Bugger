//
//  BuggerImgurStore.swift
//  BuggerImgurStore
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger

public struct BuggerImgurStore: Sendable {
    let clientID: String

    public init(clientID: String) {
        self.clientID = clientID
    }
}

extension BuggerImgurStore: ImageStore {
    public func uploadImage(image: UIImage) async throws -> URL {
        guard let imageData = image.pngData() else {
            throw GeneralError.unknown
        }

        var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.addValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")
        request.httpBody = imageData.base64EncodedString().data(using: .utf8, allowLossyConversion: true)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let urlString = responseData["link"] as? String,
              let url = URL(string: urlString) else {
            throw NetworkError.responseParseError
        }

        return url
    }
}
