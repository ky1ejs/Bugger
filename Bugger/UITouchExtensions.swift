//
//  UITouchExtensions.swift
//  Bugger
//
//  Created by Kyle McAlpine on 15/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

extension UITouch {
    func isLocated(in view: UIView) -> Bool {
        let l = location(in: view)
        return l.x >= 0 && l.y >= 0 && l.x <= view.frame.width && l.y <= view.frame.height
    }
}
