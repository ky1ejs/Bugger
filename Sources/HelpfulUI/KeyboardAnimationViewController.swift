//
//  KeyboardAnimationVC.swift
//  Bugger
//
//  Created by Kyle McAlpine on 23/07/2015.
//  Copyright (c) 2017 Kyle McAlpine. All rights reserved.
//
import UIKit

@MainActor
open class KeyboardAnimationVC: UIViewController {
    @IBOutlet fileprivate weak var keyboardConstraint: NSLayoutConstraint?

    // keyboardWillShowNotification is called many times when a keyboard type is changed
    // even if keyboard is still visible. This flag is to stop unnecessary
    // animation calls
    fileprivate(set) var isOnScreen = false
    fileprivate(set) var animationDuration = 0.4
    fileprivate(set) var animationOptions: UIView.AnimationOptions?
    fileprivate var originalBottomConstraintConstaint: CGFloat = 0
    fileprivate var keyboardHeight: CGFloat = 0
    var keyboardVisible: Bool { return keyboardHeight > 0 }

    // MARK: Controller life cycle
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    public override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnScreen = true
    }

    public override func viewDidDisappear(_ animated: Bool) {
        isOnScreen = false
        super.viewDidDisappear(animated)
    }

    // MARK: Observer callback -- getting CGRect values
    @objc func keyboardWillChangeFrame(notification: Notification) {
        setPropertiesWith(notification: notification)

        guard let userInfo = notification.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let screenRect = UIScreen.main.bounds
        let visibleKeyboardHeight = screenRect.height - endFrame.origin.y
        guard visibleKeyboardHeight != keyboardHeight else { return }

        if keyboardHeight == 0, let bottomConstraint = keyboardConstraint {
            // set original when showing keyboard
            originalBottomConstraintConstaint = bottomConstraint.constant
        }

        keyboardHeight = visibleKeyboardHeight
        keyboardWillChangeHeight(to: visibleKeyboardHeight)
    }

    // MARK: Updating properties
    fileprivate func setPropertiesWith(notification: Notification) {
        if let curveNumber = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationOptions = UIView.AnimationOptions(rawValue: curveNumber.uintValue << 16)
        }
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            animationDuration = duration
        }
    }

    // MARK: Observer callback - easier to override
    func keyboardWillChangeHeight(to keyboardHeight: CGFloat) {
        if let constraint = keyboardConstraint {
            constraint.constant = constraintConstant(for: keyboardHeight)
        }
        animate(to: keyboardHeight)
    }

    // MARK: Convenience for setting animations
    func constraintConstant(for keyboardHeight: CGFloat) -> CGFloat {
        return keyboardHeight == 0 ? originalBottomConstraintConstaint : keyboardHeight
    }

    // MARK: Animate change
    private func animate(to keyboardHeight: CGFloat) {
        guard isOnScreen else {
            keyboardAnimations(to: keyboardHeight)
            return
        }

        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions ?? [], animations: {
            self.keyboardAnimations(to: keyboardHeight)
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // Override this to provide keyboard animations
    open func keyboardAnimations(to keyboardHeight: CGFloat) {}
}

