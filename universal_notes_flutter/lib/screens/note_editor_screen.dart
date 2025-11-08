import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
  late quill.QuillController _contentController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  Note? _currentNote;
  bool _isToolbarVisible = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');
    _initializeContentController();

    _debounce = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveNote();
    });

    _contentController.changes.listen((event) {
      setState(() {});
    });
  }

  void _initializeContentController() {
    final content = _currentNote?.content;
    if (content != null && content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(content));
        _contentController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        return;
      } catch (e) {
        // Fallback for plain text
      }
    }
    _contentController = quill.QuillController.basic();
  }


  @override
  void dispose() {
    _debounce?.cancel();
    _saveNote();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final contentJson = jsonEncode(_contentController.document.toDelta().toJson());

    if (title.isEmpty && _contentController.document.isEmpty()) {
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

  Widget _buildFluentUI(BuildContext context) {
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
              decoration: fluent.WidgetStateProperty.all(const fluent.BoxDecoration(
                border: null,
              )),
              style: fluent.FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 16),
            quill.QuillToolbar.simple(
              controller: _contentController,
              configurations: quill.QuillSimpleToolbarConfig(
                showUndo: true,
                showRedo: true,
                showBoldButton: false,
                showItalicButton: false,
                showUnderlineButton: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showClearFormat: false,
                showFontFamily: false,
                showFontSize: false,
                showHeaderStyle: false,
                showListNumbers: false,
                showListBullets: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showSearchButton: false,
                showDirection: false,
                showAlignmentButtons: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                customButtons: [
                  quill.QuillToolbarCustomButton(
                    child: const Icon(fluent.FluentIcons.keyboard_classic),
                    onTap: () {
                      setState(() {
                        _isToolbarVisible = !_isToolbarVisible;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_isToolbarVisible)
              quill.QuillToolbar.simple(
                controller: _contentController,
                configurations: quill.QuillSimpleToolbarConfig(
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                  showAlignmentButtons: true,
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: quill.QuillEditor(
                controller: _contentController,
                focusNode: _editorFocusNode,
                scrollController: _scrollController,
                configurations: quill.QuillEditorConfig(
                  padding: const EdgeInsets.all(16),
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            quill.QuillToolbar.simple(
              controller: _contentController,
              configurations: quill.QuillSimpleToolbarConfig(
                showUndo: true,
                showRedo: true,
                showBoldButton: false,
                showItalicButton: false,
                showUnderlineButton: false,
                showStrikeThrough: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showClearFormat: false,
                showFontFamily: false,
                showFontSize: false,
                showHeaderStyle: false,
                showListNumbers: false,
                showListBullets: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showSearchButton: false,
                showDirection: false,
                showAlignmentButtons: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                customButtons: [
                  quill.QuillToolbarCustomButton(
                    child: const Icon(Icons.keyboard),
                    onTap: () {
                      setState(() {
                        _isToolbarVisible = !_isToolbarVisible;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_isToolbarVisible)
              quill.QuillToolbar.simple(
                controller: _contentController,
                configurations: quill.QuillSimpleToolbarConfig(
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                  showAlignmentButtons: true,
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: quill.QuillEditor(
                controller: _contentController,
                focusNode: _editorFocusNode,
                scrollController: _scrollController,
                configurations: quill.QuillEditorConfig(
                  padding: const EdgeInsets.all(16),
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
