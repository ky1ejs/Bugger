//
//  Bugger.swift
//  Bugger
//
//  Created by Kyle McAlpine on 26/09/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

/// Main entry point for the Bugger bug reporting framework.
///
/// To enable shake-to-report functionality, use `BuggerWindow` as your app's main window class.
/// See `BuggerWindow` documentation for setup instructions.
@MainActor
public struct Bugger {
    static var state: BuggerState = .notWatching

    public static func start(with config: BuggerConfig) {
        state = .watching(config)
    }

    public static func stop() {
        state = .notWatching
    }

    static public func present(with config: BuggerConfig, from window: UIWindow) {
        let annotationVC = AnnotationViewController(appWindow: window, config: config)
        let nav = UINavigationController(rootViewController: annotationVC)
        let buggerWindow = UIWindow(frame: UIScreen.main.bounds)
        buggerWindow.rootViewController = nav
        buggerWindow.windowLevel = UIWindow.Level(.greatestFiniteMagnitude)
        buggerWindow.makeKeyAndVisible()
        Bugger.state = .active(window: buggerWindow, config: config)
    }
}


