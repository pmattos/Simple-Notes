//
//  NoteTextStorage.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 12/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import UIKit

/// Stores a given note text with rich formatting.
/// This implements the core text formatting engine.
final class NoteTextStorage: NSTextStorage {

    fileprivate let backingStore = NSMutableAttributedString()
    fileprivate var backingString: NSString { return backingStore.string as NSString }
    
    // MARK: - Storage Initialization
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        wordsFormatter.storage = self
        listsFormatter.storage = self
    }
    
    // MARK: - NSTextStorage Subclassing Requirements
    
    /// The character contents of the storage as an `NSString` object.
    override var string: String {
        return backingStore.string
    }
    
    /// Returns the attributes for the character at a given index.
    override func attributes(
        at location: Int,
        effectiveRange range: NSRangePointer?)
        -> [NSAttributedString.Key: Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }

    /// Replaces the characters in the given range
    /// with the characters of the specified string.
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    /// Sets the attributes for the characters in
    /// the specified range to the specified attributes.
    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    // MARK: - Rich Text Formatting
    
    private let bodyFont = UIFont.systemFont(ofSize: 18)
    
    var bodyStyle: [NSAttributedString.Key: Any] {
        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.paragraphSpacingBefore = 2.5
        
        return [
            .paragraphStyle: bodyParagraphStyle,
            .font: bodyFont,
            .kern: NSNumber(value: 0.0)
        ]
    }
    
    private let wordsFormatter = WordsFormatter()
    private let listsFormatter = ListsFormatter()

    private func performRichFormatting(in editedRange: NSRange,
                                       with editedMask: EditActions) -> FormattedText? {
        let lineRange = backingStore.lineRange(for: editedRange.location)
        let editedLineRange = NSUnionRange(editedRange, lineRange)
        let editedString = backingString.substring(with: editedRange)

        /*
         let maxLineRange = backingString.lineRange(
             for: NSMakeRange(editedRange.upperBound, 0))
         editedLineRange = NSUnionRange(editedRange, maxLineRange)
         */

        let changedText = ChangedText(
            contents: editedString,
            mask: editedMask,
            range: editedRange,
            lineRange: editedLineRange,
            listItem: listsFormatter.listItem(at: editedLineRange)
        )
        
        #if DEBUG
        print(changedText.description)
        #endif
        
        let formatters = [wordsFormatter.formatWords, listsFormatter.formatLists]
        for format in formatters {
            if let formattedText = format(changedText) {
                return formattedText
            }
        }
        return nil
    }
    
    private var lastEditedRange: NSRange?
    private var lastEditedMask: NSTextStorage.EditActions?

    func processRichFormatting() -> FormattedText? {
        if let lastEditedRange = self.lastEditedRange,
            let lastEditedMask = self.lastEditedMask {
            return performRichFormatting(in: lastEditedRange, with: lastEditedMask)
        }
        return nil
    }

    override func processEditing() {
        lastEditedRange = editedRange
        lastEditedMask  = editedMask
        super.processEditing()
    }
    
    // MARK: - Checkmarks Support
    
    func insertCheckmark(atLine lineRange: NSRange, withValue value: Bool = false) {
        listsFormatter.insertListItem(.checkmark(value), atLine: lineRange)
    }
    
    func setCheckmark(atLine lineRange: NSRange, to value: Bool) {
        listsFormatter.updateListItem(.checkmark(value), atLine: lineRange)
    }
    
    // MARK: - Note IO
    
    /// Loads the specified Markdown-ish formatted note.
    func load(note: String) {
        var noteString = NSAttributedString(string: note, attributes: bodyStyle)
        
        let formatters = [wordsFormatter.format, listsFormatter.format]
        for format in formatters {
            noteString = format(noteString)
        }
        setAttributedString(noteString)
    }

    /// Returns a Markdown-ish formatted note with this text contents.
    func deformatted() -> String {
        var markdownString = NSAttributedString(attributedString: self)
        
        let deformatters = [wordsFormatter.deformat, listsFormatter.deformat]
        for deformat in deformatters {
            markdownString = deformat(markdownString)
        }
        return markdownString.string
    }
}

// MARK: - Formatting Metadata

