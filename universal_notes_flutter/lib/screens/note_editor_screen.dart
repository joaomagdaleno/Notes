import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'dart:io' show Platform;
import '../models/note.dart';
import '../widgets/custom_editor_toolbar.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Future<Note> Function(Note) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late EditorState _editorState;
  Timer? _debounce;
  Note? _currentNote;
  final ValueNotifier<bool> _isToolbarVisible =
      ValueNotifier<bool>(!Platform.isAndroid && !Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');
    _initializeContentController();

    _debounce = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveNote();
    });
  }

  void _initializeContentController() {
    final content = _currentNote?.content;
    if (content != null && content.isNotEmpty) {
      try {
        // First, try to decode as AppFlowy's format
        final json = jsonDecode(content);
        final document = Document.fromJson(json);
        _editorState = EditorState(document: document);
        return;
      } catch (e) {
        // If that fails, try to decode as Quill Delta format
        try {
          final delta = Delta.fromJson(jsonDecode(content));
          final document = quillDeltaEncoder.convert(delta);
          _editorState = EditorState(document: document);
          return;
        } catch (e) {
          // If both fail, create a blank editor
        }
      }
    }
    _editorState = EditorState.blank(withInitialText: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveNote();
    _titleController.dispose();
    _editorState.dispose();
    _isToolbarVisible.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final contentJson = jsonEncode(_editorState.document.toJson());

    if (title.isEmpty && _editorState.document.isEmpty) {
      return;
    }

    final note = Note(
      id: _currentNote?.id,
      title: title,
      content: contentJson,
      date: _currentNote?.date ?? DateTime.now(),
    );
    final savedNote = await widget.onSave(note);
    if (mounted) {
      setState(() {
        _currentNote = savedNote;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildEditor({bool showToolbar = true}) {
    return Column(
      children: [
        if (showToolbar)
          CustomEditorToolbar(
            editorState: _editorState,
            isVisible: _isToolbarVisible.value,
          ),
        Expanded(
          child: AppFlowyEditor(
            editorState: _editorState,
            characterShortcutEvents: standardCharacterShortcutEvents,
            commandShortcutEvents: standardCommandShortcutEvents,
          ),
        ),
      ],
    );
  }

  Widget _buildFluentUI(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget body;
    if (isDesktop) {
      body = Column(
        children: [
          CustomEditorToolbar(editorState: _editorState, isVisible: true),
          Expanded(child: _buildEditor(showToolbar: false)),
        ],
      );
    } else if (isMobile) {
      body = Column(
        children: [
          Expanded(child: _buildEditor(showToolbar: false)),
          CustomEditorToolbar(editorState: _editorState, isVisible: true),
        ],
      );
    } else {
      // Tablet
      body = ValueListenableBuilder<bool>(
        valueListenable: _isToolbarVisible,
        builder: (context, visible, child) {
          return Column(
            children: [
              if (visible)
                CustomEditorToolbar(editorState: _editorState, isVisible: true),
              Expanded(child: _buildEditor(showToolbar: false)),
            ],
          );
        },
      );
    }

    return fluent.ScaffoldPage(
      header: fluent.CommandBar(
        mainAxisAlignment: fluent.MainAxisAlignment.start,
        primaryItems: [
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
          if (!isDesktop && !isMobile) // Tablet
            fluent.CommandBarButton(
              icon: fluent.Icon(
                  _isToolbarVisible.value ? fluent.FluentIcons.edit_off : fluent.FluentIcons.edit),
              onPressed: () {
                _isToolbarVisible.value = !_isToolbarVisible.value;
              },
            ),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: fluent.Column(
          children: [
            fluent.TextBox(
              controller: _titleController,
              placeholder: 'Título',
              decoration: fluent.WidgetStateProperty.all(
                  const fluent.BoxDecoration(
                border: null,
              )),
              style: fluent.FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 16),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    Widget body;
    if (isDesktop) {
      body = Column(
        children: [
          CustomEditorToolbar(editorState: _editorState, isVisible: true),
          Expanded(child: _buildEditor(showToolbar: false)),
        ],
      );
    } else if (isMobile) {
      body = Column(
        children: [
          Expanded(child: _buildEditor(showToolbar: false)),
          CustomEditorToolbar(editorState: _editorState, isVisible: true),
        ],
      );
    } else {
      // Tablet
      body = ValueListenableBuilder<bool>(
        valueListenable: _isToolbarVisible,
        builder: (context, visible, child) {
          return Column(
            children: [
              if (visible)
                CustomEditorToolbar(editorState: _editorState, isVisible: true),
              Expanded(child: _buildEditor(showToolbar: false)),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nova Nota' : 'Editar Nota'),
        actions: [
          if (!isDesktop && !isMobile) // Tablet
            IconButton(
              icon: Icon(
                  _isToolbarVisible.value ? Icons.edit_off : Icons.edit),
              onPressed: () {
                _isToolbarVisible.value = !_isToolbarVisible.value;
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
              ),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
