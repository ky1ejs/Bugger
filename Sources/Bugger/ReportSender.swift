//
//  ReportSender.swift
//  Bugger
//
//  Created by Kyle Satti on 8/31/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit

public typealias BuggerCompletionHandler = () -> Void

public struct ReportParams {
    public let screenshot: UIImage
    public let appWindow: UIWindow
    public let completionHandler: BuggerCompletionHandler
}