/// Metadata about the interactive changes, in the text, made by the user.
fileprivate struct ChangedText: CustomStringConvertible {
    var contents: String
    var mask: NSTextStorage.EditActions
    var range: NSRange
    var lineRange: NSRange
    var listItem: ListItem?
    
    var isNewLine: Bool {
        return contents == "\n" && mask.contains(.editedCharacters)
    }
    
    var description: String {
        let change: String
        switch contents {
        case " ":
            change = "<space>"
        case "\n":
            change = "<newline>" //+ (isNewLine ? "+" : "?")
        default:
            change = "\"\(contents)\""
        }
        
        var extras: [String] = []
        extras.append("line \(lineRange)")
        if let listStyle = listItem {
            extras.append("\(listStyle)")
        }
        let extrasDescription = extras.joined(separator: ", ")
        
        return "ChangedText: \(change) at \(range) (\(extrasDescription))"
    }
}

/// Metadata about the resulting formatted text, if any.
struct FormattedText {
    var caretRange: NSRange?
    
    init(caretRange: NSRange? = nil) {
        self.caretRange = caretRange
    }
}

fileprivate class Formatter {
    
    fileprivate weak var storage: NoteTextStorage!
    fileprivate var backingStore: NSMutableAttributedString { return storage.backingStore }
    
    var bodyStyle: [NSAttributedString.Key: Any] { return storage.bodyStyle }

    func formattedText(caretAtLine index: Int) -> FormattedText {
        let lineRange = storage.lineRange(for: index)
        return FormattedText(caretRange: lineRange)
    }
}

extension NSAttributedString.Key {
    
    /// Indicates the last character *before* the fixed caret location.
    static let caret = NSAttributedString.Key("markdown.caret")
}

// MARK: - Words Formatting

fileprivate extension NSAttributedString.Key {
    static let italic = NSAttributedString.Key("markdown.italic")
    static let bold   = NSAttributedString.Key("markdown.bold")
}

fileprivate final class WordsFormatter: Formatter {
    
    private struct WordFormat {
        var key: NSAttributedString.Key
        var regex: NSRegularExpression
        var style: [NSAttributedString.Key: Any]
        var enclosingChars: String
        
        func markdown(for text: String) -> String {
            return "\(enclosingChars)\(text)\(enclosingChars)"
        }
    }

    private let italicFormat = WordFormat(
        key: .italic,
        regex: regex("(?<=^|[^*])[*_]{1}(?<text>\\w+(\\s+\\w+)*)[*_]{1}"),
        style: [.italic: true, .font: UIFont.italicSystemFont(ofSize: 18)],
        enclosingChars: "*"
    )

    private let boldFormat = WordFormat(
        key:   .bold,
        regex: regex("[*_]{2}(?<text>\\w+(\\s+\\w+)*)[*_]{2}"),
        style: [.bold: true, .font: UIFont.systemFont(ofSize: 18, weight: .bold)],
        enclosingChars: "**"
    )

    func formatWords(in change: ChangedText) -> FormattedText? {
        for wordsFormat in [boldFormat, italicFormat] {
            if let formattedText = formatWords(in: change, using: wordsFormat) {
                return formattedText
            }
        }
        return nil
    }

    private func formatWords(in change: ChangedText,
                             using format: WordFormat) -> FormattedText? {
        let match = format.regex.firstMatch(in: backingStore.string, range: change.lineRange)

        if let match = match {
            // Captures the target text.
            let text = storage.backingString.substring(with: match.range(withName: "text"))
            let attribText = NSMutableAttributedString(
                string: text,
                attributes: format.style
            )

            // Adds trailing whitespace if needed.
            let nextChar = storage.character(at: match.range.max)
            if nextChar == nil || nextChar != " " {
                attribText.append(NSAttributedString(string: " ", attributes: bodyStyle))
            }

            // Fixes caret position and applies words formatting.
            attribText.addAttribute(
                .caret, value: true,
                range: NSMakeRange(attribText.length - 1, 1)
            )
            storage.replaceCharacters(in: match.range, with: attribText)
            return formattedText(caretAtLine: match.range.location)
        } else {
            return nil
        }
    }
    
    func format(_ markdownString: NSAttributedString) -> NSAttributedString {
        var markdownString = markdownString
        for wordsFormat in [boldFormat, italicFormat] {
            markdownString = format(markdownString, using: wordsFormat)
        }
        return markdownString
    }
    
    private func format(_ markdownString: NSAttributedString,
                        using format: WordFormat) -> NSAttributedString {
        return markdownString.mapLines {
            (attribLine) in
            let line = attribLine.string
            let lineRange = attribLine.range
            
            let mutableLine = NSMutableAttributedString(attributedString: attribLine)
            let matches = format.regex.matches(in: line, range: lineRange)
            
            for match in matches.reversed() {
                let text = (line as NSString).substring(with: match.range(withName: "text"))
                let formattedText = NSAttributedString(string: text, attributes: format.style)
                mutableLine.replaceCharacters(in: match.range, with: formattedText)
            }
            return mutableLine
        }
    }
    
    func deformat(_ formattedString: NSAttributedString) -> NSAttributedString {
        var markdownString = formattedString
        for wordsFormat in [boldFormat, italicFormat] {
            markdownString = deformat(markdownString, using: wordsFormat)
        }
        return markdownString
    }
    
    private func deformat(_ attribString: NSAttributedString,
                          using format: WordFormat) -> NSAttributedString {
        return attribString.mapLines {
            (attribLine) in
            let line = attribLine.string as NSString
            let mutableLine = NSMutableAttributedString(attributedString: attribLine)
            let attribs = attribLine.attribute(format.key, in: attribLine.range)
            
            for attrib in attribs.reversed() {
                let text = line.substring(with: attrib.range)
                let markdownText = format.markdown(for: text)
                mutableLine.removeAttribute(format.key, range: attrib.range)
                mutableLine.replaceCharacters(in: attrib.range, with: markdownText)
            }
            return mutableLine
        }
    }
}

