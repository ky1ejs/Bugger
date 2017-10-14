//
//  AnnotationViewController.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class AnnotationViewController: UIViewController {
    let config: BuggerConfig
    let annotationView: AnnotationView
    let screenshot: UIImage
    
    init(screenshot: UIImage, config: BuggerConfig) {
        self.config = config
        self.screenshot = screenshot
        annotationView = AnnotationView(image: screenshot)
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextStep))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() { view = annotationView }
    
    @objc private func nextStep() {
        let reportVC = ReportViewController(screenshot: screenshot, config: config)
        navigationController?.pushViewController(reportVC, animated: true)
    }
}
