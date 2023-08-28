//
//  AppDelegate.swift
//  BuggerExample
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import BuggerImgurStore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let imgur = BuggerImgurStore(clientID: ExampleConfig.imgurClientID)
        let config = BuggerConfig(token: ExampleConfig.githubToken,
                                  owner: ExampleConfig.githubOwner,
                                  repo: ExampleConfig.githubRepo,
                                  store: .image(imgur))
        Bugger.with(config: config)
        
        return true
    }
}

