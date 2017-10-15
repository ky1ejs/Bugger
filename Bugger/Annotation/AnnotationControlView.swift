//
//  AnnotationControlView.swift
//  Bugger
//
//  Created by Kyle McAlpine on 15/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class AnnotationControlView: UIView {
    let colors: [UIColor] = [ .red, .blue, .green, .orange, .purple, .black]
    let undoButton: UIButton
    
    private let unselectedAlpha: CGFloat = 0.2
    private var selectedButton: UIButton {
        didSet {
            oldValue.alpha = unselectedAlpha
            selectedButton.alpha = 1
        }
    }
    
    var selectedColor: UIColor { return selectedButton.backgroundColor ?? .red }
    
    init() {
        undoButton = UIButton()
        undoButton.setTitle("Undo", for: .normal)
        
        let colorButtons = colors.map(ColorButton.init(color:))
        selectedButton = colorButtons[0]
        
        super.init(frame: .zero)
        
        colorButtons.forEach {
            $0.alpha = unselectedAlpha
            $0.addTarget(self, action: #selector(colorSelected(button:)), for: .touchUpInside)
        }
        selectedButton.alpha = 1
        
        translatesAutoresizingMaskIntoConstraints = false
        
        var prevButton: UIButton?
        for button in colorButtons {
            addSubview(button)
            
            button.heightAnchor.constraint(equalToConstant: 30).isActive = true
            button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            if let prevButton = prevButton {
                button.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 20).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
            }
            
            prevButton = button
        }
        
        addSubview(undoButton)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        undoButton.leadingAnchor.constraint(equalTo: colorButtons.last!.trailingAnchor, constant: 20).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func colorSelected(button: UIButton) {
        selectedButton = button
    }
}

