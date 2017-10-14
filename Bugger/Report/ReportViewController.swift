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
    let screenshot: UIImage
    
    init(screenshot: UIImage, config: BuggerConfig) {
        self.config = config
        self.screenshot = screenshot
        super.init(nibName: nil, bundle: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(send))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(reportView)
        
        reportView.translatesAutoresizingMaskIntoConstraints = false
        
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: reportView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: reportView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: reportView.trailingAnchor).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: reportView.bottomAnchor).isActive = true
    }
    
    @objc func send() {
        guard let title = reportView.titleTF.text, title.count > 0 else { return }
        guard let username = reportView.usernameTF.text, username.count > 0 else { return }
        guard let githubEmail = reportView.githubEmailTF.text, githubEmail.count > 0 else { return }
        guard let body = reportView.bodyTV.text, body.count > 0 else { return }
        
        Report(title: title, username: username, githubUsername: githubEmail, body: body, image: screenshot).send(with: config)
    }
}
