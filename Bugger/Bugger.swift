//
//  Bugger.swift
//  Bugger
//
//  Created by Kyle McAlpine on 26/09/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public struct BuggerConfig {
    let token: String
    let owner: String
    let repo: String
    let dataStore: DataStore
    let swizzleInvocation: Bool
    
    public init(token: String, owner: String, repo: String, dataStore: DataStore, swizzleInvocation: Bool = true) {
        self.token = token
        self.owner = owner
        self.repo = repo
        self.dataStore = dataStore
        self.swizzleInvocation = swizzleInvocation
    }
}

protocol BuggerDelegate {
    func issueCreated()
    func errorUploadingData(error: Error)
    func errorCreatingIssue(error: Error)
}

enum BuggerState {
    case watching(BuggerConfig)
    case active(window: UIWindow, config: BuggerConfig)
    case notWatching
}

public struct Bugger {
    static var state: BuggerState = .notWatching {
        didSet {
            guard case .watching(let config) = state else { return }
            if config.swizzleInvocation { UIWindow.swizzleBuggerInvocation() }
        }
    }
    
    public static func with(config: BuggerConfig) {
        state = .watching(config)
    }
    
    static public func present(with config: BuggerConfig, from window: UIWindow) {
        let annotationVC = AnnotationViewController(screenshot: snapshot(of: window), config: config)
        let nav = UINavigationController(rootViewController: annotationVC)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = nav
        window.windowLevel = .greatestFiniteMagnitude
        window.makeKeyAndVisible()
        Bugger.state = .active(window: window, config: config)
    }
    
    static func snapshot(of view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshot!
    }
}

extension UIResponder {
    class func swizzleBuggerInvocation() {
        struct Dispatch {
            static let once: () = {
                let originalSelector = #selector(UIResponder.motionEnded(_:with:))
                let swizzledSelector = #selector(UIResponder.bugger_motionEnded(_:with:))
                
                let originalMethod = class_getInstanceMethod(UIResponder.self, originalSelector)!
                let swizzledMethod = class_getInstanceMethod(UIResponder.self, swizzledSelector)!
                
                let didAddMethod = class_addMethod(UIResponder.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
                
                if didAddMethod {
                    class_replaceMethod(UIResponder.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
                } else {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }()
        }
        _ = Dispatch.once
    }
    
    @objc open func bugger_motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        defer { bugger_motionEnded(motion, with: event) }
        
        guard motion == .motionShake else { return }
        guard case .watching(let config) = Bugger.state else { return }
        guard let window = UIApplication.shared.delegate?.window, let win = window else { return }
        
        Bugger.present(with: config, from: win)
    }
}


class AnnotationViewController: UIViewController {
    let config: BuggerConfig
    let annotationView: AnnotationView
    let screenshot: UIImage
    
    init(screenshot: UIImage, config: BuggerConfig) {
        self.config = config
        self.screenshot = screenshot
        annotationView = AnnotationView(image: screenshot)
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextStep))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() { view = annotationView }
    
    @objc private func nextStep() {
        let reportVC = ReportViewController(annotatedScreenshot: screenshot, config: config)
        navigationController?.pushViewController(reportVC, animated: true)
    }
}

class AnnotationView: UIView {
    let imageView = UIImageView()
    
    init(image: UIImage) {
        super.init(frame: .zero)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        
        addSubview(imageView)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ReportViewController: UIViewController {
    let config: BuggerConfig
    let reportView = ReportView()
    
    init(annotatedScreenshot: UIImage, config: BuggerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = reportView
    }
    
    func send() {
        // upload screenshots and videos to S3
        // create GH ticket and submit data
    }
}

struct Report {
    let title: String
    let username: String
    let githubEmail: String
    let body: String
}

class ReportView: UIView {
    let titleTF = UITextField()
    let usernameTF = UITextField()
    let githubEmailTF = UITextField()
    let bodyTV = UITextView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        addSubview(titleTF)
        addSubview(usernameTF)
        addSubview(githubEmailTF)
        addSubview(bodyTV)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: titleTF, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: titleTF, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: titleTF, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: titleTF, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44),
            
            NSLayoutConstraint(item: usernameTF, attribute: .height, relatedBy: .equal, toItem: titleTF, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .leading, relatedBy: .equal, toItem: titleTF, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .trailing, relatedBy: .equal, toItem: titleTF, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .height, relatedBy: .equal, toItem: titleTF, attribute: .height, multiplier: 1, constant: 0)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum UploadResult {
    case success(URL)
    case failure(Error)
}

public protocol DataStore {
    func uploadData(data: Data, completion: (UploadResult) -> ())
}
