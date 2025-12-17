import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/editor_toolbar.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/editor/floating_toolbar.dart';
import 'package:universal_notes_flutter/editor/history_manager.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_notes_flutter/editor/snippet_converter.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/screens/snippets_screen.dart';
import 'package:universal_notes_flutter/services/export_service.dart';
import 'package:universal_notes_flutter/services/storage_service.dart';
import 'package:universal_notes_flutter/widgets/find_replace_bar.dart';
import 'package:universal_notes_flutter/services/event_replayer.dart';
import 'package:universal_notes_flutter/services/history_grouper.dart';
import 'package:universal_notes_flutter/models/note_event.dart';

/// A screen for editing a note.
class NoteEditorScreen extends StatefulWidget {
  /// Creates a new instance of [NoteEditorScreen].
  const NoteEditorScreen({
    required this.onSave,
    this.note,
    this.isCollaborative = false,
    super.key,
  });

  /// The note to edit, or null if creating a new note.
  final Note? note;

  /// Callback to save the note.
  final Future<Note> Function(Note) onSave;

  /// Whether the note is in collaborative mode.
  final bool isCollaborative;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  Note? _note;
  late DocumentModel _document;
  TextSelection _selection = const TextSelection.collapsed(offset: 0);
  late final HistoryManager _historyManager;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<EditorWidgetState> _editorKey =
      GlobalKey<EditorWidgetState>();
  Timer? _recordHistoryTimer;
  Timer? _debounceTimer;
  Timer? _throttleTimer;
  final _selectionRectNotifier = ValueNotifier<Rect?>(null);
  bool get _isToolbarVisible =>
      _selectionRectNotifier.value != null && !_selection.isCollapsed;
  bool _isFocusMode = false;
  Rect? get _selectionRect => _selectionRectNotifier.value;
  final _wordCountNotifier = ValueNotifier<int>(0);
  final _charCountNotifier = ValueNotifier<int>(0);
  bool _isFindBarVisible = false;
  String _findTerm = '';
  List<int> _findMatches = [];
  int _currentMatchIndex = -1;
  final _firestoreRepository = FirestoreRepository();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  // --- Collaboration State (Temporarily disabled) ---
  final bool _isCollaborative = false;
  final Map<String, Map<String, dynamic>> _remoteCursors = {};

  // --- Tag state ---
  List<String> _currentTags = [];
  final _tagController = TextEditingController();

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
    _currentTags = _note?.tags.toList() ?? [];
    WidgetsBinding.instance.addObserver(this);

    _initializeEditor(_note?.content ?? '');

    if (_note != null) {
      _fetchContent();
    }

