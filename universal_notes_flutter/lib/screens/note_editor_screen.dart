import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
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
  late TextEditingController _contentController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.contentPreview ?? '');

    // Inicia o timer para salvamento periódico
    _debounce = Timer.periodic(const Duration(minutes: 5), (timer) {
      _saveNote();
    });
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
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      return; // Não salva notas vazias
    }

    final note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      contentPreview: _contentController.text,
      date: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
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
        leading: fluent.CommandBarButton(
          icon: const fluent.Icon(fluent.FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        mainAxisAlignment: fluent.MainAxisAlignment.end,
        primaryItems: [
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.save),
            label: const Text('Salvar e fechar'),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
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
              decoration: fluent.WidgetStateProperty.all(const fluent.BoxDecoration(
                border: null,
              )),
              style: fluent.FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: fluent.TextBox(
                controller: _contentController,
                placeholder: 'Conteúdo',
                maxLines: null,
                decoration: fluent.WidgetStateProperty.all(const fluent.BoxDecoration(
                  border: null,
                )),
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
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Conteúdo',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
