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
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }

    var safeTopAnchor: NSLayoutYAxisAnchor {
        safeAreaLayoutGuide.topAnchor
    }

    var safeBottomAnchor: NSLayoutYAxisAnchor {
        safeAreaLayoutGuide.bottomAnchor
    }

    var safeCenterXAnchor: NSLayoutXAxisAnchor {
        safeAreaLayoutGuide.centerXAnchor
    }

    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        safeAreaLayoutGuide.centerYAnchor
    }

    var safeHeightAnchor: NSLayoutDimension {
        safeAreaLayoutGuide.heightAnchor
    }

    var safeWidthAnchor: NSLayoutDimension {
        safeAreaLayoutGuide.widthAnchor
    }

    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        safeAreaLayoutGuide.leadingAnchor
    }

    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        safeAreaLayoutGuide.trailingAnchor
    }

    var safeLeftAnchor: NSLayoutXAxisAnchor {
        safeAreaLayoutGuide.leftAnchor
    }

    var safeRightAnchor: NSLayoutXAxisAnchor {
        safeAreaLayoutGuide.rightAnchor
    }
}
