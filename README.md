# Simple Notes #

A simple Swift/iOS notes app with rich formatting based on TextKit APIs.

Rich formatting summary:

* Smart links for URLs and phone numbers
* Text formatting using `**bold**` and `*italic*` simple markup
* Support for *bullet*, *dashed*, and *ordered* lists (e.g., `* `, `- `, `1. `)
* Checkmark ✔ lists as well

## Main Classes ##

UI layer:

* [`NotesListViewController`][NotesListViewController.swift]. Displays all created notes in a table view.
* [`NoteEditorViewController`][NoteEditorViewController.swift]. View controller to show *and* edit a given note.
* [`NoteTextStorage`][NoteTextStorage.swift]. Stores a given note text with rich formatting. This implements the core text formatting engine.
* [`CheckmarkView`][CheckmarkView.swift]. Draws a Core Graphics based checkmark vector icon with a circular background. It also provides a simple animation for the checkmark.

Model layer:

* [`Note`][Note.swift]. The note model layer object. For simplicity, this is designed as a plain value type. The actual note contents is stored in *plain text*, following a simple Markdown-ish format (more on that below).
* [`NotesManager`][NotesManager.swift]. Manages a list of notes model objects. This class centralizes all communication with Firebase.

## Markdown-ish Encoding ##

The following richly formatted note (using [TextKit][TextKit]):

<img src="Screenshots/note-editor.png" width="315">

is then encoded as a Markdown-based, plain text *string* (for database storage):

```
Links & Lists

Some links:

* www.google.com
* www.swift.org
* (407) 939-7000

Text in **bold** too!

To do list:

[x] Add a nice icon (?)
[x] Upload to Github
[_] Notify Nikita
```

[NotesListViewController.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/NotesListViewController.swift#L73

[NoteEditorViewController.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/NoteEditorViewController.swift#L11

[NoteTextStorage.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/NoteTextStorage.swift#L11

[Note.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/NotesManager.swift#L176

[NotesManager.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/NotesManager.swift#L13

[CheckmarkView.swift]: https://github.com/pmattos/Simple-Notes/blob/master/Simple%20Notes/CheckmarkView.swift#L11 

[TextKit]: https://developer.apple.com/documentation/appkit/textkit
