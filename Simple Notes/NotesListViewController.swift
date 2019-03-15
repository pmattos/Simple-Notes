//
//  NotesListViewController.swift
//  Simple Notes
//
//  Created by Paulo Mattos on 12/03/19.
//  Copyright © 2019 Paulo Mattos. All rights reserved.
//

import UIKit

/// The parent view controller for the notes list UI.
final class NotesViewController: UIViewController {

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNewNoteButton()
        setUpNotesList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        
        /*
        // Testing only.
        run(afterTimeInterval: 1.45) {
            if let firstNote = NotesManager.shared.notes.first {
                self.notesListViewController.pushNoteEditorViewController(with: firstNote)
            }
        }
        */
    }
    
    private func setUpNavigationBar() {
        navigationController!.navigationBar.setTransparentBackground(false)
    }

    // MARK: - Nested Notes List View Controller
    
    @IBOutlet weak private var notesListContainer: UIView!
    private var notesListViewController: NotesListViewController!
    
    private func setUpNotesList() {
        precondition(isViewLoaded)
        notesListViewController = NotesListViewController.instantiate()
        addContentController(notesListViewController, in: notesListContainer)
    }
    
    // MARK: - New Note Button
    
    private var newNoteButton: UIBarButtonItem!
    
    private func setUpNewNoteButton() {
        precondition(isViewLoaded)
        newNoteButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(newNoteButtonTapped)
        )
        navigationItem.setRightBarButton(newNoteButton, animated: false)
    }
    
    @IBAction private func newNoteButtonTapped(_ sender: UIBarButtonItem) {
        let newNote = Note()
        notesListViewController.pushNoteEditorViewController(with: newNote)
    }
}

// MARK: -

/// Displays all created noted in a table view.
final class NotesListViewController: UITableViewController, StoryboardInstantiatable {

    // MARK: - View Controller Lifecycle
    
    /// When instantiating a view controller from a storyboard, iOS
    /// initializes the new view controller by calling this initializer.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        /* empty */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        observeNotesManagerNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Notes Model
    
    var notes: [Note] {
        return NotesManager.shared.notes
    }
    
    private var notesManagerObserver: NSObjectProtocol?
    
    private func observeNotesManagerNotifications() {
        guard notesManagerObserver == nil else { return }
        
        notesManagerObserver = NotificationCenter.default.addObserver(
            forName: NotesManager.didUpdateNoteNotification,
            object: nil,
            queue: .main) {
                [weak self] (_) in
                guard let self = self else { return }
                self.tableView.reloadData() // Refresh all notes!
        }
    }
    
    // MARK: - Set Up

    private func setUpTableView() {
        precondition(isViewLoaded)
        
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView(frame: .zero) // Don't show empty rows.
    }

    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = notes[indexPath.row]
        
        let cell = dequeueReusableCell(NoteCell.self, for: indexPath)
        cell.noteTitle = note.title
        cell.modifiedDate = note.modifiedDate

        return cell
    }
    
    private func dequeueReusableCell<T: UITableViewCell>(_ cellClass: T.Type,
                                                         for indexPath: IndexPath) -> T {
        let cellId = cellClass.className
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        return cell as! T
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = notes[indexPath.row]
        pushNoteEditorViewController(with: note)
    }

    func pushNoteEditorViewController(with note: Note) {
        let noteEditorViewController = NoteEditorViewController.instantiate()
        noteEditorViewController.loadNote(note)
        navigationController!.pushViewController(noteEditorViewController, animated: true)
    }
}

// MARK: - Table View Cells

/// Cell showing note title.
final class NoteCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var modifiedDateLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        noteTitle = nil
    }
    
    fileprivate var noteTitle: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    fileprivate var modifiedDate: Date? {
        didSet {
            modifiedDateLabel.text = modifiedDate?.relativeDescription
        }
    }
}

// MARK: - Helpers

extension Date {

    /// A compact date format (e.g.,  “12/03/19” or “5:30 PM”), using
    /// phrases such as “today” and “tomorrow” for relative dates as well.
    var relativeDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true

        return dateFormatter.string(from: self)
    }
}
