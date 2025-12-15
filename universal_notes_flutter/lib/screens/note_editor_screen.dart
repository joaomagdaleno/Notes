import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/editor_toolbar.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/editor/history_manager.dart';
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
  late final HistoryManager _historyManager;
  Timer? _recordHistoryTimer;

  static const List<Color> _predefinedColors = [
    Colors.black, Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple
  ];
  static const Map<String, double> _fontSizes = {
    'Normal': 16.0, 'Título Médio': 24.0, 'Título Grande': 32.0,
  };

  @override
  void initState() {
    super.initState();
    _document = DocumentAdapter.fromJson(widget.note?.content ?? '');
    _historyManager = HistoryManager(
      initialState: HistoryState(document: _document, selection: _selection),
    );
  }

  @override
  void dispose() {
    _recordHistoryTimer?.cancel();
    super.dispose();
  }

  void _onDocumentChanged(DocumentModel newDocument) {
    setState(() {
      _document = newDocument;
    });
    _recordHistoryTimer?.cancel();
    _recordHistoryTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
         _historyManager.record(HistoryState(document: newDocument, selection: _selection));
      });
    });
  }

  void _onSelectionChanged(TextSelection newSelection) {
    setState(() {
      _selection = newSelection;
    });
  }

  void _toggleStyle(StyleAttribute attribute) {
    final newDocument = DocumentManipulator.toggleStyle(_document, _selection, attribute);
    _onDocumentChanged(newDocument);
  }

  void _applyColor(Color color) {
    final newDocument = DocumentManipulator.applyColor(_document, _selection, color);
    _onDocumentChanged(newDocument);
  }

  void _applyFontSize(double fontSize) {
    final newDocument = DocumentManipulator.applyFontSize(_document, _selection, fontSize);
    _onDocumentChanged(newDocument);
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedColors.map((color) => GestureDetector(
            onTap: () {
              _applyColor(color);
              Navigator.of(context).pop();
            },
            child: CircleAvatar(backgroundColor: color, radius: 20),
          )).toList(),
        ),
      ),
    );
  }

  void _showFontSizePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _fontSizes.entries.map((entry) => ListTile(
          title: Text(entry.key, style: TextStyle(fontSize: entry.value)),
          onTap: () {
            _applyFontSize(entry.value);
            Navigator.of(context).pop();
          },
        )).toList(),
      ),
    );
  }

  void _undo() {
    setState(() {
      final state = _historyManager.undo();
      _document = state.document;
      _selection = state.selection;
    });
  }

  void _redo() {
    setState(() {
      final state = _historyManager.redo();
      _document = state.document;
      _selection = state.selection;
    });
  }

  Future<void> _saveNote() async {
    final plainText = _document.toPlainText();
    if (plainText.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final jsonContent = DocumentAdapter.toJson(_document);
    final noteToSave = (widget.note ?? Note(id: '', title: '', content: '', date: DateTime.now()))
        .copyWith(
          title: plainText.split('\n').first,
          content: jsonContent,
        );

    await widget.onSave(noteToSave);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveNote,
        child: const Icon(Icons.save),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
            onStrikethrough: () => _toggleStyle(StyleAttribute.strikethrough),
            onColor: _showColorPicker,
            onFontSize: _showFontSizePicker,
            onUndo: _undo,
            onRedo: _redo,
            canUndo: _historyManager.canUndo,
            canRedo: _historyManager.canRedo,
          ),
        ],
      ),
    );
  }
}
