import 'dart:async';
import 'dart:convert';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
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
  late EditorState editorState;
  late DrawingController drawingController;
  late TextEditingController _titleController;
  Timer? _debounce;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');

    editorState = EditorState(
      document: widget.note?.content != null && widget.note!.content.isNotEmpty
          ? Document.fromJson(jsonDecode(widget.note!.content))
          : Document.blank(),
    );

    drawingController = DrawingController();
    if (widget.note?.drawingJson != null && widget.note!.drawingJson!.isNotEmpty) {
      drawingController.addContents(
        (jsonDecode(widget.note!.drawingJson!) as List)
            .cast<Map<String, dynamic>>()
            .map(PaintContent.fromJson)
            .toList(),
      );
    }

    _debounce = Timer.periodic(const Duration(seconds: 5), (_) => _saveNote());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveNote();
    _titleController.dispose();
    editorState.dispose();
    drawingController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final contentJson = jsonEncode(editorState.document.toJson());
    final strokesJson = jsonEncode(drawingController.getJsonList());

    final note = Note(
      id: _currentNote?.id,
      title: title,
      content: contentJson,
      drawingJson: strokesJson,
      date: _currentNote?.date ?? DateTime.now(),
    );

    final saved = await widget.onSave(note);
    if (mounted) setState(() => _currentNote = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          CustomEditorToolbar(
              editorState: editorState, drawingController: drawingController),
          Expanded(
            child: Row(
              children: [
                // Text Editor Area
                Expanded(
                  child: AppFlowyEditor(
                    editorState: editorState,
                  ),
                ),
                // Drawing Board Area
                Expanded(
                  child: DrawingBoard(
                    controller: drawingController,
                    background: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
