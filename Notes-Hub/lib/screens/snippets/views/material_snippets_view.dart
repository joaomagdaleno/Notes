import 'package:flutter/material.dart';
import 'package:notes_hub/models/snippet.dart';

/// Material Design view for SnippetsScreen
class MaterialSnippetsView extends StatelessWidget {
  /// Creates a [MaterialSnippetsView].
  const MaterialSnippetsView({
    required this.snippets,
    required this.onAddSnippet,
    required this.onEditSnippet,
    required this.onDeleteSnippet,
    super.key,
  });

  /// The list of snippets to display.
  final List<Snippet> snippets;
  /// Callback for adding a new snippet.
  final VoidCallback onAddSnippet;
  /// Callback for editing a snippet.
  final void Function(Snippet) onEditSnippet;
  /// Callback for deleting a snippet.
  final void Function(String) onDeleteSnippet;

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
