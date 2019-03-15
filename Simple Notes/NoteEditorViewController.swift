//
//  NoteEditorViewController.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 09/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import UIKit

/// Shows and edits a given note.
final class NoteEditorViewController: UIViewController,
NoteTextViewDelegate, StoryboardInstantiatable {

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDoneButton()
        setUpNoteView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        registerForKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveNoteIfNeeded()
        deregisterFromKeyboardNotifications()
    }

    private func setUpNavigationBar() {
        navigationController!.navigationBar.setTransparentBackground(true)
    }

    // MARK: - Note Model

    private(set) var note: Note!

    func loadNote(_ note: Note) {
        self.note = note
        loadViewIfNeeded()
        noteTextView.loadNote(note)
        endEditing(updateNote: false)
    }
    
    // MARK: - Note Text View
    
    @IBOutlet private weak var noteViewContainer: UIView!
    private var noteTextView: NoteTextView!
    private var noteTextStorage: NoteTextStorage!
    
    private func setUpNoteView() {
        precondition(isViewLoaded)
        precondition(noteTextView == nil && noteTextStorage == nil)
        
        // Note storage layer.
        noteTextStorage = NoteTextStorage()
        
        // We use a single NSTextContainer (for the UITextView).
        let textContainerSize = CGSize(
            width: view.bounds.width,
            height: .greatestFiniteMagnitude
        )
        let textContainer = NSTextContainer(size: textContainerSize)
        textContainer.widthTracksTextView = true
        
        // Defines a standard NSLayoutManager.
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        noteTextStorage.addLayoutManager(layoutManager)
        
        // Finally, add the UITextView to this view controller.
        noteTextView = NoteTextView(frame: view.bounds, textContainer: textContainer)
        noteTextView.noteTextViewDelegate = self
        layoutNoteTextView()
    }
    
    private func layoutNoteTextView() {
        noteViewContainer.addSubview(noteTextView)
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noteTextView.leadingAnchor.constraint(equalTo: noteViewContainer.leadingAnchor),
            noteTextView.trailingAnchor.constraint(equalTo: noteViewContainer.trailingAnchor),
            noteTextView.topAnchor.constraint(equalTo: noteViewContainer.topAnchor),
            noteTextView.bottomAnchor.constraint(equalTo: noteViewContainer.bottomAnchor)
        ])
    }

    // MARK: - Note Editing Buttons
    
    private var okButton: UIBarButtonItem!
    private var checkmarkButton: UIBarButtonItem!

    private func setUpDoneButton() {
        precondition(isViewLoaded)
        
        okButton = UIBarButtonItem(
            title: "OK",
            style: .done,
            target: self,
            action: #selector(okButtonTapped)
        )
        checkmarkButton = UIBarButtonItem(
            title: "Checklist",
            style: .plain,
            target: self,
            action: #selector(checkmarkButtonTapped)
        )
        hideNoteEditingButtons(true, animated: true)
    }
    
    @IBAction private func okButtonTapped(_ sender: UIBarButtonItem) {
        noteTextView.resignFirstResponder()
    }

    @IBAction private func checkmarkButtonTapped(_ sender: UIBarButtonItem) {
        noteTextView.insertCheckmarkAtCaretPosition()
    }

    private func hideNoteEditingButtons(_ hide: Bool, animated: Bool) {
        precondition(okButton != nil && checkmarkButton != nil)
        
        let buttons: [UIBarButtonItem] = hide ? [] : [okButton, checkmarkButton]
        navigationItem.setRightBarButtonItems(buttons, animated: animated)
    }

    // MARK: - Editing Flow

    private func saveNoteIfNeeded() {
        note.contents = noteTextStorage.deformatted()
        switch NotesManager.shared.saveNote(note) {
        case .saved(let savedNote):
            note = savedNote
            print(note!.debugDescription)
        case .empty, .didNotChange:
            break
        }
    }

    func noteTextViewDidBeginEditing(_ noteTextView: NoteTextView) {
        hideNoteEditingButtons(false, animated: true)
    }
    
    func noteTextViewDidEndEditing(_ noteTextView: NoteTextView) {
        endEditing(updateNote: true)
    }

    private func endEditing(updateNote: Bool) {
        noteTextView.endEditing()
        hideNoteEditingButtons(true, animated: true)
        if updateNote {
            saveNoteIfNeeded()
        }
    }
    
    // MARK: - Keyboard Management
    
    private func registerForKeyboardNotifications(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWasShown(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillBeHidden(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func deregisterFromKeyboardNotifications(){
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private var oldContentInsets: UIEdgeInsets?
    private var oldScrollIndicatorInsets: UIEdgeInsets?

    /// Need to calculate keyboard exact size due to Apple suggestions
    @objc private func keyboardWasShown(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(
            top: 0.0, left: 0.0,
            bottom: keyboardSize!.height, right: 0.0
        )

        oldContentInsets = noteTextView.contentInset
        oldScrollIndicatorInsets = noteTextView.scrollIndicatorInsets

        noteTextView.contentInset = contentInsets
        noteTextView.scrollIndicatorInsets = contentInsets
        
        var visibleRect : CGRect = self.view.frame
        visibleRect.size.height -= keyboardSize!.height
        
        let caret = noteTextView.caretRect(for: noteTextView.selectedTextRange!.start)
        if !visibleRect.contains(caret.origin) {
            noteTextView.scrollRectToVisible(caret, animated: true)
        }
    }
    
    /// Once keyboard disappears, restore original positions
    @objc func keyboardWillBeHidden(notification: NSNotification){
        if let oldContentInsets = oldContentInsets,
            let oldScrollIndicatorInsets = oldScrollIndicatorInsets {
            noteTextView.contentInset = oldContentInsets
            noteTextView.scrollIndicatorInsets = oldScrollIndicatorInsets
        }
    }
}

// MARK: -

protocol NoteTextViewDelegate: class {
    
    func noteTextViewDidBeginEditing(_ noteTextView: NoteTextView);
    func noteTextViewDidEndEditing(_ noteTextView: NoteTextView);
}

// MARK: -

/// Custom `UITextView` subclass for showing & editing a given `Note` object.
final class NoteTextView: UITextView, UITextViewDelegate, UITextPasteDelegate {
 
    private var noteTextStorage: NoteTextStorage {
        return textStorage as! NoteTextStorage
    }
    
    // MARK: - View Initializers
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setUpNoteTextView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpNoteTextView()
    }
    
    private func setUpNoteTextView() {
        self.delegate = self
        self.pasteDelegate = self
        self.spellCheckingType = .no
        self.autocorrectionType = .no
        self.autocapitalizationType = .sentences
        self.dataDetectorTypes = [.link, .phoneNumber]
        self.font = noteTextStorage.bodyFont
        self.isSelectable = true

        resetTypingAttributes()
    }

    private func resetTypingAttributes() {
        typingAttributes = noteTextStorage.bodyStyle
    }
    
    fileprivate func loadNote(_ note: Note) {
        noteTextStorage.load(note: note.contents)
        layoutCheckmarkViews()
        print(note.debugDescription)
    }

    // MARK: - Delegate
    
    weak var noteTextViewDelegate: NoteTextViewDelegate?

    // MARK: - User Interaction
    
    private var initialTouchY: CGFloat = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        initialTouchY = touches.first!.location(in: self).y
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let swipeDistance = abs(touch.location(in: self).y - initialTouchY)
        if  swipeDistance <= 10 {
            if !didTapNoteView(touch) {
                super.touchesEnded(touches, with: event)
            }
        }
    }
    
    @objc private func didTapNoteView(_ touch: UITouch) -> Bool {
        // Location of tap in noteView coordinates and taking the inset into account.
        var location = touch.location(in: self)
        location.x -= self.textContainerInset.left;
        location.y -= self.textContainerInset.top;
        
        // Character index at tap location.
        var unitInsertionPoint: CGFloat = 0
        let charIndex = self.layoutManager.characterIndex(
            for: location,
            in: self.textContainer,
            fractionOfDistanceBetweenInsertionPoints: &unitInsertionPoint
        )
        assert(unitInsertionPoint >= 0.0 && unitInsertionPoint <= 1.0)
        
        if !detectTappableText(at: charIndex, with: unitInsertionPoint) {
            startEditing(at: charIndex, with: unitInsertionPoint)
            return true
        } else {
            return false
        }
    }
    
    private func detectTappableText(at charIndex: Int,
                                    with unitInsertionPoint: CGFloat) -> Bool {
        guard charIndex < self.textStorage.length else {
            return false
        }
        
        let noteText = self.attributedText!
        let tappableAttribs: [NSAttributedString.Key] = [.link, .list]
        for attrib in tappableAttribs {
            var attribRange = NSRange(location: 0, length: 0)
            let attribValue = noteText.attribute(attrib, at: charIndex,
                                                 effectiveRange: &attribRange)
            guard let _ = attribValue else {
                continue
            }
            guard !(charIndex == attribRange.max - 1 && unitInsertionPoint == 1.0) else {
                continue // Tapped after the link end.
            }
            return true
        }
        return false
    }

    // MARK: - Fixes Copy & Paste Bug
    
    /// Fixes weird animation glitch on paste action.
    /// More info: https://stackoverflow.com/a/51771555/819340
    func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        shouldAnimatePasteOf attributedString: NSAttributedString,
        to textRange: UITextRange) -> Bool {
        return false
    }
    
    // MARK: - Editing Flow

    func textViewDidBeginEditing(_ textView: UITextView) {
        oldSelectedRange = selectedRange
        noteTextViewDelegate?.noteTextViewDidBeginEditing(self)
    }
    
    func textViewDidEndEditing(_ noteView: UITextView) {
        noteTextViewDelegate?.noteTextViewDidEndEditing(self)
    }

    private func startEditing(at charIndex: Int, with unitInsertionPoint: CGFloat) {
        var charIndex = charIndex
        if character(at: charIndex) != "\n" {
            charIndex += Int(unitInsertionPoint.rounded())
        }
        selectedRange = NSRange(location: charIndex, length: 0)
        
        isEditable = true
        becomeFirstResponder()
        resetTypingAttributes()
        //scrollToCaretPosition()
    }
    
    private func scrollToCaretPosition() {
        DispatchQueue.main.async {
            assert(self.isFirstResponder)
            let caret = self.caretRect(for: self.selectedTextRange!.start)
            self.scrollRectToVisible(caret, animated: true)
        }
    }
    
    fileprivate func endEditing() {
        endEditing(false)
        isEditable = false
        resignFirstResponder()
    }

    func textViewDidChange(_ noteView: UITextView) {
        let formattedText = noteTextStorage.processRichFormatting()
        if let caretRange = formattedText?.caretRange {
            fixCaretPosition(in: caretRange)
        }
        resetTypingAttributes()
        layoutCheckmarkViews()
    }

    private func fixCaretPosition(in caretRange: NSRange) {
        let caretRange = noteTextStorage.lineRange(for: caretRange.location)
        guard let caret = noteTextStorage.attribute(.caret, in: caretRange).first else {
            return
        }
        DispatchQueue.main.async {
            self.noteTextStorage.removeAttribute(.caret, range: caret.range)
            self.setCaretPosition(to: caret.range.max)
        }
    }
    
    private func setCaretPosition(to caret: Int) {
        self.selectedRange = NSRange(location: caret, length: 0)
        self.resetTypingAttributes()
    }

    private var oldSelectedRange: NSRange?
    
    /// Dirty hack to ignore ZERO WIDTH SPACE characters.
    /// https://www.fileformat.info/info/unicode/char/200b
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard let oldSelectedRange = self.oldSelectedRange else { return }
        
        if let char = character(at: selectedRange.location), char == zeroWidthSpace {
            let dir = (selectedRange.location - oldSelectedRange.location) >= 0 ? 1 : -1
            let newSelectedRange = NSMakeRange(selectedRange.location + dir, 0)
            DispatchQueue.main.async {
                self.selectedRange = newSelectedRange
            }
        }
        self.oldSelectedRange = selectedRange
    }

    // MARK: - Checkmarks Views Overlay
    
    fileprivate func insertCheckmarkAtCaretPosition() {
        noteTextStorage.insertCheckmark(at: selectedRange.location, withValue: false)
        moveCaretToLineEnd(at: selectedRange.location)
        layoutCheckmarkViews()
    }
    
    private func moveCaretToLineEnd(at index: Int) {
        guard index < noteTextStorage.length - 1 else {
            fixCaretPosition(in: NSMakeRange(index, 0))
            return
        }
        let lineRange = noteTextStorage.lineRange(for: index)
        DispatchQueue.main.async {
            self.setCaretPosition(to: lineRange.max - 1)
        }
    }
    
    private func reuseCheckmarkView() -> CheckmarkView {
        let checkmarkView = CheckmarkView()
        checkmarkView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        checkmarkView.addTarget(
            self, action: #selector(didTapCheckmark),
            for: .primaryActionTriggered
        )
        return checkmarkView
    }
    
    @IBAction private func didTapCheckmark(_ checkmarkView: CheckmarkView) {
        precondition(checkmarkView.tag >= 0 && checkmarkView.tag < noteTextStorage.length)
        noteTextStorage.setCheckmark(
            atLine: NSRange(location: checkmarkView.tag, length: 0),
            to: checkmarkView.tickShown
        )
    }
    
    private var checkmarkViews: [CheckmarkView] = []
    
    private func layoutCheckmarkViews() {
        for checkmarkView in checkmarkViews {
            checkmarkView.removeFromSuperview()
        }
        
        noteTextStorage.enumerateAttribute(.list, in: noteTextStorage.range) {
            (attribValue, attribRange, stop) in
            guard let attribValue = attribValue as? String else { return }
            guard let listItem = ListItem(rawValue: attribValue) else { return }
            guard case let ListItem.checkmark(checkmarkValue) = listItem else { return }
            
            let textRange = self.textRange(from: attribRange)!
            let checkmarkRect = firstRect(for: textRange)
            
            let checkmarkView = reuseCheckmarkView()
            checkmarkView.tag = attribRange.location
            checkmarkView.showTick(checkmarkValue!)

            checkmarkView.frame.origin = CGPoint(
                x: 0,
                y: checkmarkRect.midY - checkmarkView.frame.height/2 + 0.5
            )
            addSubview(checkmarkView)
            checkmarkViews.append(checkmarkView)
        }
    }
    
    private func textRange(from range: NSRange) -> UITextRange? {
        guard let start = position(from: beginningOfDocument, offset: range.location) else {
            return nil
        }
        guard let end = position(from: beginningOfDocument, offset: range.max) else {
            return nil
        }
        return textRange(from: start, to: end)
    }

    // MARK: - Helpers
    
    private func character(at charIndex: Int) -> String? {
        return attributedText!.character(at: charIndex)
    }
    
    // MARK: - Debugging Helpers
    
    fileprivate func printChar(at charIndex: Int) {
        let char = character(at: charIndex)!
        let charName: String
        
        switch char {
        case " ":
            charName = "<space>"
        case "\n":
            charName = "<newline>"
        default:
            charName = "\"\(char)\""
        }
        print("Character: \(charName)")
    }
}