// MARK: - Lists Formatting

extension NSAttributedString.Key {
    static let list = NSAttributedString.Key("markdown.list")
}

let zeroWidthSpace = "\u{200B}"

/// Identifies a given list item (or list kind).
/// This is used as the *value* for the `NSAttributedString.Key.list` custom attribute.
enum ListItem: CaseIterable, CustomStringConvertible {
    
    case bullet
    case dashed
    case ordered(Int?)
    case checkmark(Bool?)

    static let allCases = [bullet, dashed, ordered(nil), checkmark(nil)]

    var description: String {
        return "\(rawValue) list"
    }
    
    var itemMarker: String {
        switch self {
        case .bullet:
            return "•"
        case .dashed:
            return "–"
        case .ordered(let number):
            return "\(number!)."
        case .checkmark:
            return zeroWidthSpace
        }
    }

    var nextItem: ListItem {
        switch self {
        case .bullet:
            return self
        case .dashed:
            return self
        case .ordered(let number):
            return .ordered(number! + 1)
        case .checkmark:
            return .checkmark(false)
        }
    }

    private static let bulletItemRegex    = regex("^([*]\\h).*")
    private static let dashedItemRegex    = regex("^([-]\\h).*")
    private static let orderedItemRegex   = regex("^((?<number>[0-9]+)[.]\\h).*")
    private static let checkmarkItemRegex = regex("^(\\[(?<bool>_|x)\\]\\h).*")

    var itemRegex: NSRegularExpression {
        switch self {
        case .bullet:
            return ListItem.bulletItemRegex
        case .dashed:
            return ListItem.dashedItemRegex
        case .ordered:
            return ListItem.orderedItemRegex
        case .checkmark:
            return ListItem.checkmarkItemRegex
        }
    }
    
    func firstMatch(in string: String, range: NSRange) -> (kind: ListItem, range: NSRange)? {
        guard let match = itemRegex.firstMatch(in: string, range: range) else {
            return nil
        }
        switch self {
        case .bullet, .dashed:
            return (self, match.range(at: 1))
        case .ordered:
            let numberRange = match.range(withName: "number")
            let number = (string as NSString).substring(with: numberRange)
            return (.ordered(Int(number)), match.range(at: 1))
        case .checkmark:
            let boolRange = match.range(withName: "bool")
            let boolFlag = (string as NSString).substring(with: boolRange)
            let bool: Bool
            switch boolFlag {
            case "_":
                bool = false
            case "x":
                bool = true
            default:
                preconditionFailure("Unknown bool flag: \(boolFlag)")
            }
            return (.checkmark(bool), match.range(at: 1))
        }
    }

    var paragraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.headIndent = 10
        paragraphStyle.paragraphSpacingBefore = 2.5

        switch self {
        case .bullet, .dashed, .ordered:
            break
        case .checkmark:
            paragraphStyle.firstLineHeadIndent = 24
            paragraphStyle.headIndent = 24
            //paragraphStyle.minimumLineHeight = 20
            paragraphStyle.paragraphSpacing = 8
            //paragraphStyle.lineSpacing = 8
        }
        return paragraphStyle
    }

    var kern: NSNumber {
        switch self {
        case .bullet, .dashed:
            return NSNumber(value: 6.5)
        case .ordered:
            return NSNumber(value: 3.5)
        case .checkmark:
            return NSNumber(value: 0.0)
        }
    }
    
    var markdownPrefix: String {
        switch self {
        case .bullet:
            return "* "
        case .dashed:
            return "- "
        case .ordered(let number):
            return "\(number!). "
        case .checkmark(let bool):
            if bool! {
                return "[x] "
            } else {
                return "[_] "
            }
        }
    }
}

