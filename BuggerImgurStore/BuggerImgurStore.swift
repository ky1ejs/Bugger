//
//  BuggerImgurStore.swift
//  BuggerImgurStore
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger

public struct BuggerImgurStore {
    let clientID: String
    
    public init(clientID: String) {
        self.clientID = clientID
    }
}

extension BuggerImgurStore: ImageStore {
    public func uploadImage(image: UIImage, completion: @escaping (UploadResult) -> ()) {
        var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.addValue("Client-ID \(clientID)", forHTTPHeaderField: "Authorization")
        let data = UIImagePNGRepresentation(image)!
        request.httpBody = data.base64EncodedString().data(using: .utf8, allowLossyConversion: true)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            var result = UploadResult.error(GeneralError.unknown)
            
            defer { DispatchQueue.main.async { completion(result) } }
            
            if let error = error {
                completion(.error(NetworkError.requestError(error: error)))
            } else {
                do {
                    guard let data = data else { return }
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return }
                    guard let imageData = json["data"] as? [String : Any] else { return }
                    guard let urlString = imageData["link"] as? String else { return }
                    guard let url = URL(string: urlString) else { return }
                    result = .success(url)
                } catch let error {
                    result = .error(SerialisationError.error(error))
                }
            }
        })
        task.resume()
    }
}
