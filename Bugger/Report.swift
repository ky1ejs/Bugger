//
//  Report.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

protocol UserError {
    var userErrorMessage: String { get }
}

enum ReportValidationError: Error {
    case summaryLength
    case bodyLength
    case summaryAndbodyLength
}

extension ReportValidationError: UserError {
    var userErrorMessage: String {
        switch self {
        case .summaryLength: return "Summary required"
        case .bodyLength: return "Description required"
        case .summaryAndbodyLength: return "Summary and Description required"
        }
    }
}

struct Report {
    let githubUsername: String?
    let summary: String
    let body: String
    let image: UIImage
    
    init(githubUsername: String?, summary: String?, body: String?, image: UIImage) throws {
        
        let summaryCount = summary?.count ?? 0
        let bodyCount = body?.count ?? 0
        
        guard let summary = summary, let body = body,
            summaryCount > 0, bodyCount > 0 else {
            switch (summaryCount, bodyCount) {
            case (0, 0):    throw ReportValidationError.summaryAndbodyLength
            case (0, _):    throw ReportValidationError.summaryLength
            default:        throw ReportValidationError.bodyLength
            }
        }
        
        self.githubUsername = githubUsername
        self.summary = summary
        self.body = body
        self.image = image
    }
    
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
            "title": summary,
            "body":
            """
            Reporter: @\(githubUsername ?? "")
            
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