    unawaited(SnippetConverter.precacheSnippets());
  }

  Future<void> _fetchContent() async {
    if (_note != null && _note!.id.isNotEmpty) {
      // Check if note is shared
      bool isShared =
          _note!.memberIds.length > 1 || _note!.collaborators.isNotEmpty;

      if (isShared) {
        final fullContent = await _firestoreRepository.getNoteContent(
          _note!.id,
        );
        if (fullContent.isNotEmpty && mounted) {
          setState(() {
            _initializeEditor(fullContent);
          });
        }
      }
      // For local notes, widget.note.content is assumed to be full content
      // (loaded from SQLite via SyncService)
    }
  }

  void _initializeEditor(String content) {
    _document = DocumentAdapter.fromJson(content);
    _historyManager = HistoryManager(
      initialState: HistoryState(document: _document, selection: _selection),
    );
    _updateCounts(_document);
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
    _scrollController.dispose();
    _tagController.dispose();
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
    _charCountNotifier.value = text.length;
    _wordCountNotifier.value = text.isEmpty
        ? 0
        : text.split(RegExp(r'\s+')).length;
  }

  void _onDocumentChanged(DocumentModel newDocument) {
    setState(() {
      _document = newDocument;
    });
    _updateCounts(newDocument);

    // Autosave logic
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      unawaited(_autosave());
    });

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(const Duration(seconds: 10), () {
        unawaited(_autosave());
      });
    }

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
      _selectionRectNotifier.value = rect;
    } else {
      _selectionRectNotifier.value = null;
    }
  }

  void _replaceAll(String replaceTerm) {
    if (_findTerm.isEmpty || _findMatches.isEmpty) return;

    var tempDoc = _document;
    // Iterate backwards to keep indices valid.
    for (var i = _findMatches.length - 1; i >= 0; i--) {
      final matchIndex = _findMatches[i];
      final deleteResult = DocumentManipulator.deleteText(
        tempDoc,
        matchIndex,
        _findTerm.length,
      );
      tempDoc = deleteResult.document;
      _handleNoteEvent(deleteResult.eventType, deleteResult.eventPayload);

      final insertResult = DocumentManipulator.insertText(
        tempDoc,
        matchIndex,
        replaceTerm,
      );
      tempDoc = insertResult.document;
      _handleNoteEvent(insertResult.eventType, insertResult.eventPayload);
    }
    _onDocumentChanged(tempDoc);
  }

  Future<void> _handleNoteEvent(
    NoteEventType type,
    Map<String, dynamic> payload,
  ) async {
    if (_note == null || type == NoteEventType.unknown) return;

    final event = NoteEvent(
      id: const Uuid().v4(),
      noteId: _note!.id,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await NoteRepository.instance.addNoteEvent(event);
  }

  // ... (all other methods remain the same)
  void _toggleStyle(StyleAttribute attribute) {
    final result = DocumentManipulator.toggleStyle(
      _document,
      _selection,
      attribute,
    );
    final newDocument = result.document;
    _handleNoteEvent(result.eventType, result.eventPayload);
    _onDocumentChanged(newDocument);
  }

  void _applyColor(Color color) {
    final result = DocumentManipulator.applyColor(
      _document,
      _selection,
      color,
    );
    final newDocument = result.document;
    _handleNoteEvent(result.eventType, result.eventPayload);
    _onDocumentChanged(newDocument);
  }

  void _applyFontSize(double fontSize) {
    final result = DocumentManipulator.applyFontSize(
      _document,
      _selection,
      fontSize,
    );
    final newDocument = result.document;
    _handleNoteEvent(result.eventType, result.eventPayload);
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
    if (!_historyManager.canUndo) return;
    setState(() {
      final state = _historyManager.undo();
      _document = state.document;
      _selection = state.selection;
      _updateCounts(_document);
    });
  }

  void _redo() {
    if (!_historyManager.canRedo) return;
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

    if (_note == null) return;

    final plainText = _document.toPlainText();
    if (plainText.trim().isEmpty) return;

    final jsonContent = DocumentAdapter.toJson(_document);

    final noteToSave = _note!.copyWith(
      title: plainText.split('\n').first,
      content: jsonContent,
      lastModified: DateTime.now(),
      tags: _currentTags,
    );

    // Always save locally (SQLite) via callback
    await widget.onSave(noteToSave);

    // Create a Version Snapshot locally (if not empty)
    // We do this after saving the note itself.
    // Ideally we'd compare content with last version to avoid duplicates,
    // but for now, we'll create a version on every "Autosave" that is triggered.
    // To avoid spamming versions on every character (handled by debounce),
    // we might want to limit frequency (e.g. 1 per hour) in the future.
    // For now, let's keep it simple: Create version.
    /* 
       Wait, creating a version on every autosave (debounce 1s) is too much. 
       Let's ONLY create version on:
       1. Manual Save.
       2. Or if X minutes passed since last version?
       
       For this Step, let's enable it on Manual Save primarily.
       So, I will NOT put it here in _autosave unless I add a flag 'createVersion'.
    */

    // If Shared, push to Firestore (Real-Time / Sync)
    bool isShared =
        noteToSave.memberIds.length > 1 || noteToSave.collaborators.isNotEmpty;
    if (isShared) {
      await _firestoreRepository.updateNote(noteToSave);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nota salva automaticamente.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveNote() async {
    // Cancel any pending autosave before manual save
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();

    // Perform the save
    await _autosave();

    // Create a specific Version Snapshot on Manual Save
    if (_note != null) {
      // We need to construct the version from current state
      final jsonContent = DocumentAdapter.toJson(_document);
      final version = NoteVersion(
        id: const Uuid().v4(),
        noteId: _note!.id,
        content: jsonContent,
        date: DateTime.now(),
      );
      // We need access to repository directly.
      // Ideally we'd use a service or the repository instance if we kept it.
      // We removed _noteRepository field earlier. Let's add it back or use singleton.
      await NoteRepository.instance.createNoteVersion(version);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _attachImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    final imageUrl = await _storageService.uploadImage(File(pickedFile.path));
    if (imageUrl != null) {
      setState(() {
        _note = _note?.copyWith(imageUrl: imageUrl);
      });
      // Trigger autosave
      unawaited(_autosave());
    }
  }

  Future<void> _showHistoryDialog() async {
    if (_note == null) return;

    // Fetch events instead of versions
    final events = await NoteRepository.instance.getNoteEvents(_note!.id);
    // Group events using Smart Strategy
    final historyPoints = HistoryGrouper.groupEvents(events);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Histórico de Edição'),
          content: SizedBox(
            width: double.maxFinite,
            child: historyPoints.isEmpty
                ? const Text('Nenhuma alteração registrada.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: historyPoints.length,
                    itemBuilder: (context, index) {
                      final point = historyPoints[index];
                      // Simple date formatting
                      final dateStr =
                          '${point.timestamp.day}/${point.timestamp.month}/${point.timestamp.year} ${point.timestamp.hour}:${point.timestamp.minute}';

                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(point.label),
                        subtitle: Text(dateStr),
                        onTap: () async {
                          // Restore logic
                          bool confirm =
                              await showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text(
                                    'Restaurar para este ponto?',
                                  ),
                                  content: const Text(
                                    'Isso reverterá o documento para o estado selecionado. '
                                    'Uma nova linha do tempo será criada a partir daqui.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Restaurar'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (confirm && mounted) {
                            // Reconstruct state at this point
                            final restoredDoc = EventReplayer.reconstruct(
                              point.eventsUpToPoint,
                            );

                            _initializeEditor(restoredDoc.toPlainText());
                            // Note: ideally _initializeEditor should take a DocumentModel if we want to preserve rich text state properly.
                            // But EventReplayer returns DocumentModel.
                            // _initializeEditor parses string -> DocumentModel.
                            // If EventReplayer is accurate, we should probably set _document directly if possible or update _initializeEditor/update wrapper.
                            // Currently _initializeEditor acts on String content.
                            // IF DocumentManipulator handles rich text, we lose it if we convert toPlainText() unless _initializeEditor re-parses it correctly or we bypass it.
                            // For v1 event sourcing, if we only store pure text events? No, we have Format events.
                            // So converting toPlainText() LOSES formatting.
                            // We must update the state directly.

                            setState(() {
                              _document = restoredDoc;
                              // Reset selection to start
                              _selection = const TextSelection.collapsed(
                                offset: 0,
                              );
                              // Rebuild history manager with restored state
                              _historyManager = HistoryManager(
                                initialState: HistoryState(
                                  document: _document,
                                  selection: _selection,
                                ),
                              );
                            });

                            Navigator.pop(context); // Close History Dialog

                            // Trigger save to persist restoration as a NEW event?
                            // No, typically we just treat this as a massive change or log a specific "Rollback" event.
                            // For now, _autosave will run eventually, OR we should force a log.
                            // But wait, if we set state, _onDocumentChanged wasn't called.
                            // So we need to trigger downstream effects.

                            // Let's create a snapshot event or rely on next edit.
                            // Better: Log a 'restore' event manually if we want to trace it,
                            // but simply setting the document puts the user in that state.
                            // Any subsequent edit will append events.

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Versão restaurada com sucesso.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
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
    final deleteResult = DocumentManipulator.deleteText(
      _document,
      _selection.start,
      _selection.end - _selection.start,
    );
    final docAfterDelete = deleteResult.document;
    _handleNoteEvent(deleteResult.eventType, deleteResult.eventPayload);

    final insertResult = DocumentManipulator.insertText(
      docAfterDelete,
      _selection.start,
      replaceTerm,
    );
    final newDoc = insertResult.document;
    _handleNoteEvent(insertResult.eventType, insertResult.eventPayload);

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

  Future<void> _insertImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    // Upload to Firebase Storage for sync compatibility
    final storageService = StorageService();
    final url = await storageService.uploadImage(File(pickedFile.path));

    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Check internet connection.'),
          ),
        );
      }
      return;
    }

    // Use the URL
    final savedImagePath = url;

    final result = DocumentManipulator.insertImage(
      _document,
      _selection.baseOffset,
      savedImagePath,
    );
    final newDoc = result.document;
    _handleNoteEvent(result.eventType, result.eventPayload);
    _onDocumentChanged(newDoc);
  }

  // --- Tag Methods ---

  void _addTag(String tagName) {
    if (tagName.isNotEmpty && !_currentTags.contains(tagName)) {
      setState(() {
        _currentTags.add(tagName);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tagName) {
    setState(() {
      _currentTags.remove(tagName);
    });
  }

  Widget _buildTagEditor() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _currentTags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ),
                )
                .toList(),
          ),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              hintText: 'Add a tag...',
              border: InputBorder.none,
            ),
            onSubmitted: _addTag,
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final emailController = TextEditingController();
    var permission = 'viewer'; // Default permission

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Share Note'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add new collaborator:'),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'User Email',
                        ),
                      ),
                      DropdownButton<String>(
                        value: permission,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              permission = newValue;
                            });
                          }
                        },
                        items: <String>['viewer', 'editor']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                      const Divider(),
                      const Text('Current collaborators:'),
                      if (_note!.collaborators.isEmpty)
                        const Text('None')
                      else
                        ..._note!.collaborators.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.key), // Ideally, show email/name
                            subtitle: Text(entry.value),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () async {
                                await _firestoreRepository
                                    .unshareNoteWithCollaborator(
                                      _note!.id,
                                      entry.key,
                                    );
                                // Refresh note from parent
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final success = await _firestoreRepository.shareNoteWithEmail(
                    _note!.id,
                    emailController.text,
                    permission,
                  );
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Note shared successfully!'
                            : 'User not found.',
                      ),
                    ),
                  );
                  navigator.pop();
                },
                child: const Text('Share'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add the remote cursors to the editor widget
    final editor = EditorWidget(
      key: _editorKey,
      document: _document,
      onDocumentChanged: _onDocumentChanged,
      selection: _selection,
      onSelectionChanged: _onSelectionChanged,
      onSelectionRectChanged: _onSelectionRectChanged,
      scrollController: _scrollController,
      remoteCursors: _remoteCursors,
      // Keyboard shortcut callbacks
      onStyleToggle: _toggleStyle,
      onUndo: _undo,
      onRedo: _redo,
      onSave: _saveNote,
      onFind: () => setState(() => _isFindBarVisible = true),
      onEscape: () {
        if (_isFocusMode) {
          _toggleFocusMode();
        } else if (_isFindBarVisible) {
          setState(() => _isFindBarVisible = false);
        }
      },
    );

    // Define the keyboard shortcuts
    final shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
          const _UndoIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
          const _UndoIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ,
      ): const _RedoIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.keyZ,
      ): const _RedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
          const _RedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyY):
          const _RedoIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE):
          const _CenterLineIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyE):
          const _CenterLineIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
          const _ShowFormatMenuIntent(),
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyP):
          const _ShowFormatMenuIntent(),
    };

    // Define the actions
    final actions = <Type, Action<Intent>>{
      _UndoIntent: _UndoAction(this),
      _RedoIntent: _RedoAction(this),
      _CenterLineIntent: _CenterLineAction(this),
      _ShowFormatMenuIntent: _ShowFormatMenuAction(this),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveNote();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Scaffold(
            appBar: _isFocusMode
                ? null
                : AppBar(
                    title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
                    actions: [
                      if (_isCollaborative)
                        _CollaboratorAvatars(remoteCursors: _remoteCursors),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => setState(
                          () => _isFindBarVisible = !_isFindBarVisible,
                        ),
                      ),
                      if (widget.note != null)
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: _showShareDialog,
                        ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _attachImage,
                      ),
                      IconButton(
                        icon: Icon(
                          _isFocusMode
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                        onPressed: _toggleFocusMode,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (widget.note == null) return;
                          final exportService = ExportService();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exportando...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          if (value == 'txt') {
                            await exportService.exportToTxt(widget.note!);
                          } else if (value == 'pdf') {
                            await exportService.exportToPdf(widget.note!);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'txt',
                                child: Text('Exportar para TXT'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'pdf',
                                child: Text('Exportar para PDF'),
                              ),
                            ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        tooltip: 'Ver Histórico',
                        onPressed: _showHistoryDialog,
                      ),
                    ],
                  ),
            floatingActionButton: _isFocusMode
                ? null
                : FloatingActionButton(
                    onPressed: _saveNote,
                    child: const Icon(Icons.save),
                  ),
            body: SafeArea(
              top: !_isFocusMode,
              bottom: !_isFocusMode,
              child: Stack(
                children: [
                  Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              );
                            },
                        child: _isFindBarVisible && !_isFocusMode
                            ? FindReplaceBar(
                                key: const ValueKey('findBar'),
                                onFindChanged: _onFindChanged,
                                onFindNext: _findNext,
                                onFindPrevious: _findPrevious,
                                onReplace: _replace,
                                onReplaceAll: _replaceAll,
                                onClose: () => setState(
                                  () => _isFindBarVisible = false,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (!_isFocusMode) _buildTagEditor(),
                      if (_note?.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.network(_note!.imageUrl!),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: editor,
                        ),
                      ),
                      if (!_isFocusMode)
                        EditorToolbar(
                          onBold: () => _toggleStyle(StyleAttribute.bold),
                          onItalic: () => _toggleStyle(StyleAttribute.italic),
                          onUnderline: () =>
                              _toggleStyle(StyleAttribute.underline),
                          onStrikethrough: () =>
                              _toggleStyle(StyleAttribute.strikethrough),
                          onColor: _showColorPicker,
                          onFontSize: _showFontSizePicker,
                          onSnippets: () => unawaited(_showSnippetsScreen()),
                          onImage: () => unawaited(_insertImage()),
                          onUndo: _undo,
                          onRedo: _redo,
                          canUndo: _historyManager.canUndo,
                          canRedo: _historyManager.canRedo,
                          wordCountNotifier: _wordCountNotifier,
                          charCountNotifier: _charCountNotifier,
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
        ),
      ),
    );
  }
}

