import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/snippet.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

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
    _loadSnippets();
  }

  Future<void> _loadSnippets() async {
    final snippets = await NoteRepository.instance.getAllSnippets();
    setState(() {
      _snippets = snippets;
    });
  }

  Future<void> _showEditDialog({Snippet? snippet}) async {
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
              decoration: const InputDecoration(labelText: 'Trigger (e.g., ;email)'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
          Snippet(id: snippet.id, trigger: result['trigger']!, content: result['content']!),
        );
      }
      _loadSnippets();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            subtitle: Text(snippet.content, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _showEditDialog(snippet: snippet),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await NoteRepository.instance.deleteSnippet(snippet.id);
                _loadSnippets();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
