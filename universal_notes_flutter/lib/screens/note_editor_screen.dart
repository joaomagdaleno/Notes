import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/editor_toolbar.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A screen for editing a note using a custom rich text editor.
class NoteEditorScreen extends StatefulWidget {
  /// Creates a new instance of [NoteEditorScreen].
  const NoteEditorScreen({
    required this.onSave,
    this.note,
    super.key,
  });

  /// The note to edit. If null, a new note is created.
  final Note? note;
  /// The function to call when the note is saved.
  final Future<Note> Function(Note) onSave;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late DocumentModel _document;
  TextSelection _selection = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
    _document = const DocumentModel(
      spans: [
        TextSpanModel(text: 'Hello, '),
        TextSpanModel(text: 'World!', isBold: true),
        TextSpanModel(text: '\nThis is an '),
        TextSpanModel(text: 'editable', isItalic: true),
        TextSpanModel(text: ' text field.'),
      ],
    );
  }

  void _onDocumentChanged(DocumentModel newDocument) {
    setState(() {
      _document = newDocument;
    });
  }

  void _onSelectionChanged(TextSelection newSelection) {
    setState(() {
      _selection = newSelection;
    });
  }

  void _toggleStyle(StyleAttribute attribute) {
    setState(() {
      _document = DocumentManipulator.toggleStyle(
        _document,
        _selection,
        attribute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: EditorWidget(
                document: _document,
                onDocumentChanged: _onDocumentChanged,
                selection: _selection,
                onSelectionChanged: _onSelectionChanged,
              ),
            ),
          ),
          EditorToolbar(
            onBold: () => _toggleStyle(StyleAttribute.bold),
            onItalic: () => _toggleStyle(StyleAttribute.italic),
            onUnderline: () => _toggleStyle(StyleAttribute.underline),
          ),
        ],
      ),
    );
  }
}
