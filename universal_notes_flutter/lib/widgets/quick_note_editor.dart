import 'dart:async';

import 'package:flutter/material.dart';

/// A quick editor for creating simple notes.
class QuickNoteEditor extends StatefulWidget {
  /// Creates a new instance of [QuickNoteEditor].
  const QuickNoteEditor({
    required this.onSave,
    super.key,
  });

  /// Callback when the note is saved.
  final ValueChanged<String> onSave;

  @override
  State<QuickNoteEditor> createState() => _QuickNoteEditorState();
}

class _QuickNoteEditorState extends State<QuickNoteEditor> {
  final _controller = TextEditingController();
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    // Autosave every 10 seconds
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_controller.text.isNotEmpty) {
        widget.onSave(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_controller.text.isNotEmpty) {
      widget.onSave(_controller.text);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nota Rápida',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Digite sua nota rápida...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
