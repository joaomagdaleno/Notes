import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/snippet.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/snippets/views/fluent_snippets_view.dart';
import 'package:notes_hub/screens/snippets/views/material_snippets_view.dart';

/// Controller for the snippets screen.
class SnippetsScreen extends StatefulWidget {
  /// Creates a [SnippetsScreen].
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  List<Snippet> _snippets = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSnippets());
  }

  Future<void> _loadSnippets() async {
    final snippets = await NoteRepository.instance.getAllSnippets();
    setState(() {
      _snippets = snippets;
    });
  }

  Future<void> _handleEditSnippet(Snippet? snippet) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await _showEditDialogFluent(snippet: snippet);
    } else {
      await _showEditDialogMaterial(snippet: snippet);
    }
  }

  Future<void> _handleDeleteSnippet(String id) async {
    await NoteRepository.instance.deleteSnippet(id);
    await _loadSnippets();
  }

  Future<void> _showEditDialogMaterial({Snippet? snippet}) async {
    final triggerController = TextEditingController(text: snippet?.trigger);
    final contentController = TextEditingController(text: snippet?.content);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(snippet == null ? 'New Snippet' : 'Edit Snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: triggerController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Trigger (e.g., ;email)',
              ),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'trigger': triggerController.text,
                'content': contentController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveSnippet(snippet, result);
    }
  }

  Future<void> _showEditDialogFluent({Snippet? snippet}) async {
    final triggerController = TextEditingController(text: snippet?.trigger);
    final contentController = TextEditingController(text: snippet?.content);

    final result = await fluent.showDialog<Map<String, String>>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(snippet == null ? 'New Snippet' : 'Edit Snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fluent.InfoLabel(
              label: 'Trigger (e.g., ;email)',
              child: fluent.TextBox(
                controller: triggerController,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: 'Content',
              child: fluent.TextBox(
                controller: contentController,
              ),
            ),
          ],
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          fluent.FilledButton(
            onPressed: () {
              Navigator.of(context).pop({
                'trigger': triggerController.text,
                'content': contentController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveSnippet(snippet, result);
    }
  }

  Future<void> _saveSnippet(Snippet? snippet, Map<String, String> data) async {
    if (snippet == null) {
      await NoteRepository.instance.createSnippet(
        trigger: data['trigger']!,
        content: data['content']!,
      );
    } else {
      await NoteRepository.instance.updateSnippet(
        Snippet(
          id: snippet.id,
          trigger: data['trigger']!,
          content: data['content']!,
        ),
      );
    }
    await _loadSnippets();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentSnippetsView(
        snippets: _snippets,
        onAddSnippet: () => _handleEditSnippet(null),
        onEditSnippet: _handleEditSnippet,
        onDeleteSnippet: _handleDeleteSnippet,
      );
    } else {
      return MaterialSnippetsView(
        snippets: _snippets,
        onAddSnippet: () => _handleEditSnippet(null),
        onEditSnippet: _handleEditSnippet,
        onDeleteSnippet: _handleDeleteSnippet,
      );
    }
  }
}
