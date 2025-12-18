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
  // Patterns for inline styles
  static final Map<RegExp, TextSpanModel Function(TextSpanModel)>
  _inlineModifiers = {
    RegExp(r'\*([^\*]+)\*(?=\s|$)'): (s) => s.copyWith(isBold: !s.isBold),
    RegExp(r'_([^_]+)_(?=\s|$)'): (s) => s.copyWith(isItalic: !s.isItalic),
    RegExp(r'~([^~]+)~(?=\s|$)'): (s) =>
        s.copyWith(isStrikethrough: !s.isStrikethrough),
    RegExp(r'`([^`]+)`(?=\s|$)'): (s) =>
        s.copyWith(isCode: true, fontFamily: 'monospace'),
  };

  /// Checks the text around the cursor for Markdown patterns and applies them.
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

    // --- Block Patterns (triggered by space) ---
    if (lineText.endsWith(' ')) {
      final pattern = lineText.trim();

      // Headings (#, ##, ###)
      if (RegExp(r'^#{1,6}$').hasMatch(pattern)) {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          pattern.length + 1, // length of '# ' is pattern.length + 1 for space
          // logic below handles deletion
          {'blockType': 'heading', 'level': pattern.length},
        );
      }

      // Blockquote (>)
      if (pattern == '>') {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          2, // "> "
          {'blockType': 'quote'},
        );
      }

      // Unordered List (-)
      if (pattern == '-') {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          2,
          {'blockType': 'unordered-list'},
        );
      }

      // Ordered List (1., 2., 3., etc.)
      if (RegExp(r'^\d+\.$').hasMatch(pattern)) {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          pattern.length + 1, // "1. " including space
          {'blockType': 'ordered-list'},
        );
      }

      // Unchecked Checklist (- [ ])
      if (lineText.trimLeft().startsWith('- [ ] ')) {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          6, // "- [ ] "
          {'blockType': 'checklist', 'checked': false},
        );
      }

      // Checked Checklist (- [x])
      if (lineText.trimLeft().startsWith('- [x] ')) {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          6, // "- [x] "
          {'blockType': 'checklist', 'checked': true},
        );
      }

      // Code Block (```)
      if (pattern == '```') {
        return _applyBlockAttribute(
          document,
          lineStart,
          selection,
          4, // "``` "
          {'blockType': 'code-block'},
        );
      }
    }

    // --- Inline Patterns ---
    // Check for Links [text](url) -> Triggered by closing paren )
    if (selection.baseOffset > 0 &&
        plainText[selection.baseOffset - 1] == ')') {
      final linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)$');
      final match = linkRegex.firstMatch(lineText);
      if (match != null) {
        final text = match.group(1)!;
        final url = match.group(2)!;
        final matchStart = lineStart + match.start;
        final fullMatch = match.group(0)!;

        // Delete full match
        final deleteResult = DocumentManipulator.deleteText(
          document,
          matchStart,
          fullMatch.length,
        );
        var newDoc = deleteResult.document;

        // Insert just the text
        final insertResult = DocumentManipulator.insertText(
          newDoc,
          matchStart,
          text,
        );
        newDoc = insertResult.document;

        // Apply Link Style
        final newSelection = TextSelection(
          baseOffset: matchStart,
          extentOffset: matchStart + text.length,
        );

        // We need a helper to apply custom span updates (linkUrl)
        newDoc = DocumentManipulator.applyToSelection(
          newDoc,
          newSelection,
          (s) =>
              s.copyWith(linkUrl: url, color: Colors.blue, isUnderline: true),
        );

        final finalSelection = TextSelection.collapsed(
          offset: newSelection.end,
        );
        return MarkdownConversionResult(
          document: newDoc,
          selection: finalSelection,
          results: [deleteResult, insertResult], // Simplified list
        );
      }
    }

    // Standard Inline Styles
    for (final entry in _inlineModifiers.entries) {
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

        // Apply specific modifier
        newDoc = DocumentManipulator.applyToSelection(
          newDoc,
          newSelection,
          entry.value,
        );

        final finalSelection = TextSelection.collapsed(
          offset: newSelection.end,
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

  static MarkdownConversionResult _applyBlockAttribute(
    DocumentModel document,
    int lineStart,
    TextSelection selection,
    int lengthToDelete,
    Map<String, dynamic> attributes, {
    String replacementText = '',
  }) {
    final deleteResult = DocumentManipulator.deleteText(
      document,
      lineStart,
      lengthToDelete,
    );
    var newDoc = deleteResult.document;

    if (replacementText.isNotEmpty) {
      final insertResult = DocumentManipulator.insertText(
        newDoc,
        lineStart,
        replacementText,
      );
      newDoc = insertResult.document;
    }

    final attrResult = DocumentManipulator.setBlockAttributes(
      newDoc,
      lineStart,
      attributes,
    );
    newDoc = attrResult.document;

    final finalSelection = TextSelection.collapsed(
      offset: lineStart + replacementText.length,
    );

    return MarkdownConversionResult(
      document: newDoc,
      selection: finalSelection,
      results: [deleteResult, attrResult],
    );
  }
}
