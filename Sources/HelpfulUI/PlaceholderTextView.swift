//
//  PlaceholderTextView.swift
//  Bugger
//
//  Created by Kyle McAlpine on 15/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

@MainActor
public class PlaceholderTextView: UITextView {
    public var placeholder = "" {
        didSet {
            placeholderLabel.text = placeholder
            showOrHidePlaceholder()
        }
    }
    let placeholderLabel = UILabel()
    
    public init() {
        super.init(frame: .zero, textContainer: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: UITextView.textDidChangeNotification, object: self)
        
        font = .systemFont(ofSize: 17)
        textContainer.lineFragmentPadding = 0
        
        placeholderLabel.font = font
        placeholderLabel.textAlignment = textAlignment
        placeholderLabel.textColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(placeholderLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textChanged() {
        guard placeholder.count > 0 else { return }
        
        UIView.animate(withDuration: 0.1) {
            self.showOrHidePlaceholder()
        }
    }
    
    func showOrHidePlaceholder() {
        placeholderLabel.alpha = text.count == 0 ? 1 : 0
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let linePadding = textContainer.lineFragmentPadding
        let x = textContainerInset.left + linePadding
        let y = textContainerInset.top
        let width = frame.size.width - textContainerInset.left - textContainerInset.right - 2 * linePadding
        let height = placeholderLabel.sizeThatFits(CGSize(width: width, height: 0)).height
        
        let placeholderRect = CGRect(x: x, y: y, width: width, height: height)
        placeholderLabel.frame = placeholderRect
        showOrHidePlaceholder()
    }
}
