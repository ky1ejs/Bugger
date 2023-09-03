//
//  ReportView.swift
//  BuggerLinear
//
//  Created by Kyle Satti on 9/2/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit
import HelpfulUI

class ReportView: UIView {
    let titleTF = ChainedTextField()
    let descriptionTF = PlaceholderTextView()
    let screenshotPreviewImageView = UIImageView()

    init(screenshot: UIImage) {
        super.init(frame: .zero)

        screenshotPreviewImageView.image = screenshot

        titleTF.placeholder = "title"
        titleTF.returnKeyType = .next
        titleTF.nextControl = descriptionTF

        descriptionTF.placeholder = "description"

        let views = [titleTF, descriptionTF, screenshotPreviewImageView]
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        views.forEach(addSubview)

        NSLayoutConstraint.activate([
            titleTF.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            titleTF.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleTF.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleTF.heightAnchor.constraint(equalToConstant: 44),

            descriptionTF.topAnchor.constraint(equalTo: titleTF.bottomAnchor),
            descriptionTF.leadingAnchor.constraint(equalTo: titleTF.leadingAnchor),
            descriptionTF.trailingAnchor.constraint(equalTo: titleTF.trailingAnchor),
            descriptionTF.heightAnchor.constraint(equalTo: titleTF.heightAnchor),

            screenshotPreviewImageView.topAnchor.constraint(equalTo: descriptionTF.bottomAnchor, constant: 20),
            screenshotPreviewImageView.leadingAnchor.constraint(equalTo: descriptionTF.leadingAnchor),
            screenshotPreviewImageView.widthAnchor.constraint(equalTo: screenshotPreviewImageView.heightAnchor, multiplier: screenshot.size.width / screenshot.size.height),
            screenshotPreviewImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

