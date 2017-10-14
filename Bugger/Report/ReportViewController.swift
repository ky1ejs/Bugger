//
//  ReportViewController.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit

class ReportViewController: UIViewController {
    let config: BuggerConfig
    let reportView = ReportView()
    
    init(annotatedScreenshot: UIImage, config: BuggerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = reportView
    }
    
    func send() {
        // upload screenshots and videos to S3
        // create GH ticket and submit data
    }
}
