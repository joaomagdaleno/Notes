import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/word_lookup_service.dart';

class FluentLookupView extends StatelessWidget {
  const FluentLookupView({
    required this.word,
    required this.definition,
    required this.wikipedia,
    required this.loadingDef,
    required this.loadingWiki,
    required this.errorDef,
    required this.errorWiki,
    required this.tabIndex,
    required this.onTabChanged,
    required this.onClose,
    required this.onOpenUrl,
    super.key,
  });

  final String word;
  final WordDefinition? definition;
  final WikipediaSummary? wikipedia;
  final bool loadingDef;
  final bool loadingWiki;
  final String? errorDef;
  final String? errorWiki;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onClose;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      width: 350,
      height: 400,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    word,
                    style: theme.typography.subtitle,
                  ),
                ),
                if (definition?.phonetic != null)
                  Text(
                    definition!.phonetic!,
                    style: theme.typography.caption?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.chrome_close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Tabs
          fluent.TabView(
            currentIndex: tabIndex,
            onChanged: onTabChanged,
            tabs: [
              fluent.Tab(
                text: const Text('Dictionary'),
                body: _buildDictionaryTab(context),
              ),
              fluent.Tab(
                text: const Text('Wikipedia'),
                body: _buildWikipediaTab(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryTab(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    if (loadingDef) {
      return const Center(child: fluent.ProgressRing());
    }

    if (errorDef != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorDef!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[400]),
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
                  color: theme.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  def.partOfSpeech,
                  style: theme.typography.caption,
                ),
              ),
              const SizedBox(height: 4),
              Text(def.definition),
              if (def.example != null) ...[
                const SizedBox(height: 4),
                Text(
                  '"${def.example}"',
                  style: theme.typography.caption?.copyWith(
                    fontStyle: FontStyle.italic,
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
    final theme = fluent.FluentTheme.of(context);

    if (loadingWiki) {
      return const Center(child: fluent.ProgressRing());
    }

    if (errorWiki != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorWiki!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[400]),
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
          Text(wikipedia!.title, style: theme.typography.bodyStrong),
          const SizedBox(height: 8),
          Text(wikipedia!.extract),
          if (wikipedia!.pageUrl != null) ...[
            const SizedBox(height: 12),
            fluent.HyperlinkButton(
              onPressed: () => onOpenUrl(wikipedia!.pageUrl!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(fluent.FluentIcons.open_in_new_window, size: 14),
                  const SizedBox(width: 4),
                  const Text('Read more on Wikipedia'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
