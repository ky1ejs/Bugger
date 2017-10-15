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
    let reportView: ReportView
    let screenshot: UIImage
    var state: ReportViewControllerState = .editing {
        didSet {
            if case .loading(let spinner) = oldValue {
                spinner.removeFromSuperview()
            }
            
            if case .loading(let spinner) = state {
                navigationItem.rightBarButtonItem?.isEnabled = false
                navigationItem.backBarButtonItem?.isEnabled = false
                reportView.subviews.forEach() { view in
                    view.resignFirstResponder()
                    view.isUserInteractionEnabled = false
                }
                
                reportView.addSubview(spinner)
                spinner.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: reportView.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: reportView.centerYAnchor)
                ])
                spinner.startAnimating()
            }
            
            if case .editing = state {
                navigationItem.rightBarButtonItem?.isEnabled = true
                navigationItem.backBarButtonItem?.isEnabled = true
                reportView.subviews.forEach() { view in
                    view.resignFirstResponder()
                    view.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    init(screenshot: UIImage, config: BuggerConfig) {
        self.reportView = ReportView(screenshot: screenshot)
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
        guard case .editing = state else { return }
        guard let title = reportView.titleTF.text, title.count > 0 else { return }
        guard let username = reportView.usernameTF.text, username.count > 0 else { return }
        guard let githubEmail = reportView.githubEmailTF.text, githubEmail.count > 0 else { return }
        guard let body = reportView.bodyTV.text, body.count > 0 else { return }
        
        let report = Report(title: title,
                            username: username,
                            githubUsername: githubEmail,
                            body: body,
                            image: screenshot)
        
        state = .loading(UIActivityIndicatorView(activityIndicatorStyle: .gray))
        report.send(with: config) { success in
            if success {
                Bugger.state = .watching(self.config)
            } else {
                let alert = UIAlertController(title: "Error", message: "Your feedback could not be reported", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

enum ReportViewControllerState {
    case editing
    case loading(UIActivityIndicatorView)
}
