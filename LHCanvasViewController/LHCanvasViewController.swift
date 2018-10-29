//
//  LHCanvasViewController.swift
//  Testing
//
//  Created by 許立衡 on 2018/10/26.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit
import LHColorPickerController
import LHMenuController

public protocol LHCanvasViewControllerDelegate: AnyObject {
    func canvasViewController(_ canvasVC: LHCanvasViewController, didSave image: UIImage)
    func canvasViewControllerDidCancel(_ canvasVC: LHCanvasViewController)
}

open class LHCanvasViewController: UIViewController {
    
    enum StrokeType {
        case pen, eraser
    }
    private var strokeType: StrokeType = .pen {
        didSet {
            penButton.isEnabled = strokeType != .pen
            eraserButton.isEnabled = strokeType != .eraser
        }
    }
    private var strokeColor: UIColor = .black {
        didSet {
            colorButton.tintColor = strokeColor
        }
    }
    private var strokeWidth: CGFloat = 5

    @IBOutlet private weak var navigationBar: UINavigationBar!
    @IBOutlet private weak var toolBar: UIToolbar!
    @IBOutlet private weak var penButton: UIBarButtonItem!
    @IBOutlet private weak var eraserButton: UIBarButtonItem!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var canvasView: LHCanvasView!
    @IBOutlet private weak var undoButton: UIBarButtonItem!
    @IBOutlet private weak var colorButton: UIBarButtonItem!
    
    weak open var delegate: LHCanvasViewControllerDelegate?
    
    public init(image: UIImage?) {
        super.init(nibName: nil, bundle: Bundle.init(for: LHCanvasViewController.self))
        if let image = image {
            loadViewIfNeeded()
            canvasView.undoManager.disableUndoRegistration()
            canvasView.replaceImage(with: image)
            canvasView.undoManager.enableUndoRegistration()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        canvasView.delegate = self
        strokeType = .pen
        strokeColor = .black
        updateButtons()
        navigationBar.delegate = self
        toolBar.delegate = self
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolBar.clipsToBounds = true
    }
    
    @IBAction private func didPressUndoButton(_ sender: UIBarButtonItem) {
        let undoMenuController = LHUndoMenuController(undoManager: canvasView.undoManager, barButtonItem: sender)
        present(undoMenuController, animated: true, completion: nil)
    }
    
    @IBAction private func didPressPenButton(_ sender: Any) {
        strokeType = .pen
    }
    
    @IBAction private func didPressClearButton(_ sender: UIBarButtonItem) {
        canvasView.replaceImage(with: nil, actionName: NSLocalizedString("Clear Canvas", comment: ""))
    }
    
    @IBAction private func didPressEraserButton(_ sender: Any) {
        strokeType = .eraser
    }
    
    @IBAction private func didPressColorButton(_ sender: UIBarButtonItem) {
        let colorPicker = LHColorPickerController { color in
            self.strokeColor = color
        }
        if let popoverController = colorPicker.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        present(colorPicker, animated: true, completion: nil)
    }
    
    @IBAction private func didPressSizeButton(_ sender: UIBarButtonItem) {
        let sliderVC = LHSliderViewController(min: 1, max: 100, current: Float(strokeWidth), barButtonItem: sender) { value in
            self.strokeWidth = CGFloat(value)
        }
        present(sliderVC, animated: true, completion: nil)
    }
    
    @IBAction private func didPressCancelButton(_ sender: Any) {
        delegate?.canvasViewControllerDidCancel(self)
    }
    
    @IBAction private func didPressSaveButton(_ sender: Any) {
        guard let image = canvasView.image else { return }
        delegate?.canvasViewController(self, didSave: image)
    }
    
}

extension LHCanvasViewController: LHCanvasViewDelegate {
    
    public func lineConfigurator(for canvasView: LHCanvasView) -> LHCanvasView.LineConfigurationHandler? {
        switch strokeType {
        case .pen:
            return {
                $0.setStrokeColor(self.strokeColor)
                $0.setLineWidth(self.strokeWidth)
            }
        case .eraser:
            return {
                $0.setStrokeColor(.white)
                $0.setLineWidth(20)
            }
        }
    }
    
    private func updateButtons() {
        saveButton.isEnabled = canvasView.undoManager.canUndo
    }
    
    public func canvasViewDidChange(_ canvasView: LHCanvasView) {
        updateButtons()
    }
    
}

extension LHCanvasViewController: UINavigationBarDelegate, UIToolbarDelegate {
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        if bar === navigationBar {
            return .topAttached
        } else if bar === toolBar {
            return .bottom
        } else {
            return .any
        }
    }
    
}
