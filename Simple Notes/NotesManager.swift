//
//  NotesManager.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 12/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import Foundation
import Firebase
import os.log

/// Manages a list of notes model objects.
/// This class centralizes with all communication with Firebase.
final class NotesManager {

    /// Returns the singleton instance.
    static let shared = NotesManager()
    
    /// Notes indexed by correspoding UID.
    private var notesByUID: [UID: Note] = [:]

    /// Returns all available notes in
    /// descending order by modification date.
    var notes: [Note] {
        let notes = Array(notesByUID.values)
        return notes.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    /// Result from save operation.
    enum SaveResult {
        case saved(Note)
        case empty
        case didNotChange
    }
    
    /// Saves the specified note (if changed).
    func saveNote(_ newNote: Note) -> SaveResult {
        // Handles newly created notes.
        guard let noteUID = newNote.uid else {
            if newNote.contents.isEmpty {
                log(.info, "Saving: note is empty")
                return .empty
            } else {
                let newNote = addNoteDocument(newNote)
                log(.info, "Saving: new note created: %@", newNote.uid!)
                storeUpdatedNote(newNote)
                return .saved(newNote)
            }
        }
        
        // Detects actual content changes, if any.
        let oldNote = notesByUID[noteUID]!
        guard newNote.contents != oldNote.contents else {
            log(.info, "Saving: note note didn't change")
            return .didNotChange
        }
        
        // Updates an existing note.
        let newNote = updateNoteDocument(newNote)
        log(.info, "Saving: note saved: %@", newNote.uid!)
        storeUpdatedNote(newNote)
        return .saved(newNote)
    }

    private func storeUpdatedNote(_ note: Note) {
        guard let noteUID = note.uid else {
            preconditionFailure("Note with missing UID!")
        }
        notesByUID[noteUID] = note
        postDidUpdateNoteNotification(for: note)
    }
    
    // MARK: - Notes Notifications

    /// Posted after a given note is updated.
    static let didUpdateNoteNotification = Notification.Name("didUpdateNoteNotification")
    
    private func postDidUpdateNoteNotification(for updatedNote: Note) {
        let notificationName = NotesManager.didUpdateNoteNotification
        log(.info, "Posting: %@: %@", notificationName.rawValue, updatedNote.uid!)
        
        NotificationCenter.default.post(name: notificationName, object: updatedNote)
    }
    
    // MARK: - Firebase Integration
    
    func setUp() {
        FirebaseApp.configure()
        ensureTimestampsInDocuments()
        readAllNoteDocuments()
    }
    
    /// The behavior for system `Date` objects stored in
    /// Firestore is going to change and this ensures we are ready!
    private func ensureTimestampsInDocuments() {
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
    }

    private var notesCollection: CollectionReference {
        return Firestore.firestore().collection("notes")
    }
    
    private func readAllNoteDocuments() {
        precondition(notesByUID.isEmpty)

        notesCollection.getDocuments(source: .default) {
            [weak self] (querySnapshot, error) in
            guard let self = self else { return }

            if let error = error {
                log(.error, "Reading all notes failed: %@", error.localizedDescription)
                return
            }
            let nodeDocuments = querySnapshot!.documents
            log(.info, "Read %d node documents", nodeDocuments.count)
            
            for nodeDocument in nodeDocuments {
                let readNote = Note(nodeDocument.documentID, with: nodeDocument.data())
                self.storeUpdatedNote(readNote)
            }
        }
    }
    
    private func addNoteDocument(_ newNote: Note) -> Note {
        precondition(newNote.uid == nil)
        
        var noteDocument: DocumentReference!
        noteDocument = notesCollection.addDocument(data: newNote.data) {
            (error) in
            if let error = error {
                log(.error, "Firestore: Note creation failed: %@", error.localizedDescription)
                return
            }
            log(.info, "Firestore: New note created: %@", noteDocument!.documentID)
        }
        
        var newNote = newNote
        newNote.uid = noteDocument!.documentID
        return newNote
    }
    
    private func updateNoteDocument(_ note: Note) -> Note {
        guard let noteUID = note.uid else {
            preconditionFailure("Note with missing UID!")
        }

        let noteDocument = notesCollection.document(noteUID)
        noteDocument.setData(note.data) {
            (error) in
            if let error = error {
                log(.error, "Firestore: Note update failed: %@", error.localizedDescription)
                return
            }
            log(.info, "Firestore: Note updated: %@", noteUID)
        }
        return note
    }
}

// MARK: -

extension Notification {

