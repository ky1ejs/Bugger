//
//  UIViewExtensions.swift
//  Bugger
//
//  Created by Kyle McAlpine on 29/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

extension UIView {
    func snapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshot!
    }
}
