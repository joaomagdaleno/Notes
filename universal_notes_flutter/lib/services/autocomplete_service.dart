import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

/// A service to provide autocomplete suggestions from multiple sources.
class AutocompleteService {
  static List<String>? _dictionaryCache;

  /// Resets the dictionary cache.
  @visibleForTesting
  static void resetCache() => _dictionaryCache = null;

  /// Gets suggestions for the word being typed at the cursor position.
  static Future<List<String>> getSuggestions(
    String text,
    int cursorPosition,
  ) async {
    if (text.isEmpty) return [];

    // 1. Extract the word being typed.
    var start = cursorPosition;
    while (start > 0 && !isWordBoundary(text[start - 1])) {
      start--;
    }
    final wordInProgress = text.substring(start, cursorPosition).toLowerCase();

    if (wordInProgress.length < 3) return [];

    final suggestions = <String>{};

    // --- Priority 1: Current Note ---
    final matches = RegExp(r'\b\w+\b').allMatches(text);
    for (final match in matches) {
      final word = match.group(0)!.toLowerCase();
      if (word != wordInProgress && word.startsWith(wordInProgress)) {
        suggestions.add(match.group(0)!);
      }
    }

    if (suggestions.length >= 5) {
      return suggestions.take(5).toList();
    }

    // --- Priority 2: User Dictionary (Learned Words) ---
    final learnedWords = await NoteRepository.instance.getLearnedWords(
      wordInProgress,
    );
    for (final word in learnedWords) {
      if (word.toLowerCase() != wordInProgress) {
        suggestions.add(word);
        if (suggestions.length >= 5) return suggestions.take(5).toList();
      }
    }

    // --- Priority 3: Dictionary ---
    _dictionaryCache ??= await _loadDictionary();
    for (final word in _dictionaryCache!) {
      if (word.toLowerCase().startsWith(wordInProgress)) {
        suggestions.add(word);
        if (suggestions.length >= 5) return suggestions.take(5).toList();
      }
    }

    return suggestions.take(5).toList();
  }

  static Future<List<String>> _loadDictionary() async {
    final content = await rootBundle.loadString(
      'assets/dictionaries/pt_br_common.txt',
    );
    return content.split('\n');
  }

  /// Checks if the character is a word boundary.
  static bool isWordBoundary(String char) {
    return RegExp(r'[\s,.;\n\t]').hasMatch(char);
  }
}
