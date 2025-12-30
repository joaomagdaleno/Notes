import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/word_lookup_service.dart';

/// A Material Design view for dictionary and Wikipedia lookup.
class MaterialLookupView extends StatelessWidget {
  /// Creates a [MaterialLookupView].
  const MaterialLookupView({
    required this.word,
    required this.definition,
    required this.wikipedia,
    required this.loadingDef,
    required this.loadingWiki,
    required this.errorDef,
    required this.errorWiki,
    required this.tabController,
    required this.onClose,
    required this.onOpenUrl,
    super.key,
  });

  /// The word being looked up.
  final String word;

  /// The dictionary definition, if found.
  final WordDefinition? definition;

  /// The Wikipedia summary, if found.
  final WikipediaSummary? wikipedia;

  /// Whether the dictionary definition is currently loading.
  final bool loadingDef;

  /// Whether the Wikipedia summary is currently loading.
  final bool loadingWiki;

  /// Error message if the dictionary lookup failed.
  final String? errorDef;

  /// Error message if the Wikipedia lookup failed.
  final String? errorWiki;

  /// Controller for the tabbed interface.
  final TabController tabController;

  /// Callback to close the lookup view.
  final VoidCallback? onClose;

  /// Callback to open an external URL.
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 350,
        height: 400,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      word,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (definition?.phonetic != null)
                    Text(
                      definition!.phonetic!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: 'Dictionary'),
                Tab(text: 'Wikipedia'),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildDictionaryTab(context),
                  _buildWikipediaTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDictionaryTab(BuildContext context) {
    if (loadingDef) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorDef != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorDef!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (definition == null) {
      return const Center(child: Text('No definition found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: definition!.definitions.length,
      itemBuilder: (context, index) {
        final def = definition!.definitions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  def.partOfSpeech,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(def.definition),
              if (def.example != null) ...[
                const SizedBox(height: 4),
                Text(
                  '"${def.example}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWikipediaTab(BuildContext context) {
    if (loadingWiki) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorWiki != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorWiki!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (wikipedia == null) {
      return const Center(child: Text('No article found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wikipedia!.thumbnailUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                wikipedia!.thumbnailUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (a, b, c) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            wikipedia!.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(wikipedia!.extract),
          if (wikipedia!.pageUrl != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => onOpenUrl(wikipedia!.pageUrl!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Read more on Wikipedia'),
            ),
          ],
        ],
      ),
    );
  }
}
