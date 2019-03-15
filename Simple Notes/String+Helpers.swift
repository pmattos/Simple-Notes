//
//  String+Helpers.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 11/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import Foundation

/// General `String` helpers.
extension String {

    /// Returns an array of all the lines in this string.
    /// The new line terminator is *not* included in each line.
    var lines: [String] {
        return self.components(separatedBy: "\n")
    }
}

// MARK: -

/// General `NSString` helpers.
extension NSString {

    /// Returns this string *full* range.
    var range: NSRange {
        return NSRange(location: 0, length: length)
    }
}

// MARK: -

/// General `NSAttributedString` helpers.
extension NSAttributedString {

    /// Returns this string *full* range.
    var range: NSRange {
        return NSRange(location: 0, length: length)
    }
    
    /// Returns the range of characters representing the line
    /// or lines containing the specified index.
    func lineRange(for index: Int) -> NSRange {
        let charRange = NSRange(location: index, length: 0)
        return (self.string as NSString).lineRange(for: charRange)
    }
    
    /// Returns the character in the specified index, if any.
    func character(at charIndex: Int) -> String? {
        let string = self.string as NSString
        guard charIndex >= 0 && charIndex < string.length else {
            return nil
        }
        return string.substring(with: NSRange(location: charIndex, length: 1))
    }

    /// Enumerates all the lines in this attributed string.
    /// This *also* includes the new line terminator as well.
    func enumerateLines(invoking body: (NSAttributedString) -> Void) {
        let string = self.string as NSString
        var lineStart = 0, lineEnd = 0
        
        while lineStart < string.length {
            string.getLineStart(
                &lineStart,
                end: &lineEnd,
                contentsEnd: nil,
                for: NSRange(location: lineStart, length: 0)
            )
            let lineRange = NSRange(location: lineStart, length: lineEnd - lineStart)
            let line = self.attributedSubstring(from: lineRange)
            
            body(line)
            lineStart = lineEnd
        }
    }

    /// Returns a new attributed string containing the results
    /// of mapping the given closure over each string's line.
    /// Each provided line *also* includes the new line terminator as well.
    func mapLines(
        transform: (NSAttributedString) -> NSAttributedString) -> NSAttributedString {
        let transformedString = NSMutableAttributedString()
        self.enumerateLines {
            (line) in
            transformedString.append(transform(line))
        }
        return transformedString
    }

    /// Returns all attribute values and ranges in the specified range.
    func attribute(_ attribKey: NSAttributedString.Key,
                   in range: NSRange) -> [(value: Any, range: NSRange)] {
        var result: [(value: Any, range: NSRange)] = []
        self.enumerateAttribute(attribKey, in: range) {
            (value, range, stop) in
            guard let value = value else { return }
            result.append((value, range))
        }
        return result
    }
}

// MARK: -

/// General `NSMutableAttributedString` helpers.
extension NSMutableAttributedString {
    
    /// Adds to the end of this string the characters of the specified string.
    /// This **will** extend the previous attributes to the new string as well.
    func append(_ string: String) {
        self.mutableString.append(string)
    }
    
    /// Sets the attribute for the characters in
    /// the specified range to the specified value.
    func setAttribute(_ attrib: NSAttributedString.Key, value: Any, range: NSRange) {
        self.setAttributes([attrib: value], range: range)
    }
}

// MARK: - Regular Expressions

func regex(_ pattern: String) -> NSRegularExpression {
    return try! NSRegularExpression(pattern: pattern)
}

extension NSRegularExpression {

    func firstMatch(in string: String) -> NSTextCheckingResult? {
        let fullRange = (string as NSString).range
        return self.firstMatch(in: string, range: fullRange)
    }
}

// MARK: - Misc

extension NSRange {
    
    func nextChar() -> NSRange {
        return NSRange(location: self.location + 1, length: self.length)
    }
}
