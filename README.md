# Simple Notes

A simple Swift/iOS notes app with rich formatting based on TextKit APIs.

Rich formatting summary:

* Smart links for URLs and phone numbers
* Bold and italic using `**bold**` and `*italic*`
* Support for *bullet*, *dashed*, and *ordered* lists (e.g., `* `, `- `, `1. `)
* Checkmark lists as well

## Main Classes ##

UI layer:

* `NotesListViewController`. Displays all created noted in a table view.
* `NoteEditorViewController`. View controller to shows and edits a given note.
* `NoteTextStorage`. Stores a given note text with rich formatting. This implements the core text formatting engine.

Model layer:

* `Note`. The note model layer object. For simplicity, this is designed as a plain value type.
* `NotesManager`. Manages a list of notes model objects. This class centralizes with all communication with Firebase.

