import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/snippet.dart';

/// Material Design view for SnippetsScreen
class MaterialSnippetsView extends StatelessWidget {
  final List<Snippet> snippets;
  final VoidCallback onAddSnippet;
  final void Function(Snippet) onEditSnippet;
  final void Function(String) onDeleteSnippet;

  const MaterialSnippetsView({
    super.key,
    required this.snippets,
    required this.onAddSnippet,
    required this.onEditSnippet,
    required this.onDeleteSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Snippets'),
      ),
      body: ListView.builder(
        itemCount: snippets.length,
        itemBuilder: (context, index) {
          final snippet = snippets[index];
          return ListTile(
            title: Text(snippet.trigger),
            subtitle: Text(snippet.content),
            onTap: () => onEditSnippet(snippet),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onDeleteSnippet(snippet.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddSnippet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
