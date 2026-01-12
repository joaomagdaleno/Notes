import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/snippet.dart';
import 'package:notes_hub/repositories/note_repository.dart';

/// A screen to manage custom snippets.
class SnippetsScreen extends StatefulWidget {
  /// Creates a new instance of [SnippetsScreen].
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
            onPressed: () {
              Navigator.of(context).pop();
            },
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
      if (snippet == null) {
        await NoteRepository.instance.createSnippet(
          trigger: result['trigger']!,
          content: result['content']!,
        );
      } else {
        await NoteRepository.instance.updateSnippet(
          Snippet(
            id: snippet.id,
            trigger: result['trigger']!,
            content: result['content']!,
          ),
        );
      }
      await _loadSnippets();
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
            onPressed: () {
              Navigator.of(context).pop();
            },
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
      if (snippet == null) {
        await NoteRepository.instance.createSnippet(
          trigger: result['trigger']!,
          content: result['content']!,
        );
      } else {
        await NoteRepository.instance.updateSnippet(
          Snippet(
            id: snippet.id,
            trigger: result['trigger']!,
            content: result['content']!,
          ),
        );
      }
      await _loadSnippets();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: const Text('Manage Snippets'),
        commandBar: fluent.CommandBar(
          primaryItems: [
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.add),
              label: const Text('Add Snippet'),
              onPressed: () => unawaited(_showEditDialogFluent()),
            ),
          ],
        ),
      ),
      content: ListView.builder(
        itemCount: _snippets.length,
        itemBuilder: (context, index) {
          final snippet = _snippets[index];
          return fluent.ListTile.selectable(
            title: Text(snippet.trigger),
            subtitle: Text(snippet.content),
            onPressed: () => unawaited(_showEditDialogFluent(snippet: snippet)),
            trailing: fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.delete),
              onPressed: () async {
                await NoteRepository.instance.deleteSnippet(snippet.id);
                await _loadSnippets();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Snippets'),
      ),
      body: ListView.builder(
        itemCount: _snippets.length,
        itemBuilder: (context, index) {
          final snippet = _snippets[index];
          return ListTile(
            title: Text(snippet.trigger),
            subtitle: Text(
              snippet.content,
            ),
            onTap: () => unawaited(_showEditDialogMaterial(snippet: snippet)),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await NoteRepository.instance.deleteSnippet(snippet.id);
                await _loadSnippets();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_showEditDialogMaterial()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
