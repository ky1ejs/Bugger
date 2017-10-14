//
//  AnnotationView.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class AnnotationView: UIView {
    let imageView = UIImageView()
    
    init(image: UIImage) {
        super.init(frame: .zero)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        
        addSubview(imageView)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0),
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
