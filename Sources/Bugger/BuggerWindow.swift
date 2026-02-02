//
//  BuggerWindow.swift
//  Bugger
//
//  Created by Claude on 2026.
//  Copyright © 2026 Kyle McAlpine. All rights reserved.
//

import UIKit

/// A custom UIWindow subclass that detects shake gestures to trigger bug reporting.
///
/// To enable shake-to-report functionality, use `BuggerWindow` as your app's main window class
/// in your SceneDelegate or AppDelegate:
///
/// ```swift
/// // In SceneDelegate:
/// func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
///     guard let windowScene = scene as? UIWindowScene else { return }
///     let window = BuggerWindow(windowScene: windowScene)
///     window.rootViewController = YourRootViewController()
///     window.makeKeyAndVisible()
///     self.window = window
/// }
/// ```
@MainActor
public class BuggerWindow: UIWindow {
    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        guard case .watching(let config) = Bugger.state else { return }
        guard config.enableShakeToTrigger else { return }
        Bugger.present(with: config, from: self)
    }
}
