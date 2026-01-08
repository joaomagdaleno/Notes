import 'package:flutter/material.dart';
import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/editor/document_manipulator.dart';
import 'package:notes_hub/models/snippet.dart';
import 'package:notes_hub/repositories/note_repository.dart';

/// The result of a successful snippet conversion.
class SnippetConversionResult {
  /// Creates a new instance of [SnippetConversionResult].
  const SnippetConversionResult({
    required this.document,
    required this.selection,
    required this.results,
  });

  /// The new document after conversion.
  final DocumentModel document;

  /// The new selection after conversion.
  final TextSelection selection;

  /// The manipulation results that led to this state.
  final List<ManipulationResult> results;
}

/// A class to handle real-time snippet conversions.
class SnippetConverter {
  static List<Snippet>? _cachedSnippets;

  /// Loads or reloads the snippets from the database into the cache.
  static Future<void> precacheSnippets() async {
    _cachedSnippets = await NoteRepository.instance.getAllSnippets();
  }

  /// Checks the text before the cursor for a snippet trigger and applies it.
  static SnippetConversionResult? checkAndApply(
    DocumentModel document,
    TextSelection selection,
  ) {
    if (_cachedSnippets == null || !selection.isCollapsed) return null;

    final plainText = document.toPlainText();
    final textBeforeCursor = plainText.substring(0, selection.baseOffset);

    // This is triggered by a space.
    if (!textBeforeCursor.endsWith(' ')) return null;

    for (final snippet in _cachedSnippets!) {
      if (textBeforeCursor.endsWith('${snippet.trigger} ')) {
        final triggerLength = snippet.trigger.length;
        final startOfTrigger = selection.baseOffset - 1 - triggerLength;

        // Perform the conversion
        final deleteResult = DocumentManipulator.deleteText(
          document,
          startOfTrigger,
          triggerLength + 1, // +1 for the space
        );
        final docAfterDelete = deleteResult.document;

        final insertResult = DocumentManipulator.insertText(
          docAfterDelete,
          startOfTrigger,
          snippet.content,
        );
        final docAfterInsert = insertResult.document;

        final newSelection = TextSelection.collapsed(
          offset: startOfTrigger + snippet.content.length,
        );
        return SnippetConversionResult(
          document: docAfterInsert,
          selection: newSelection,
          results: [deleteResult, insertResult],
        );
      }
    }

    return null;
  }
}
