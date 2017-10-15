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
    let bodyTV = PlaceholderTextView()
    let screenshotPreviewImageView = UIImageView()
    
    init(screenshot: UIImage) {
        super.init(frame: .zero)
        
        screenshotPreviewImageView.image = screenshot
        
        titleTF.translatesAutoresizingMaskIntoConstraints = false
        usernameTF.translatesAutoresizingMaskIntoConstraints = false
        githubEmailTF.translatesAutoresizingMaskIntoConstraints = false
        bodyTV.translatesAutoresizingMaskIntoConstraints = false
        screenshotPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleTF.placeholder = "Title"
        usernameTF.placeholder = "Username"
        githubEmailTF.placeholder = "GitHub Email"
        bodyTV.placeholder = "What was wrong? What can we improve?"
        
        addSubview(titleTF)
        addSubview(usernameTF)
        addSubview(githubEmailTF)
        addSubview(bodyTV)
        addSubview(screenshotPreviewImageView)
        
        NSLayoutConstraint.activate([
            titleTF.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            titleTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleTF.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleTF.heightAnchor.constraint(equalToConstant: 44),
            
            usernameTF.topAnchor.constraint(equalTo: titleTF.bottomAnchor),
            usernameTF.leadingAnchor.constraint(equalTo: titleTF.leadingAnchor),
            usernameTF.trailingAnchor.constraint(equalTo: titleTF.trailingAnchor),
            usernameTF.heightAnchor.constraint(equalTo: titleTF.heightAnchor),
            
            githubEmailTF.topAnchor.constraint(equalTo: usernameTF.bottomAnchor),
            githubEmailTF.leadingAnchor.constraint(equalTo: usernameTF.leadingAnchor),
            githubEmailTF.trailingAnchor.constraint(equalTo: usernameTF.trailingAnchor),
            githubEmailTF.heightAnchor.constraint(equalTo: usernameTF.heightAnchor),
            
            bodyTV.topAnchor.constraint(equalTo: githubEmailTF.bottomAnchor),
            bodyTV.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
            bodyTV.leadingAnchor.constraint(equalTo: githubEmailTF.leadingAnchor),
            bodyTV.trailingAnchor.constraint(equalTo: githubEmailTF.trailingAnchor),
            
            screenshotPreviewImageView.topAnchor.constraint(equalTo: bodyTV.bottomAnchor, constant: 20),
            screenshotPreviewImageView.leadingAnchor.constraint(equalTo: bodyTV.leadingAnchor),
            screenshotPreviewImageView.widthAnchor.constraint(equalTo: screenshotPreviewImageView.heightAnchor, multiplier: screenshot.size.width / screenshot.size.height),
            screenshotPreviewImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
