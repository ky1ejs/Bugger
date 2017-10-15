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
    
    init(screenshot: UIImage, config: BuggerConfig) {
        self.config = config
        self.annotationView = AnnotationView(image: screenshot)
        
        super.init(nibName: nil, bundle: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextStep))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() { view = annotationView }
    
    @objc private func nextStep() {
        let reportVC = ReportViewController(screenshot: annotationView.imageView.image!, config: config)
        navigationController?.pushViewController(reportVC, animated: true)
    }
    
    @objc private func cancel() {
        Bugger.state = .watching(config)
    }
    
    // Drawing
    
    var lastPoint = CGPoint.zero
    var swiped = false
    
    let strokeWidth: CGFloat = 5
    
    var drawingRect: CGRect { return annotationView.imageView.bounds }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: annotationView.imageView)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 6
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: annotationView.imageView)
            drawLine(from: lastPoint, to: currentPoint)
            
            // 7
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            // draw a single point
            drawLine(from: lastPoint, to: lastPoint)
        }
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        // 1
        UIGraphicsBeginImageContext(drawingRect.size)
        let context = UIGraphicsGetCurrentContext()
        annotationView.imageView.image?.draw(in: annotationView.imageView.bounds)
        
        // 2
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        // 3
        context?.setLineCap(.round)
        context?.setLineWidth(strokeWidth)
        context?.setStrokeColor(annotationView.controlView.selectedColor.cgColor)
        context?.setBlendMode(.normal)
        
        // 4
        context?.strokePath()
        
        // 5
        annotationView.imageView.image = UIImage(cgImage: context!.makeImage()!)
        UIGraphicsEndImageContext()
    }
}
