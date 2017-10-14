//
//  ReportView.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class ReportView: UIView {
    let titleTF = UITextField()
    let usernameTF = UITextField()
    let githubEmailTF = UITextField()
    let bodyTV = UITextView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        titleTF.translatesAutoresizingMaskIntoConstraints = false
        usernameTF.translatesAutoresizingMaskIntoConstraints = false
        githubEmailTF.translatesAutoresizingMaskIntoConstraints = false
        bodyTV.translatesAutoresizingMaskIntoConstraints = false
        
        titleTF.placeholder = "Title"
        usernameTF.placeholder = "Username"
        githubEmailTF.placeholder = "GitHub Email"
        
        addSubview(titleTF)
        addSubview(usernameTF)
        addSubview(githubEmailTF)
        addSubview(bodyTV)
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: titleTF, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: titleTF, attribute: .leading, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: titleTF, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: titleTF, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44),
            
            NSLayoutConstraint(item: usernameTF, attribute: .top, relatedBy: .equal, toItem: titleTF, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .leading, relatedBy: .equal, toItem: titleTF, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .trailing, relatedBy: .equal, toItem: titleTF, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: usernameTF, attribute: .height, relatedBy: .equal, toItem: titleTF, attribute: .height, multiplier: 1, constant: 0),
        
            NSLayoutConstraint(item: githubEmailTF, attribute: .top, relatedBy: .equal, toItem: usernameTF, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: githubEmailTF, attribute: .leading, relatedBy: .equal, toItem: usernameTF, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: githubEmailTF, attribute: .trailing, relatedBy: .equal, toItem: usernameTF, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: githubEmailTF, attribute: .height, relatedBy: .equal, toItem: usernameTF, attribute: .height, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: bodyTV, attribute: .top, relatedBy: .equal, toItem: githubEmailTF, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bodyTV, attribute: .leading, relatedBy: .equal, toItem: githubEmailTF, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bodyTV, attribute: .trailing, relatedBy: .equal, toItem: githubEmailTF, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bodyTV, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