    /// Returns the correspondng note, if any.
    var note: Note? {
        return self.object as? Note
    }
}

// MARK: -

/// The note model layer object.
/// For simplicity, this is designed as a plain value type.
/// The actual note contents is stored in *plain text*,
/// following a simple Markdown-ish format.
struct Note {
  
    /// Creates an empty note.
    init() {
        self.init(contents: "", modifiedDate: Date(), uid: nil)
    }

    /// Creates a fully defined note.
    fileprivate init(contents: String, modifiedDate: Date, uid: UID? = nil) {
        self.contents = contents
        self.creationDate = Date()
        self.modifiedDate = modifiedDate
        self.uid = uid
    }
    
    /// Note contents in a Markdow-ish plain test format.
    /// Please see the `NoteTextStorage` class for further details
    var contents: String {
        didSet {
            modifiedDate = Date()
        }
    }

    /// This note creation date.
    let creationDate: Date

    /// This note last modified date.
    private(set) var modifiedDate: Date
    
    // Note title (i.e., the first line).
    var title: String {
        return contents.lines.first ?? ""
    }
    
    /// Note unique identifier. This will be `nil` for newly created notes.
    ///
    /// This identifier is automatically created by the Firestore database.
    fileprivate(set) var uid: UID?
    
    // MARK: - Firebase Integration
    
    fileprivate init(_ uid: UID, with data: [String : Any]) {
        self.uid = uid
        self.contents = data["contents"] as! String
        self.creationDate = (data["created_at"] as! Timestamp).dateValue()
        self.modifiedDate = (data["modified_at"] as! Timestamp).dateValue()
    }
    
    fileprivate var data: [String : Any] {
        return [
            "contents": contents,
            "created_at": Timestamp(date: creationDate),
            "modified_at": Timestamp(date: modifiedDate)
        ]
    }
}
    
// MARK: - Helpers

/// Just syntax sugar ;)
typealias UID = String

// MARK: - Testing Support

fileprivate let daySeconds: TimeInterval = 60*60*24

fileprivate var testNotes = [
    Note(
        contents:
        """
        The first note.

        The *link* is www.google.com
        **The** Phone **number** is (407) 939-3476

        * 1st item
        * 2nd item
        * 3rd item
        """,
        modifiedDate: Date(timeIntervalSinceNow: -daySeconds/24),
        uid: "1st"
    ),
    Note(
        contents:
        """
        The second note.

        We can use **bold** or *italic*.
        Another link example: https://en.wikipedia.org/wiki/Alan_Turing

        * 1st item
        * 2nd item
        * 3rd item
        """,
        modifiedDate: Date(timeIntervalSinceNow: -daySeconds),
        uid: "2nd"
    ),
    Note(
        contents:
        """
        The third note.

        We can use **bold** or *italic*.
        Another link example: www.swift.org

        * 1st item
        * 2nd item
        * 3rd item
        """,
        modifiedDate: Date(timeIntervalSinceNow: -3*daySeconds),
        uid: "3rd"
    )
]

fileprivate extension NotesManager {
    
    func addTestNotes() {
        for note in testNotes {
            notesByUID[note.uid!] = note
        }
    }
}

extension Note: CustomDebugStringConvertible {
    
    var debugDescription: String {
        let uid = self.uid ?? "<new>"
        return "[Note: \(uid)]\n{{{\n\(self.contents)\n}}}"
    }
}

func testAddingANewNote() {
    var newNote = Note()
    newNote.contents = "A new note!"
    
    switch NotesManager.shared.saveNote(newNote) {
    case .saved(let savedNote):
        newNote = savedNote
    case .empty, .didNotChange:
        fatalError()
    }
    assert(newNote.uid != nil)
    
    print("New note: \(newNote.uid!)")
}
