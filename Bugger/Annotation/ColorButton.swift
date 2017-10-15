//
//  ColorButton.swift
//  Bugger
//
//  Created by Kyle McAlpine on 15/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation

class ColorButton: UIButton {
    init(color: UIColor) {
        super.init(frame: .zero)
        
        backgroundColor = color
        
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 30).isActive = true
        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}
