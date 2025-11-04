import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:io' show Platform;
import '../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _initializeContentController();

    // Inicia o timer para salvamento periódico
    _debounce = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveNote();
    });
  }

  void _initializeContentController() {
    final content = widget.note?.content;
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
    _saveNote(); // Salva uma última vez ao sair
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text;
    final contentJson = jsonEncode(_contentController.document.toDelta().toJson());

    // Não salva notas vazias
    if (title.isEmpty && _contentController.document.isEmpty()) {
      return;
    }

    final note = Note(
      id: widget.note?.id,
      title: title,
      content: contentJson,
      date: widget.note?.date ?? DateTime.now(),
    );
    widget.onSave(note);
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
        mainAxisAlignment: fluent.MainAxisAlignment.end,
        primaryItems: [
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.back),
            label: const Text('Voltar'),
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
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _contentController,
                sharedConfigurations: const quill.QuillSharedConfigurations(
                  locale: Locale('pt_BR'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _contentController,
                  padding: const EdgeInsets.all(16),
                  sharedConfigurations: const quill.QuillSharedConfigurations(
                    locale: Locale('pt_BR'),
                  ),
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
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _contentController,
                sharedConfigurations: const quill.QuillSharedConfigurations(
                  locale: Locale('pt_BR'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _contentController,
                  padding: const EdgeInsets.all(16),
                  sharedConfigurations: const quill.QuillSharedConfigurations(
                    locale: Locale('pt_BR'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
