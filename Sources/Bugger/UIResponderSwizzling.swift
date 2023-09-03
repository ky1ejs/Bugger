//
//  UIResponderSwizzling.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

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
    
    @objc open func bugger_motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        defer { bugger_motionEnded(motion, with: event) }
        
        guard motion == .motionShake else { return }
        guard case .watching(let config) = Bugger.state else { return }
        guard let window = UIApplication.shared.delegate?.window, let win = window else { return }
        
        Bugger.present(with: config, from: win)
    }
}
