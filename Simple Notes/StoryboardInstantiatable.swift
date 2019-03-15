//
//  StoryboardInstantiatable.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 11/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import UIKit

// MARK: - Instantiating View Controllers from Storyboards

/// A view controller that can be instantiable from a storyboard.
protocol StoryboardInstantiatable: class {
    
    /// Instantiates and returns the view controller using the class name as identifier.
    static func instantiate() -> Self
    
    /// Instantiates and returns the view controller with the specified identifier.
    static func instantiate(withIdentifier identifier: String) -> Self
    
    /// The name of the corresponding storyboard file (default is `"Main"`).
    static var storyboardFilename: String { get }
}

extension StoryboardInstantiatable where Self: UIViewController {
    
    static func instantiate() -> Self {
        let viewControllerClassName = self.className
        return instantiate(withIdentifier: viewControllerClassName)
    }
    
    static func instantiate(withIdentifier identifier: String) -> Self {
        let mainStoryboard = UIStoryboard(name: self.storyboardFilename, bundle: nil)
        return mainStoryboard.instantiateViewController(withIdentifier: identifier) as! Self
    }
    
    static var storyboardFilename: String {
        return "Main"
    }
}
