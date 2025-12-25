import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service for looking up word definitions and translations.
///
/// Uses free dictionary API and Wikipedia.
class WordLookupService {
  /// Creates a new [WordLookupService].
  WordLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _dictionaryBaseUrl =
      'https://api.dictionaryapi.dev/api/v2/entries';
  static const _wikipediaBaseUrl = 'https://en.wikipedia.org/api/rest_v1';

  /// Looks up a word definition.
  Future<WordDefinition?> lookupDefinition(
    String word, {
    String language = 'en',
  }) async {
    try {
      final url = Uri.parse('$_dictionaryBaseUrl/$language/$word');
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as List<dynamic>;
      if (data.isEmpty) return null;

      final entry = data[0] as Map<String, dynamic>;
      final meanings = entry['meanings'] as List<dynamic>? ?? [];

      final definitions = <DefinitionEntry>[];
      for (final meaning in meanings) {
        final meaningMap = meaning as Map<String, dynamic>;
        final partOfSpeech = meaningMap['partOfSpeech'] as String? ?? '';
        final defs = meaningMap['definitions'] as List<dynamic>? ?? [];

        for (final def in defs) {
          final defMap = def as Map<String, dynamic>;
          definitions.add(
            DefinitionEntry(
              partOfSpeech: partOfSpeech,
              definition: defMap['definition'] as String? ?? '',
              example: defMap['example'] as String?,
            ),
          );
        }
      }

      final phonetics = entry['phonetics'] as List<dynamic>? ?? [];
      String? phoneticText;
      String? audioUrl;

      for (final phonetic in phonetics) {
        final phoneticMap = phonetic as Map<String, dynamic>;
        phoneticText ??= phoneticMap['text'] as String?;
        audioUrl ??= phoneticMap['audio'] as String?;
        if (phoneticText != null && audioUrl != null) break;
      }

      return WordDefinition(
        word: word,
        phonetic: phoneticText,
        audioUrl: audioUrl,
        definitions: definitions,
      );
    } on Exception {
      return null;
    }
  }

  /// Looks up a word on Wikipedia.
  Future<WikipediaSummary?> lookupWikipedia(String term) async {
    try {
      final encoded = Uri.encodeComponent(term);
      final url = Uri.parse('$_wikipediaBaseUrl/page/summary/$encoded');
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final contentUrls = data['content_urls'] as Map<String, dynamic>?;
      final desktop = contentUrls?['desktop'] as Map<String, dynamic>?;
      final thumbnail = data['thumbnail'] as Map<String, dynamic>?;

      return WikipediaSummary(
        title: data['title'] as String? ?? term,
        extract: data['extract'] as String? ?? '',
        pageUrl: desktop?['page'] as String?,
        thumbnailUrl: thumbnail?['source'] as String?,
      );
    } on Exception {
      return null;
    }
  }

  /// Disposes resources.
  void dispose() {
    _client.close();
  }
}

/// A word definition result.
class WordDefinition {
  /// Creates a new [WordDefinition].
  const WordDefinition({
    required this.word,
    required this.definitions,
    this.phonetic,
    this.audioUrl,
  });

  /// The word being defined.
  final String word;

  /// Phonetic pronunciation.
  final String? phonetic;

  /// URL to audio pronunciation.
  final String? audioUrl;

  /// List of definitions.
  final List<DefinitionEntry> definitions;
}

/// A single definition entry.
class DefinitionEntry {
  /// Creates a new [DefinitionEntry].
  const DefinitionEntry({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  /// Part of speech (noun, verb, etc.).
  final String partOfSpeech;

  /// The definition text.
  final String definition;

  /// Optional example usage.
  final String? example;
}

/// A Wikipedia summary result.
class WikipediaSummary {
  /// Creates a new [WikipediaSummary].
  const WikipediaSummary({
    required this.title,
    required this.extract,
    this.pageUrl,
    this.thumbnailUrl,
  });

  /// Article title.
  final String title;

  /// Summary extract.
  final String extract;

  /// Full page URL.
  final String? pageUrl;

  /// Thumbnail image URL.
  final String? thumbnailUrl;
}
