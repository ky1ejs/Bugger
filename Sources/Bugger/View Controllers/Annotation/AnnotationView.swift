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
    let controlView = AnnotationControlView()
    
    init(image: UIImage) {
        super.init(frame: .zero)
        
        backgroundColor = .gray
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        
        addSubview(imageView)
        addSubview(controlView)
        
        NSLayoutConstraint.activate([
            controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlView.bottomAnchor.constraint(equalTo: safeBottomAnchor),
            controlView.centerXAnchor.constraint(equalTo: centerXAnchor),
            controlView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let insetTop: CGFloat = {
            if #available(iOS 11.0, *) {
                return safeAreaInsets.top
            }
            return 0
        }()
        
        // Calculate imageView frame manually because it needs a whole width and height for CGContext to generate an image
        let imageViewHeight = bounds.height - insetTop - (bounds.height - controlView.frame.origin.y)
        let imageViewWidth = ceil(imageViewHeight * (UIScreen.main.bounds.width / UIScreen.main.bounds.height))
        let imageViewX = (bounds.width - imageViewWidth) / 2
        let imageViewY = insetTop
        imageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewWidth, height: imageViewHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
