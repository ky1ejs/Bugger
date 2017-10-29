//
//  UIWindowExtensions.swift
//  Bugger
//
//  Created by Kyle McAlpine on 28/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

extension UIWindow {
    func topViewController() -> String {
        return topViewController(controller: rootViewController)
    }
    
    func topViewController(controller: UIViewController?) -> String {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        
        if let controller = controller {
            return String(describing: controller)
        } else {
            return ""
        }
    }
}
