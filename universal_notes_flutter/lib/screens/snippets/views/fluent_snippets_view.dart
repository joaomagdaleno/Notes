import 'package:fluent_ui/fluent_ui.dart';
import 'package:universal_notes_flutter/models/snippet.dart';

/// Fluent UI view for SnippetsScreen - WinUI 3 styling
class FluentSnippetsView extends StatelessWidget {
  final List<Snippet> snippets;
  final VoidCallback onAddSnippet;
  final void Function(Snippet) onEditSnippet;
  final void Function(String) onDeleteSnippet;

  const FluentSnippetsView({
    super.key,
    required this.snippets,
    required this.onAddSnippet,
    required this.onEditSnippet,
    required this.onDeleteSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Gerenciar Snippets'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Adicionar Snippet'),
              onPressed: onAddSnippet,
            ),
          ],
        ),
      ),
      content: ListView.builder(
        itemCount: snippets.length,
        itemBuilder: (context, index) {
          final snippet = snippets[index];
          return ListTile.selectable(
            title: Text(snippet.trigger),
            subtitle: Text(snippet.content),
            onPressed: () => onEditSnippet(snippet),
            trailing: IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: () => onDeleteSnippet(snippet.id),
            ),
          );
        },
      ),
    );
  }
}
