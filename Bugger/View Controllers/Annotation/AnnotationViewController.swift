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
    let appWindow: UIWindow
    
    init(appWindow: UIWindow, config: BuggerConfig) {
        self.config = config
        self.annotationView = AnnotationView(image: appWindow.snapshot())
        self.appWindow = appWindow
        
        super.init(nibName: nil, bundle: nil)
        
        annotationView.controlView.undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
        annotationView.controlView.redoButton.addTarget(self, action: #selector(redo), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(nextStep))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func loadView() { view = annotationView }
    
    @objc private func nextStep() {
        let reportVC = ReportViewController(appWindow: appWindow, screenshot: annotationView.imageView.image!, config: config)
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
        guard let touch = touches.first, touch.isLocated(in: annotationView.imageView) else { return }
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(set(image:)), object: annotationView.imageView.image)
        
        swiped = false
        lastPoint = touch.location(in: annotationView.imageView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.isLocated(in: annotationView.imageView) else { return }
        
        // 6
        swiped = true
        let currentPoint = touch.location(in: annotationView.imageView)
        drawLine(from: lastPoint, to: currentPoint)
        
        // 7
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch.isLocated(in: annotationView.imageView) else { return }
        
        if !swiped {
            // draw a single point
            drawLine(from: lastPoint, to: lastPoint)
        }
        updateUndoButtons()
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
    
    @objc func undo() {
        undoManager?.undo()
        updateUndoButtons()
    }
    
    @objc func redo() {
        undoManager?.redo()
        updateUndoButtons()
    }
    
    func updateUndoButtons() {
        annotationView.controlView.undoButton.isEnabled = undoManager?.canUndo ?? false
        annotationView.controlView.redoButton.isEnabled = undoManager?.canRedo ?? false
    }
    
    @objc func set(image: UIImage) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(set(image:)), object: annotationView.imageView.image)
        annotationView.imageView.image = image
    }
}
