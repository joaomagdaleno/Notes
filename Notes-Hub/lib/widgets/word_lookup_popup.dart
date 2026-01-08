import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/services/word_lookup_service.dart';
import 'package:notes_hub/widgets/lookup/fluent_lookup_view.dart';
import 'package:notes_hub/widgets/lookup/material_lookup_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// A popup widget for displaying word definitions and Wikipedia summaries.
///
/// This widget acts as a controller, managing state and logic,
/// while delegating the UI to platform-specific view widgets.
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentLookupView(
        word: widget.word,
        definition: _definition,
        wikipedia: _wikipedia,
        loadingDef: _loadingDef,
        loadingWiki: _loadingWiki,
        errorDef: _errorDef,
        errorWiki: _errorWiki,
        tabIndex: _tabController.index,
        onTabChanged: (index) {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        onClose: widget.onClose,
        onOpenUrl: (url) => unawaited(_openUrl(url)),
      );
    } else {
      return MaterialLookupView(
        word: widget.word,
        definition: _definition,
        wikipedia: _wikipedia,
        loadingDef: _loadingDef,
        loadingWiki: _loadingWiki,
        errorDef: _errorDef,
        errorWiki: _errorWiki,
        tabController: _tabController,
        onClose: widget.onClose,
        onOpenUrl: (url) => unawaited(_openUrl(url)),
      );
    }
  }
}
