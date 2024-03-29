//
//  ChainedTextField.swift
//  Bugger
//
//  Created by Kyle McAlpine on 10/11/2015.
//  Copyright © 2015 Kyle McAlpine. All rights reserved.
//
import UIKit

public class ChainedTextField: UITextField {
    @IBInspectable public var characterLimit: Int = 0
    @IBInspectable public var characterRegex: String? = nil
    @IBInspectable public var textRegex: String? = nil
    
    public weak var chainedTextFieldDelegate: ChainedTextFieldDelegate?
    
    public weak var nextControl: UIResponder?
    public weak var previousControl: UIResponder?
    
    fileprivate weak var _delegate: UITextFieldDelegate?
    @IBOutlet public override var delegate: UITextFieldDelegate? {
        get { return _delegate }
        set { _delegate = newValue }
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        super.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.delegate = self
    }
    
    public override func deleteBackward() {
        if self.text?.count == 0 {
            if let previous = previousControl {
                previous.becomeFirstResponder()
            } else if let del = chainedTextFieldDelegate {
                del.deletedBackwards()
            }
        }
        super.deleteBackward()
    }
}

extension ChainedTextField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" || range.length > 0 {
            return true
        }
        if let text = self.text {
            if let regex = self.characterRegex, !string.matchesRegex(regex) {
                return false
            } else if self.characterLimit > 0 && text.count > self.characterLimit - 1 {
                return false
            } else {
                let newString = (text as NSString).replacingCharacters(in: range, with: string)
                if let regex = self.textRegex, !newString.matchesRegex(regex) {
                    return false
                }
                textField.text = newString // if we don't do this, the next reponder is changed instead for some reason...
                let pos = textField.selectedTextRange!.start
                let index = textField.offset(from: textField.beginningOfDocument, to: pos)
                let count = newString.count
                if range.location < index - 1, let position = textField.position(from: textField.beginningOfDocument, offset: range.location + 1) {
                    textField.selectedTextRange = textField.textRange(from: position, to: position)
                } else if count == self.characterLimit && index == count {
                    if let next = nextControl {
                        next.becomeFirstResponder()
                    } else if let del = chainedTextFieldDelegate {
                        del.goToNextControl()
                    }
                }
                self.sendActions(for: .editingChanged) // We changed text manually and are returning false, so must send this
                return false
            }
        }
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let next = nextControl {
            next.becomeFirstResponder()
            return false
        }
        
        if let del = chainedTextFieldDelegate {
            del.goToNextControl()
            return false
        }
        
        return self.delegate?.textFieldShouldReturn?(textField) ?? false
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing?(textField)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidEndEditing?(textField)
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.delegate?.textFieldShouldClear?(textField) ?? true
    }
}

public protocol ChainedTextFieldDelegate: AnyObject {
    func deletedBackwards()
    func goToNextControl()
}
