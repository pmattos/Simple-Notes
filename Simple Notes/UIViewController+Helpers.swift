//
//  UIViewController+Helpers.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 11/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import UIKit

/// General helpers for common view controller behaviour.
extension UIViewController {
    
    // MARK: - Showing Nested View Controllers
    
    /// Adds the specified view controller as a child of the current view controller
    /// in the specified content view (and completes the transition).
    ///
    /// To mark the controller transition complete, this method
    /// also calls the `didMove` callback for the child controller.
    func addContentController(_ contentController: UIViewController, in contentView: UIView) {
        precondition(contentController.parent == nil)
        precondition(contentController.view.superview == nil)
        
        let containerBounds = contentView.bounds
        contentController.view.frame = containerBounds
        contentView.addSubview(contentController.view)
        
        // Resizing performed by expanding or shrinking a view's width & height.
        contentView.autoresizesSubviews = true
        contentController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addChild(contentController)
        contentController.didMove(toParent: self)
    }
    
    /// Removes the specified view controller from the
    /// children list of the current view controller
    func removeContentController(_ contentController: UIViewController) {
        precondition(contentController.parent === self)
        
        contentController.willMove(toParent: nil)
        contentController.view.removeFromSuperview()
        contentController.removeFromParent()
    }
    
    // MARK: - Showing Alert Controllers

    typealias AlertActionHandler = ((UIAlertAction) -> Void)?

    /// Shows an alert with a single **OK** button.
    func showAlert(
        title: String, message: String,
        actionTitle: String = "OK",
        actionHandler: AlertActionHandler = nil) {
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: actionTitle,
            style: .default,
            handler: actionHandler
        )
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: -

extension UINavigationBar {
    
    private static let transparentImage = UIImage.singlePixelImage(withColor: UIColor.clear)
    
    /// Configures a navigation bar with a
    /// fully transparent background (`true`) or not (`false`).
    func setTransparentBackground(_ transparentBackground: Bool) {
        if transparentBackground {
            self.setBackgroundImage(UINavigationBar.transparentImage, for: .default)
            self.hideBottomSeparator(true)
        } else {
            self.setBackgroundImage(nil, for: .default)
            self.hideBottomSeparator(false)
        }
    }
    
    private func hideBottomSeparator(_ hide: Bool) {
        self.shadowImage = hide ? UINavigationBar.transparentImage : nil
    }
}

// MARK: - Helpers

fileprivate extension UIImage {
    
    /// Creates a single pixel image with the specified color.
    class func singlePixelImage(withColor color: UIColor) -> UIImage {
        let imageRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        
        UIGraphicsBeginImageContext(imageRect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(imageRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension CGRect {
    
    var center: CGPoint {
        return CGPoint(x: origin.x + width/2, y: origin.y + height/2)
    }
}

