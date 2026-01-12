import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/tag.dart';

/// A service to suggest tags based on the content of a note.
class TagSuggestionService {
  /// Analyzes the note content and suggests relevant tags.
  ///
  /// [document]: The document model of the note.
  /// [allTags]: A list of all tags available in the application.
  /// [currentTags]: A list of tags already applied to the note.
  ///
  /// Returns a list of suggested tags, sorted by relevance.
  static List<Tag> getSuggestions({
    required DocumentModel document,
    required List<Tag> allTags,
    required List<Tag> currentTags,
  }) {
    final plainText = document.toPlainText().toLowerCase();
    if (plainText.isEmpty) {
      return [];
    }

    final currentTagIds = currentTags.map((t) => t.id).toSet();
    final suggestions = <Tag, int>{};

    for (final tag in allTags) {
      if (currentTagIds.contains(tag.id)) {
        continue; // Skip tags already added
      }

      final tagName = tag.name.toLowerCase();
      if (tagName.isEmpty) {
        continue;
      }

      final count = _countOccurrences(plainText, tagName);
      if (count > 0) {
        suggestions[tag] = count;
      }
    }

    // Sort suggestions by count in descending order
    final sortedSuggestions = suggestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return just the tags
    return sortedSuggestions.map((e) => e.key).toList();
  }

  /// Counts the number of times a word appears in a text.
  static int _countOccurrences(String text, String word) {
    // Use a simple regex to find whole words only
    final regex = RegExp('\\b$word\\b', caseSensitive: false);
    return regex.allMatches(text).length;
  }
}