/// Support for encoding as an attribute value.
extension ListItem: RawRepresentable {

    private static let orderedRegex = regex("ordered[(](?<number>[0-9]+)[)]")
    private static let checkmarkRegex = regex("checkmark[(](?<bool>true|false)[)]")

    init?(rawValue: String) {
        switch rawValue {
        case "bullet":
            self = .bullet
        case "dashed":
            self = .dashed
        case "ordered":
            self = .ordered(nil)
        case "checkmark":
            self = .checkmark(nil)
        default:
            if let orderedMatch = ListItem.orderedRegex.firstMatch(in: rawValue) {
                let numberRange = orderedMatch.range(withName: "number")
                let number = (rawValue as NSString).substring(with: numberRange)
                self = .ordered(Int(number))
            } else if let checkmarkMatch = ListItem.checkmarkRegex.firstMatch(in: rawValue) {
                let boolRange = checkmarkMatch.range(withName: "bool")
                let bool = (rawValue as NSString).substring(with: boolRange)
                self = .checkmark(Bool(bool)!)
            } else {
                return nil
            }
        }
    }
    
    var rawValue: String {
        switch self {
        case .bullet:
            return "bullet"
        case .dashed:
            return "dashed"
        case .ordered(let number):
            if let number = number {
                return "ordered(\(number))"
            } else {
                return "ordered"
            }
        case .checkmark(let bool):
            if let bool = bool {
                return "checkmark(\(bool))"
            } else {
                return "checkmark"
            }
        }
    }
}

