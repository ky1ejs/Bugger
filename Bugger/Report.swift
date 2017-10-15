//
//  Report.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

struct Report {
    let title: String
    let username: String
    let githubUsername: String
    let body: String
    let image: UIImage
    
    func send(with config: BuggerConfig, completion: @escaping (Bool) -> ()) {
        uploadImage(config: config) { url in
            self.createGitHubIssue(config: config, imageURL: url, completion: completion)
        }
    }
    
    func uploadImage(config: BuggerConfig, successHandler: @escaping (URL) -> ()) {
        config.store.imageStore.uploadImage(image: image) { result in
            switch result {
            case .success(let url):
                successHandler(url)
            case .failure:
                break
            }
        }
    }
    
    func createGitHubIssue(config: BuggerConfig, imageURL: URL, completion: @escaping (Bool) -> ()) {
        let issueData =  [
            "title": title,
            "body":
            """
            Reporter: \(username)
            Reporter: @\(githubUsername)
            
            ---
            
            ![](\(imageURL.absoluteString))
            
            ---
            
            \(body)
            """
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: issueData, options: [])
        
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(config.owner)/\(config.repo)/issues")!)
        request.httpMethod = "POST"
        request.addValue("token \(config.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let success = (response as? HTTPURLResponse)?.statusCode ?? 0 == 201
            completion(success)
//            guard let data = data else { return }
//            guard let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return }
            
        })
        task.resume()
    }
}
