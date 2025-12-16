import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/editor_toolbar.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/editor/floating_toolbar.dart';
import 'package:universal_notes_flutter/editor/history_manager.dart';
import 'package:universal_notes_flutter/editor/snippet_converter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/snippets_screen.dart';
import 'package:universal_notes_flutter/widgets/find_replace_bar.dart';
import 'package:uuid/uuid.dart';

/// A screen for editing a note.
class NoteEditorScreen extends StatefulWidget {
  /// Creates a new instance of [NoteEditorScreen].
  const NoteEditorScreen({
    required this.onSave,
    this.note,
    super.key,
  });

  /// The note to edit, or null if creating a new note.
  final Note? note;

  /// Callback to save the note.
  final Future<Note> Function(Note) onSave;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  Note? _note;
  late DocumentModel _document;
  TextSelection _selection = const TextSelection.collapsed(offset: 0);
  late final HistoryManager _historyManager;
  Timer? _recordHistoryTimer;
  Timer? _debounceTimer;
  Timer? _throttleTimer;
  Rect? _selectionRect;
  bool get _isToolbarVisible =>
      _selectionRect != null && !_selection.isCollapsed;
  bool _isFocusMode = false;
  int _wordCount = 0;
  int _charCount = 0;
  bool _isFindBarVisible = false;
  String _findTerm = '';
  List<int> _findMatches = [];
  int _currentMatchIndex = -1;

