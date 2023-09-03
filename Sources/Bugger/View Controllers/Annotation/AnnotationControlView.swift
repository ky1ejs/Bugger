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
    let redoButton: UIButton
    
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
        undoButton.setTitleColor(.lightGray, for: .disabled)
        undoButton.isEnabled = false
        
        redoButton = UIButton()
        redoButton.setTitle("Redo", for: .normal)
        redoButton.setTitleColor(.lightGray, for: .disabled)
        redoButton.isEnabled = false
        
        let colorButtons = colors.map(ColorButton.init(color:))
        selectedButton = colorButtons[0]
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(undoButton)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        undoButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        
        addSubview(redoButton)
        redoButton.translatesAutoresizingMaskIntoConstraints = false
        redoButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        redoButton.leadingAnchor.constraint(equalTo: undoButton.trailingAnchor, constant: 20).isActive = true
        
        let buttonScrollView = UIScrollView()
        buttonScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonScrollView)
        NSLayoutConstraint.activate([
            buttonScrollView.leadingAnchor.constraint(equalTo: redoButton.trailingAnchor, constant: 20),
            buttonScrollView.topAnchor.constraint(equalTo: topAnchor),
            buttonScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        
        colorButtons.forEach {
            $0.alpha = unselectedAlpha
            $0.addTarget(self, action: #selector(colorSelected(button:)), for: .touchUpInside)
        }
        selectedButton.alpha = 1
        
        var prevButton: UIButton?
        for button in colorButtons {
            buttonScrollView.addSubview(button)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
//                button.topAnchor.constraint(equalTo: buttonScrollView.topAnchor),
//                button.bottomAnchor.constraint(equalTo: buttonScrollView.bottomAnchor)
            ])
            if let prevButton = prevButton {
                button.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 20).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: buttonScrollView.leadingAnchor).isActive = true
            }
            
            prevButton = button
        }
        
        prevButton!.trailingAnchor.constraint(equalTo: buttonScrollView.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func colorSelected(button: UIButton) {
        selectedButton = button
    }
}

