//
//  Report.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork

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
    
    func formattedBody(with imageURL: URL) -> String {
        let bundleInfo          = Bundle.main.infoDictionary
        let device              = UIDevice.current
        let locale              = Locale.current.description
        let screenSize          = UIScreen.main.bounds.size
        
        let orientation: String = {
            switch device.orientation {
            case .landscapeLeft: return "Landscape Left"
            case .landscapeRight: return "Landscape Right"
            case .portrait: return "Portrait"
            case .portraitUpsideDown: return "Portrait Upside Down"
            case .faceDown: return "Face Down"
            case .faceUp: return "Face Up"
            case .unknown: return "Unknown"
            }
        }()
        
        let batteryState: String = {
            switch device.batteryState {
            case .charging: return "Charging"
            case .full: return "Full"
            case .unknown: return "Unknown"
            case .unplugged: return "Unplugged"
            }
        }()
        
        typealias CellData = (key: String, value: String)
        
        let meta: [CellData] = [
            (key: "Bundle ID",              value: bundleInfo?[String(kCFBundleIdentifierKey)] as? String ?? ""),
            (key: "Version",                value: bundleInfo?["CFBundleShortVersionString"] as? String ?? ""),
            (key: "Build",                  value: bundleInfo?[String(kCFBundleVersionKey)] as? String ?? ""),
            (key: "OS",                     value: device.systemName),
            (key: "OS Version",             value: device.systemVersion),
            (key: "Device Model",           value: device.model),
            (key: "Device Orientation",     value: orientation),
            (key: "Device Locale",          value: locale),
            (key: "Device Date",            value: String(describing: Date())),
            (key: "Battery Charge",         value: "\(device.batteryLevel)%"),
            (key: "Battery State",          value: batteryState),
            (key: "Screen Size",            value: "\(screenSize.width) x \(screenSize.height)"),
            (key: "Screen Density",         value: "\(UIScreen.main.scale)")
        ]
        
        // Does not work on the simulator.
        let ssid: String? = {
            guard let supportedInterfaces = CNCopySupportedInterfaces() as? [CFString]      else { return nil }
            guard let interface = supportedInterfaces.first                                 else { return nil }
            guard let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interface)             else { return nil }
            guard let interfaceData = unsafeInterfaceData as? Dictionary <String,AnyObject> else { return nil }
            return interfaceData["SSID"] as? String
        }()
        
        //        activeViewController
        //        location
        //
        //        mobileNetworkName
        //        mobileNetworkDataConnection
        //        memoryCapacityRemaining
        //        memoryCapacity
        //        hardDriveCapacityRemaning
        //        hardDriveCapacity
        
        let itemsPerRow = 3
        var tableData = [[CellData]]()
        
        var row = [CellData]()
        for i in 0..<meta.count {
            let cell = meta[i]
            row.append(cell)
            
            if (i + 1) % itemsPerRow == 0 || i == meta.count - 1 {
                tableData.append(row)
                row = [CellData]()
            }
        }
        
        var body = """
        Reporter: @\(githubUsername ?? "")
        
        <table>
        """
        
        for row in tableData {
            body += """
            
            <tr>
            """
            for cell in row {
                body += """
                
                <th>\(cell.key)</th><td>\(cell.value)</td>
                """
            }
            
            body += """
            
            </tr>
            """
        }
        
        body += """
        </table>
        
        ## Description
        \(self.body)
        
        ## Screenshot(s)
        ![](\(imageURL.absoluteString))
        """
        
        return body
    }
    
    func send(with config: BuggerConfig, completion: @escaping (UploadResult) -> ()) {
        uploadImage(config: config) { url in
            self.createGitHubIssue(config: config, imageURL: url, completion: completion)
        }
    }
    
    private func uploadImage(config: BuggerConfig, successHandler: @escaping (URL) -> ()) {
        config.store.imageStore.uploadImage(image: image) { result in
            switch result {
            case .success(let url):
                successHandler(url)
            case .error:
                break
            }
        }
    }
    
    private func createGitHubIssue(config: BuggerConfig, imageURL: URL, completion: @escaping (UploadResult) -> ()) {
        let issueData =  [ "title": summary, "body": formattedBody(with: imageURL) ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: issueData, options: [])
        
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(config.owner)/\(config.repo)/issues")!)
        request.httpMethod = "POST"
        request.addValue("token \(config.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            var result: UploadResult = .error(BuggerError.unknown)
            defer { DispatchQueue.main.async { completion(result) } }
            
            guard let data = data else { return }
            guard let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return }
            guard let issueUrlString = json["html_url"] as? String else { return }
            guard let issueUrl = URL(string: issueUrlString) else { return }
            result = .success(issueUrl)
        })
        task.resume()
    }
}

enum ReportValidationError: Error {
    case summaryLength
    case bodyLength
    case summaryAndbodyLength
}

enum BuggerError: Error {
    case unknown
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
