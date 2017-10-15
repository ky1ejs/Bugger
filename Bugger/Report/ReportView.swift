//
//  ReportView.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class ReportView: UIView {
    let githubUsernameTF = UITextField()
    let summaryTF = UITextField()
    let bodyTV = PlaceholderTextView()
    let screenshotPreviewImageView = UIImageView()
    
    init(screenshot: UIImage) {
        super.init(frame: .zero)
        
        screenshotPreviewImageView.image = screenshot
        
        githubUsernameTF.translatesAutoresizingMaskIntoConstraints = false
        summaryTF.translatesAutoresizingMaskIntoConstraints = false
        bodyTV.translatesAutoresizingMaskIntoConstraints = false
        screenshotPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        
        githubUsernameTF.placeholder = "GitHub username (optional)"
        summaryTF.placeholder = "Summary"
        bodyTV.placeholder = "What was wrong? What can we improve?"
        
        addSubview(githubUsernameTF)
        addSubview(summaryTF)
        addSubview(bodyTV)
        addSubview(screenshotPreviewImageView)
        
        NSLayoutConstraint.activate([
            githubUsernameTF.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            githubUsernameTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            githubUsernameTF.centerXAnchor.constraint(equalTo: centerXAnchor),
            githubUsernameTF.heightAnchor.constraint(equalToConstant: 44),
            
            summaryTF.topAnchor.constraint(equalTo: githubUsernameTF.bottomAnchor),
            summaryTF.leadingAnchor.constraint(equalTo: githubUsernameTF.leadingAnchor),
            summaryTF.trailingAnchor.constraint(equalTo: githubUsernameTF.trailingAnchor),
            summaryTF.heightAnchor.constraint(equalTo: githubUsernameTF.heightAnchor),
            
            bodyTV.topAnchor.constraint(equalTo: summaryTF.bottomAnchor),
            bodyTV.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5),
            bodyTV.leadingAnchor.constraint(equalTo: summaryTF.leadingAnchor),
            bodyTV.trailingAnchor.constraint(equalTo: summaryTF.trailingAnchor),
            
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