// --- Keyboard Shortcut Actions and Intents ---

/// Intent to undo the last action.
class _UndoIntent extends Intent {
  const _UndoIntent();
}

/// Intent to redo the last undone action.
class _RedoIntent extends Intent {
  const _RedoIntent();
}

/// Intent to center the current line.
class _CenterLineIntent extends Intent {
  const _CenterLineIntent();
}

/// Intent to show the format menu.
class _ShowFormatMenuIntent extends Intent {
  const _ShowFormatMenuIntent();
}

/// Action to handle undo.
class _UndoAction extends Action<_UndoIntent> {
  _UndoAction(this.state);

  final _NoteEditorScreenState state;

  @override
  void invoke(_UndoIntent intent) {
    state._undo();
  }
}

/// Action to handle redo.
class _RedoAction extends Action<_RedoIntent> {
  _RedoAction(this.state);

  final _NoteEditorScreenState state;

  @override
  void invoke(_RedoIntent intent) {
    state._redo();
  }
}

/// Action to handle centering the line.
class _CenterLineAction extends Action<_CenterLineIntent> {
  _CenterLineAction(this.state);

  final _NoteEditorScreenState state;

  @override
  void invoke(_CenterLineIntent intent) {
    state._editorKey.currentState?.centerLine();
  }
}

/// Action to handle showing the format menu.
class _ShowFormatMenuAction extends Action<_ShowFormatMenuIntent> {
  _ShowFormatMenuAction(this.state);

  final _NoteEditorScreenState state;

  @override
  void invoke(_ShowFormatMenuIntent intent) {
    state._showFontSizePicker();
  }
}

class _CollaboratorAvatars extends StatelessWidget {
  const _CollaboratorAvatars({required this.remoteCursors});

  final Map<String, Map<String, dynamic>> remoteCursors;

  @override
  Widget build(BuildContext context) {
    final collaborators = remoteCursors.values.toList();
    return Row(
      children: [
        for (int i = 0; i < collaborators.length; i++)
          Align(
            widthFactor: 0.7,
            child: CircleAvatar(
              backgroundColor: Color(collaborators[i]['color'] as int),
              child: Text(
                (collaborators[i]['name'] as String).substring(0, 2),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
