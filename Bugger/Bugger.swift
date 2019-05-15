//
//  Bugger.swift
//  Bugger
//
//  Created by Kyle McAlpine on 26/09/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

public struct Bugger {
    static var state: BuggerState = .notWatching {
        didSet {
            guard case .watching(let config) = state else { return }
            if config.swizzleInvocation { UIResponder.swizzleBuggerInvocation() }
        }
    }
    
    public static func with(config: BuggerConfig) {
        state = .watching(config)
    }
    
    static public func present(with config: BuggerConfig, from window: UIWindow) {
        let annotationVC = AnnotationViewController(appWindow: window, config: config)
        let nav = UINavigationController(rootViewController: annotationVC)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = nav
        window.windowLevel = UIWindow.Level(.greatestFiniteMagnitude)
        window.makeKeyAndVisible()
        Bugger.state = .active(window: window, config: config)
    }
}


