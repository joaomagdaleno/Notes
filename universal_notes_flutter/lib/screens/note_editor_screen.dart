import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'dart:io' show Platform;
import '../models/note.dart';

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
        final delta = Delta.fromJson(jsonDecode(content));
        _editorState = EditorState.fromDelta(delta);
        return;
      } catch (e) {
        // Fallback for plain text or invalid format
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
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final contentJson = jsonEncode(_editorState.document.toDelta().toJson());

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

  Widget _buildEditor() {
    return AppFlowyEditor(
      editorState: _editorState,
      characterShortcutEvents: standardCharacterShortcutEvents,
    );
  }

  Widget _buildFluentUI(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return fluent.ScaffoldPage(
      header: fluent.CommandBar(
        mainAxisAlignment: fluent.MainAxisAlignment.start,
        primaryItems: [
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.pop(context),
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
            if (isDesktop)
              DesktopToolbar(
                editorState: _editorState,
              ),
            Expanded(child: _buildEditor()),
            if (!isDesktop)
              MobileToolbar(
                editorState: _editorState,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nova Nota' : 'Editar Nota'),
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
            if (isDesktop)
              DesktopToolbar(
                editorState: _editorState,
              ),
            Expanded(child: _buildEditor()),
            if (!isDesktop)
              MobileToolbar(
                editorState: _editorState,
              ),
          ],
        ),
      ),
    );
  }
}
