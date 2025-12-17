import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';

/// The result of a successful Markdown conversion.
class MarkdownConversionResult {
  /// Creates a new instance of [MarkdownConversionResult].
  const MarkdownConversionResult({
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

/// A class to handle real-time Markdown-like conversions.
class MarkdownConverter {
  // Patterns that apply to text anywhere, like *bold*.
  // The regex now looks for a closing symbol followed by a space or end of
  // line.
  static final Map<RegExp, StyleAttribute> _inlinePatterns = {
    RegExp(r'\*([^\*]+)\*(?=\s|$)'): StyleAttribute.bold,
    RegExp(r'_([^_]+)_(?=\s|$)'): StyleAttribute.italic,
    RegExp(r'-([^-]+)-(?=\s|$)'): StyleAttribute.strikethrough,
  };

  /// Checks the text around the cursor for Markdown patterns and applies them.
  /// Returns a [MarkdownConversionResult] if a conversion happened, otherwise
  /// null.
  static MarkdownConversionResult? checkAndApply(
    DocumentModel document,
    TextSelection selection,
  ) {
    if (!selection.isCollapsed) return null;

    final plainText = document.toPlainText();
    if (plainText.isEmpty) return null;

    var lineStart = selection.baseOffset;
    while (lineStart > 0 && plainText[lineStart - 1] != '\n') {
      lineStart--;
    }
    final lineText = plainText.substring(lineStart, selection.baseOffset);

    // --- Check for inline patterns (bold, italic, etc.) ---
    for (final entry in _inlinePatterns.entries) {
      // We check the whole line for a pattern that has just been completed.
      final match = entry.key.firstMatch(lineText);
      if (match != null) {
        final content = match.group(1)!;
        final matchStart = lineStart + match.start;

        final deleteResult = DocumentManipulator.deleteText(
          document,
          matchStart,
          match.group(0)!.length,
        );
        var newDoc = deleteResult.document;

        final insertResult = DocumentManipulator.insertText(
          newDoc,
          matchStart,
          content,
        );
        newDoc = insertResult.document;

        final newSelection = TextSelection(
          baseOffset: matchStart,
          extentOffset: matchStart + content.length,
        );
        final formatResult = DocumentManipulator.toggleStyle(
          newDoc,
          newSelection,
          entry.value,
        );
        newDoc = formatResult.document;

        final finalSelection = TextSelection.collapsed(
          offset: newSelection.end,
        );
        return MarkdownConversionResult(
          document: newDoc,
          selection: finalSelection,
          results: [deleteResult, insertResult, formatResult],
        );
      }
    }

    // --- Check for block patterns (headings and lists) ---
    // These should only trigger if the user types the space.
    if (lineText.endsWith(' ')) {
      final pattern = lineText.trim();
      if (pattern == '#') {
        final lineEnd = plainText.indexOf('\n', lineStart);
        final finalLineEnd = lineEnd == -1 ? plainText.length : lineEnd;

        // Delete the "# " part
        // Delete the "# " part
        final deleteResult = DocumentManipulator.deleteText(
          document,
          lineStart,
          2,
        );
        var newDoc = deleteResult.document;
        // Apply the font size to the rest of the line
        // The text moved to lineStart, so baseOffset is lineStart.
        // The length decreased by 2, so extentOffset is original extent - 2.
        final formatResult = DocumentManipulator.applyFontSize(
          newDoc,
          TextSelection(baseOffset: lineStart, extentOffset: finalLineEnd - 2),
          32,
        );
        newDoc = formatResult.document;

        final finalSelection = TextSelection.collapsed(
          offset: selection.baseOffset - 2,
        );
        return MarkdownConversionResult(
          document: newDoc,
          selection: finalSelection,
          results: [deleteResult, formatResult],
        );
      }

      if (pattern == '-') {
        const listText = '• ';
        final deleteResult = DocumentManipulator.deleteText(
          document,
          lineStart,
          2,
        );
        var newDoc = deleteResult.document;
        final insertResult = DocumentManipulator.insertText(
          newDoc,
          lineStart,
          listText,
        );
        newDoc = insertResult.document;

        final finalSelection = TextSelection.collapsed(
          offset: lineStart + listText.length,
        );
        return MarkdownConversionResult(
          document: newDoc,
          selection: finalSelection,
          results: [deleteResult, insertResult],
        );
      }
    }

    return null;
  }
}
