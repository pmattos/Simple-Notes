//
//  NSObject+Helpers.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 11/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import Foundation

/// Helpers for `NSObject` subclasses.
extension NSObject {
    
    /// Returns this instance simple class name.
    var className: String {
        let dynamicType = type(of: self)
        return dynamicType.className
    }
    
    /// Returns this class simple name.
    class var className: String {
        let fullName = String(describing: self)
        let nameComponents = fullName.components(separatedBy: ".")
        return nameComponents.last!
    }
}