fileprivate final class ListsFormatter: Formatter {

    func itemStyle(for listItem: ListItem) -> [NSAttributedString.Key: Any] {
        var itemStyle = bodyStyle
        itemStyle[.list] = listItem.rawValue
        itemStyle[.paragraphStyle] = listItem.paragraphStyle
        
        return itemStyle
    }

    private func itemMarker(for listItem: ListItem) -> NSAttributedString {
        let itemMarker = NSMutableAttributedString(
            string: listItem.itemMarker,
            attributes: itemStyle(for: listItem)
        )
        itemMarker.addAttribute(
            .kern, value: listItem.kern,
            range: NSMakeRange(itemMarker.length - 1, 1)
        )
        itemMarker.addAttribute(
            .caret, value: true,
            range: NSMakeRange(itemMarker.length - 1, 1)
        )
        return itemMarker
    }

    func listItem(at lineRange: NSRange, effectiveRange: NSRangePointer? = nil) -> ListItem? {
        let lineRange = storage.lineRange(for: lineRange.location)
        let lineStart = lineRange.location
        guard lineStart < backingStore.length else {
            return nil
        }
        let rawListKind = backingStore.attribute(
            .list,
            at: lineStart,
            longestEffectiveRange: effectiveRange,
            in: lineRange
        )
        if let rawListKind = rawListKind as? String {
            return ListItem(rawValue: rawListKind)!
        } else {
            return nil
        }
    }
    
    func insertListItem(_ listItem: ListItem, atLine lineRange: NSRange) {
        let lineStart = storage.lineRange(for: lineRange.location).location
        //let lineStart = lineRange.location
        let itemMarker = self.itemMarker(for: listItem)
        storage.replaceCharacters(in: NSMakeRange(lineStart, 0), with: itemMarker)
    }

    @discardableResult
    func updateListItem(_ newListItem: ListItem, atLine lineRange: NSRange) -> Bool {
        var listItemRange = NSMakeRange(0, 0)
        guard let oldListItem = listItem(at: lineRange, effectiveRange: &listItemRange) else {
            return false // List item not found.
        }
        switch (oldListItem, newListItem) {
        case (.bullet, .bullet), (.dashed, .dashed),
             (.ordered, .ordered), (.checkmark, .checkmark):
            storage.replaceCharacters(in: listItemRange, with: newListItem.itemMarker)
            storage.addAttribute(.list, value: newListItem.rawValue, range: listItemRange)
        default:
             preconditionFailure("List not compatible at \(lineRange)")
        }
        return true
    }

    func formatLists(for change: ChangedText) -> FormattedText? {
        for listItem in ListItem.allCases {
            // User entered an empty list item (i.e., we should end the list)?
            if let textFormatted = formatEmptyListItem(for: change) {
                return textFormatted
            }
            
            // User entered a new list item?
            if let textFormatted = formatNewListItem(for: change) {
                return textFormatted
            }
            
            // User started a new list?
            if let textFormatted = formatNewList(listItem, for: change) {
                return textFormatted
            }
        }
        return nil
    }

    private func formatNewList(_ listItem: ListItem,
                               for change: ChangedText) -> FormattedText? {
        let itemMatch = listItem.firstMatch(
            in: backingStore.string,
            range: change.lineRange
        )
        if let itemMatch = itemMatch {
            let itemMarker = self.itemMarker(for: itemMatch.kind)
            storage.replaceCharacters(in: itemMatch.range, with: itemMarker)
            return formattedText(caretAtLine: itemMatch.range.location)
        } else {
            return nil
        }
    }
    
    private func formatNewListItem(for change: ChangedText) -> FormattedText? {
        guard let listItem = change.listItem, change.isNewLine else {
            return nil
        }
        let nextItem = listItem.nextItem
        let itemMarker = self.itemMarker(for: nextItem)
        let lineStart = NSMakeRange(change.range.max, 0)
        
        storage.replaceCharacters(in: lineStart, with: itemMarker)
        switch nextItem {
        case .ordered:
            reformatFollowingOrderedItems(nextItem, at: lineStart.location)
        case .bullet, .dashed, .checkmark:
            break
        }
        return formattedText(caretAtLine: lineStart.location)
    }
    
    private func reformatFollowingOrderedItems(_ item: ListItem, at lineStart: Int) {
        var nextItem = item
        var lineStart = lineStart
        
        while true {
            let nextLine = storage.lineRange(for: lineStart).max
            guard nextLine < storage.length else { break }

            nextItem = nextItem.nextItem
            if !updateListItem(nextItem, atLine: NSMakeRange(nextLine, 0)) { break }
            lineStart = nextLine
        }
    }
    
    private func formatEmptyListItem(for change: ChangedText) -> FormattedText? {
        guard let listItem = change.listItem, change.isNewLine else {
            return nil
        }
        
        // Is this line empty (i.e., only marker + newline)?
        guard change.lineRange.length <= listItem.itemMarker.count + 1 else {
            return nil
        }
        
        // Reset the text style of the character that follows.
        let nextChar = change.lineRange.max
        if nextChar < storage.length {
            storage.replaceCharacters(in: NSMakeRange(nextChar, 0), with: " ")
            storage.setAttributes(bodyStyle, range: NSMakeRange(nextChar, 2))
        }
        
        storage.setAttributes(bodyStyle, range: change.lineRange)
        storage.replaceCharacters(in: change.lineRange, with: "") // Deletes line.
        
        // Fixes caret position.
        let itemNewline = NSMakeRange(change.lineRange.location - 1, 1)
        storage.setAttribute(.caret, value: true, range: itemNewline)
        return formattedText(caretAtLine: itemNewline.location)
    }
    
    func format(in markdownString: NSAttributedString) -> NSAttributedString {
        var markdownString = markdownString
        for listItem in ListItem.allCases {
            markdownString = format(listItem, in: markdownString)
        }
        return markdownString
    }
    
    /// Formats a Markdown-ish string as an attributed string.
    func format(_ listItem: ListItem,
                in markdownString: NSAttributedString) -> NSAttributedString {
        return markdownString.mapLines {
            (attribLine) in
            let line = attribLine.string
            let lineRange = attribLine.range
            
            if let itemMatch = listItem.firstMatch(in: line, range: lineRange) {
                let mutableLine = NSMutableAttributedString(attributedString: attribLine)
                let itemMarker = self.itemMarker(for: itemMatch.kind)
                mutableLine.replaceCharacters(in: itemMatch.range, with: itemMarker)
                return mutableLine
            } else {
                return attribLine
            }
        }
    }

    /// Deformats an attributed string to a Markdown-ish string.
    func deformat(_ attribString: NSAttributedString) -> NSAttributedString {
        return attribString.mapLines {
            (attribLine) in
            let mutableLine = NSMutableAttributedString(attributedString: attribLine)
            let attribs = attribLine.attribute(.list, in: attribLine.range)
            
            if let attrib = attribs.first {
                let listItem = ListItem(rawValue: attrib.value as! String)!
                mutableLine.removeAttribute(.list, range: attrib.range)
                mutableLine.replaceCharacters(in: attrib.range, with: listItem.markdownPrefix)
            }
            return mutableLine
        }
    }
}

// MARK: - Helpers

extension NSRange {
 
    /// Returns the sum of the location and length of the range.
    var max: Int {
        return self.location + self.length
    }
}