  static const List<Color> _predefinedColors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];
  static const Map<String, double> _fontSizes = {
    'Normal': 16.0,
    'Título Médio': 24.0,
    'Título Grande': 32.0,
  };

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    WidgetsBinding.instance.addObserver(this);
    _document = DocumentAdapter.fromJson(_note?.content ?? '');
    _historyManager = HistoryManager(
      initialState: HistoryState(document: _document, selection: _selection),
    );
    _updateCounts(_document);
    unawaited(SnippetConverter.precacheSnippets());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_autosave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordHistoryTimer?.cancel();
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    // Ensure system UI is restored when the screen is disposed
    if (_isFocusMode) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        ),
      );
    }
    super.dispose();
  }

  void _updateCounts(DocumentModel document) {
    final text = document.toPlainText().trim();
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  void _onDocumentChanged(DocumentModel newDocument) {
    setState(() {
      _document = newDocument;
    });
    _updateCounts(newDocument);
    if (_isFindBarVisible) {
      _onFindChanged(_findTerm);
    }
    _recordHistoryTimer?.cancel();
    _recordHistoryTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _historyManager.record(
          HistoryState(document: newDocument, selection: _selection),
        );
      });
    });

    // --- Autosave Logic ---
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_autosave());
    });

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(const Duration(seconds: 10), () {
        unawaited(_autosave());
      });
    }
  }

  void _onSelectionChanged(TextSelection newSelection) {
    setState(() {
      _selection = newSelection;
    });
  }

  void _onSelectionRectChanged(Rect? rect) {
    // Prevent updating the position of the toolbar during scrolling.
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final editorRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    if (rect != null && editorRect.overlaps(rect)) {
      setState(() {
        _selectionRect = rect;
      });
    } else {
      setState(() {
        _selectionRect = null;
      });
    }
  }

  void _replaceAll(String replaceTerm) {
    if (_findTerm.isEmpty || _findMatches.isEmpty) return;

    var tempDoc = _document;
    // Iterate backwards to keep indices valid.
    for (var i = _findMatches.length - 1; i >= 0; i--) {
      final matchIndex = _findMatches[i];
      tempDoc = DocumentManipulator.deleteText(
        tempDoc,
        matchIndex,
        _findTerm.length,
      );
      tempDoc = DocumentManipulator.insertText(
        tempDoc,
        matchIndex,
        replaceTerm,
      );
    }
    _onDocumentChanged(tempDoc);
  }

  // ... (all other methods remain the same)
  void _toggleStyle(StyleAttribute attribute) {
    final newDocument = DocumentManipulator.toggleStyle(
      _document,
      _selection,
      attribute,
    );
    _onDocumentChanged(newDocument);
  }

  void _applyColor(Color color) {
    final newDocument = DocumentManipulator.applyColor(
      _document,
      _selection,
      color,
    );
    _onDocumentChanged(newDocument);
  }

  void _applyFontSize(double fontSize) {
    final newDocument = DocumentManipulator.applyFontSize(
      _document,
      _selection,
      fontSize,
    );
    _onDocumentChanged(newDocument);
  }

  void _showColorPicker() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select a color'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedColors
                .map(
                  (color) => GestureDetector(
                    onTap: () {
                      _applyColor(color);
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(backgroundColor: color, radius: 20),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showFontSizePicker() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => ListView(
          shrinkWrap: true,
          children: _fontSizes.entries
              .map(
                (entry) => ListTile(
                  title: Text(
                    entry.key,
                    style: TextStyle(fontSize: entry.value),
                  ),
                  onTap: () {
                    _applyFontSize(entry.value);
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _undo() {
    setState(() {
      final state = _historyManager.undo();
      _document = state.document;
      _selection = state.selection;
      _updateCounts(_document);
    });
  }

  void _redo() {
    setState(() {
      final state = _historyManager.redo();
      _document = state.document;
      _selection = state.selection;
      _updateCounts(_document);
    });
  }

  Future<void> _autosave() async {
    if (!mounted) return;
    _debounceTimer?.cancel();

    final plainText = _document.toPlainText();
    if (plainText.trim().isEmpty) return;

    final jsonContent = DocumentAdapter.toJson(_document);

    final noteToSave =
        (_note ??
                Note(
                  id: const Uuid().v4(),
                  title: '',
                  content: '',
                  date: DateTime.now(),
                ))
            .copyWith(
              title: plainText.split('\n').first,
              content: jsonContent,
              date: DateTime.now(),
            );

    // If it's a new note, store it in the state so we update it next time.
    if (_note == null) {
      setState(() {
        _note = noteToSave;
      });
    }

    await NoteRepository.instance.updateNoteContent(noteToSave);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nota salva automaticamente.'),
        duration: Duration(seconds: 2),
      ),
    );

    await _createVersionIfNeeded(jsonContent);
  }

  Future<void> _saveNote() async {
    // Cancel any pending autosave before manual save
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();

    await _autosave(); // Perform a final save
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _createVersionIfNeeded(String jsonContent) async {
    if (widget.note == null) return;

    final versions = await NoteRepository.instance.getNoteVersions(
      widget.note!.id,
    );
    final now = DateTime.now();

    if (versions.isEmpty || now.difference(versions.first.date).inHours >= 6) {
      final newVersion = NoteVersion(
        id: const Uuid().v4(),
        noteId: widget.note!.id,
        content: jsonContent,
        date: now,
      );
      await NoteRepository.instance.createNoteVersion(newVersion);
    }
  }

  Future<void> _showHistory() async {
    if (widget.note == null) return;
    final versions = await NoteRepository.instance.getNoteVersions(
      widget.note!.id,
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              return ListTile(
                title: Text(DateFormat.yMMMd().add_Hms().format(version.date)),
                subtitle: Text(
                  DocumentAdapter.fromJson(version.content).toPlainText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _restoreVersion(version);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _restoreVersion(NoteVersion version) {
    final newDocument = DocumentAdapter.fromJson(version.content);
    _onDocumentChanged(newDocument);
  }

  void _onFindChanged(String term) {
    setState(() {
      _findTerm = term;
      _findMatches = [];
      _currentMatchIndex = -1;
      if (term.isNotEmpty) {
        final plainText = _document.toPlainText().toLowerCase();
        var startIndex = 0;
        while (startIndex < plainText.length) {
          final index = plainText.indexOf(term.toLowerCase(), startIndex);
          if (index == -1) break;
          _findMatches.add(index);
          startIndex = index + 1;
        }
      }
      if (_findMatches.isNotEmpty) {
        _currentMatchIndex = 0;
        _jumpToMatch(0);
      }
    });
  }

  void _jumpToMatch(int index) {
    if (index < 0 || index >= _findMatches.length) return;
    final start = _findMatches[index];
    setState(() {
      _selection = TextSelection(
        baseOffset: start,
        extentOffset: start + _findTerm.length,
      );
    });
  }

  void _findNext() {
    if (_findMatches.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex + 1) % _findMatches.length;
    _jumpToMatch(_currentMatchIndex);
  }

  void _findPrevious() {
    if (_findMatches.isEmpty) return;
    _currentMatchIndex =
        (_currentMatchIndex - 1 + _findMatches.length) % _findMatches.length;
    _jumpToMatch(_currentMatchIndex);
  }

  void _replace(String replaceTerm) {
    if (_currentMatchIndex == -1 || _selection.isCollapsed) return;
    final docAfterDelete = DocumentManipulator.deleteText(
      _document,
      _selection.start,
      _selection.end - _selection.start,
    );
    final newDoc = DocumentManipulator.insertText(
      docAfterDelete,
      _selection.start,
      replaceTerm,
    );
    _onDocumentChanged(newDoc);
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      if (_isFocusMode) {
        unawaited(
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        );
      } else {
        unawaited(
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          ),
        );
      }
    });
  }

  Future<void> _showSnippetsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const SnippetsScreen()),
    );
    // Reload snippets in case they were changed.
    await SnippetConverter.precacheSnippets();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveNote();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: _isFocusMode
            ? null
            : AppBar(
                title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Find & Replace',
                    onPressed: () =>
                        setState(() => _isFindBarVisible = !_isFindBarVisible),
                  ),
                  if (widget.note != null)
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'Version History',
                      onPressed: _showHistory,
                    ),
                  IconButton(
                    icon: Icon(
                      _isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                    tooltip: 'Focus Mode',
                    onPressed: _toggleFocusMode,
                  ),
                ],
              ),
        floatingActionButton: _isFocusMode
            ? null
            : FloatingActionButton(
                onPressed: _saveNote,
                tooltip: 'Save Note',
                child: const Icon(Icons.save),
              ),
        body: SafeArea(
          top: !_isFocusMode,
          bottom: !_isFocusMode,
          child: Stack(
            children: [
              Column(
                children: [
                  if (_isFindBarVisible && !_isFocusMode)
                    FindReplaceBar(
                      onFindChanged: _onFindChanged,
                      onFindNext: _findNext,
                      onFindPrevious: _findPrevious,
                      onReplace: _replace,
                      onReplaceAll: _replaceAll,
                      onClose: () => setState(() => _isFindBarVisible = false),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: EditorWidget(
                        document: _document,
                        onDocumentChanged: _onDocumentChanged,
                        selection: _selection,
                        onSelectionChanged: _onSelectionChanged,
                        onSelectionRectChanged: _onSelectionRectChanged,
                      ),
                    ),
                  ),
                  if (!_isFocusMode)
                    EditorToolbar(
                      onBold: () => _toggleStyle(StyleAttribute.bold),
                      onItalic: () => _toggleStyle(StyleAttribute.italic),
                      onUnderline: () => _toggleStyle(StyleAttribute.underline),
                      onStrikethrough: () =>
                          _toggleStyle(StyleAttribute.strikethrough),
                      onColor: _showColorPicker,
                      onFontSize: _showFontSizePicker,
                      onSnippets: () => unawaited(_showSnippetsScreen()),
                      onUndo: _undo,
                      onRedo: _redo,
                      canUndo: _historyManager.canUndo,
                      canRedo: _historyManager.canRedo,
                      wordCount: _wordCount,
                      charCount: _charCount,
                    ),
                ],
              ),
              if (_isToolbarVisible)
                Positioned(
                  top: _selectionRect!.top - 55,
                  left: _selectionRect!.left,
                  child: FloatingToolbar(
                    onBold: () => _toggleStyle(StyleAttribute.bold),
                    onItalic: () => _toggleStyle(StyleAttribute.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
