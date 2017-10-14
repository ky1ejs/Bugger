//
//  AppDelegate.swift
//  BuggerExample
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import BuggerS3DataStore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let s3 = BuggerS3DataStore()
        let config = BuggerConfig(token: "", owner: "", repo: "", dataStore: s3)
        Bugger.with(config: config)
        return true
    }
}

