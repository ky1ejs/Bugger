//
//  ReportViewController.swift
//  Bugger
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import HelpfulUI

public class ReportViewController: KeyboardAnimationVC {
    let config: GitHubConfig
    let reportView: ReportView
    let screenshot: UIImage
    let appWindow: UIWindow
    let completionHandler: () -> Void
    
    var reportViewBottomConstraint: NSLayoutConstraint?
    
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
    
    public init(reportParams: ReportParams, gitHubConfig: GitHubConfig) {
        reportView = ReportView(screenshot: reportParams.screenshot)
        config = gitHubConfig
        appWindow = reportParams.appWindow
        screenshot = reportParams.screenshot
        completionHandler = reportParams.completionHandler
        super.init(nibName: nil, bundle: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(send))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        view.addSubview(reportView)
        
        reportView.translatesAutoresizingMaskIntoConstraints = false
        
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: reportView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: reportView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: reportView.trailingAnchor).isActive = true
        
        reportViewBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: reportView.bottomAnchor)
        reportViewBottomConstraint?.isActive = true
    }
    
    @objc func send() {
        guard case .editing = state else { return }
        
        do {
            let report = try Report(githubUsername: reportView.githubUsernameTF.text,
                                  summary: reportView.summaryTF.text,
                                  body: reportView.bodyTV.text,
                                  appWindow: appWindow,
                                  screenshot: screenshot)
            
            state = .loading(UIActivityIndicatorView(style: .medium))
            report.send(with: config) { result in
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                switch result {
                case .success(let url):
                    self.state = .editing
                    alert.title = "Thank you! 🎉"
                    alert.message = "We've received your feedback and will review it soon!\n\n\(url)"
                    alert.addAction(UIAlertAction(title: "☺️", style: .cancel, handler: { [weak self] _ in
                        self?.completionHandler()
                    }))
                case .error(let error):
                    alert.title = "Error ☹️"
                    alert.message = error.errorMessage
                    alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                }
                self.present(alert, animated: true, completion: nil)
            }
        } catch let error {
            let alert = UIAlertController(title: "Error", message: error.errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    public override func keyboardAnimations(to keyboardHeight: CGFloat) {
        reportViewBottomConstraint?.isActive = false
        reportViewBottomConstraint = reportView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardHeight)
        reportViewBottomConstraint?.isActive = true
    }
}

enum ReportViewControllerState {
    case editing
    case loading(UIActivityIndicatorView)
}
