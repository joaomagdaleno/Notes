import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/word_lookup_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A popup widget for displaying word definitions and Wikipedia summaries.
class WordLookupPopup extends StatefulWidget {
  /// Creates a new [WordLookupPopup].
  const WordLookupPopup({
    required this.word,
    required this.service,
    this.onClose,
    super.key,
  });

  /// The word to look up.
  final String word;

  /// The lookup service to use.
  final WordLookupService service;

  /// Callback when popup is closed.
  final VoidCallback? onClose;

  @override
  State<WordLookupPopup> createState() => _WordLookupPopupState();
}

class _WordLookupPopupState extends State<WordLookupPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WordDefinition? _definition;
  WikipediaSummary? _wikipedia;
  bool _loadingDef = true;
  bool _loadingWiki = true;
  String? _errorDef;
  String? _errorWiki;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadDefinition());
    unawaited(_loadWikipedia());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDefinition() async {
    try {
      final result = await widget.service.lookupDefinition(widget.word);
      if (mounted) {
        setState(() {
          _definition = result;
          _loadingDef = false;
          if (result == null) {
            _errorDef = 'No definition found';
          }
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loadingDef = false;
          _errorDef = 'Failed to load definition: $e';
        });
      }
    }
  }

  Future<void> _loadWikipedia() async {
    try {
      final result = await widget.service.lookupWikipedia(widget.word);
      if (mounted) {
        setState(() {
          _wikipedia = result;
          _loadingWiki = false;
          if (result == null) {
            _errorWiki = 'No Wikipedia article found';
          }
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loadingWiki = false;
          _errorWiki = 'Failed to load Wikipedia: $e';
        });
      }
    }
  }

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
                      widget.word,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (_definition?.phonetic != null)
                    Text(
                      _definition!.phonetic!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dictionary'),
                Tab(text: 'Wikipedia'),
              ],
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDictionaryTab(),
                  _buildWikipediaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDictionaryTab() {
    if (_loadingDef) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorDef != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorDef!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_definition == null) {
      return const Center(child: Text('No definition found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _definition!.definitions.length,
      itemBuilder: (context, index) {
        final def = _definition!.definitions[index];
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

  Widget _buildWikipediaTab() {
    if (_loadingWiki) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorWiki != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorWiki!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_wikipedia == null) {
      return const Center(child: Text('No article found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_wikipedia!.thumbnailUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _wikipedia!.thumbnailUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (a, b, c) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            _wikipedia!.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_wikipedia!.extract),
          if (_wikipedia!.pageUrl != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => unawaited(_openUrl(_wikipedia!.pageUrl!)),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Read more on Wikipedia'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
