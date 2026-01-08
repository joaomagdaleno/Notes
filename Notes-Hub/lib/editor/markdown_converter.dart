import 'package:flutter/material.dart';
import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/editor/document_manipulator.dart';

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

      // Callouts (> [!TYPE])
      final calloutMatch = RegExp(r'^> \[!(\w+)\]$').firstMatch(pattern);
      if (calloutMatch != null) {
        final typeStr = calloutMatch.group(1)!.toLowerCase();
        try {
          final type = CalloutType.values.firstWhere(
            (e) => e.name == typeStr,
          );
          return _applyCallout(
            document,
            lineStart,
            selection,
            pattern.length + 1, // "> [!NOTE] "
            type,
          );
        } on Exception catch (_) {
          // ignore errors or invalid callout types
        }
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

    // --- Table Detection (Multi-line) ---
    // Triggered when user types '|' or Enter?
    // Actually typically on Enter after the separator line |---|---|
    // Or just generic check.
    if (lineText.trim().startsWith('|')) {
      final tableResult = _tryConvertTable(document, lineStart);
      if (tableResult != null) return tableResult;
    }

    // --- Math Block Detection ($$ tex $$) ---
    if (lineText.trim().startsWith(r'$$') &&
        lineText.trim().endsWith(r'$$') &&
        lineText.trim().length > 4) {
      final tex = lineText
          .trim()
          .substring(2, lineText.trim().length - 2)
          .trim();
      if (tex.isNotEmpty) {
        return _applyMathBlock(document, lineStart, tex);
      }
    }

    // --- Transclusion Detection (![[note]]) ---
    if (lineText.trim().startsWith('![[') &&
        lineText.trim().endsWith(']]') &&
        lineText.trim().length > 5) {
      final title = lineText
          .trim()
          .substring(3, lineText.trim().length - 2)
          .trim();
      if (title.isNotEmpty) {
        return _applyTransclusion(document, lineStart, title);
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

  static MarkdownConversionResult _applyCallout(
    DocumentModel document,
    int lineStart,
    TextSelection selection,
    int lengthToDelete,
    CalloutType type,
  ) {
    final deleteResult = DocumentManipulator.deleteText(
      document,
      lineStart,
      lengthToDelete,
    );
    var newDoc = deleteResult.document;

    final convertResult = DocumentManipulator.convertBlockToCallout(
      newDoc,
      lineStart,
      type,
    );
    newDoc = convertResult.document;

    final finalSelection = TextSelection.collapsed(
      offset: lineStart,
    );

    return MarkdownConversionResult(
      document: newDoc,
      selection: finalSelection,
      results: [deleteResult, convertResult],
    );
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

  static MarkdownConversionResult? _tryConvertTable(
    DocumentModel document,
    int currentLineStart,
  ) {
    // Check previous lines for table structure.
    // Minimum:
    // Header | Header
    // --- | ---
    // (Current line might be empty or start of next row)

    // We need random access to lines.
    // This is expensive with current API (toPlainText).
    // But typically we only need to look back 1 line (separator).
    // If current line IS the separator (users typed |---|), we convert then.
    // Let's assume user types:
    // | A | B |
    // |---|---| <ENTER> -> Trigger

    final text = document.toPlainText();
    final currentLineEnd = text.indexOf('\n', currentLineStart);
    final effectiveEnd = currentLineEnd == -1 ? text.length : currentLineEnd;
    final currentLineText = text
        .substring(currentLineStart, effectiveEnd)
        .trim();

    // Regex for separator line: ^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$
    final separatorRegex = RegExp(r'^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$');

    if (separatorRegex.hasMatch(currentLineText)) {
      // This looks like a separator line.
      // Check previous line for Header.
      if (currentLineStart == 0) return null;

      var prevLineEnd = currentLineStart - 1; // Skip the newline before current
      if (text[prevLineEnd] == '\n') prevLineEnd--; // Should be \n

      var prevLineStart = text.lastIndexOf('\n', prevLineEnd);
      if (prevLineStart == -1) {
        prevLineStart = 0;
      } else {
        prevLineStart++; // Skip the newline
      }

      if (prevLineStart >= currentLineStart) return null; // Logic check

      final prevLineText = text
          .substring(prevLineStart, currentLineStart - 1 /* \n */)
          .trim();
      if (prevLineText.isEmpty) return null;

      // Header row must have pipes or at least match column count?
      // Simple check: if separator has pipes, header should probably too
      // or at least be non-empty.

      // Parse columns
      final separatorCols = currentLineText
          .split('|')
          .where((s) => s.trim().isNotEmpty)
          .length;
      final headerCols = prevLineText
          .split('|')
          .where((s) => s.trim().isNotEmpty)
          .length;

      if (separatorCols > 0 && headerCols > 0) {
        // Rough match
        // Convert!
        // We consume both lines and create a TableBlock.
        // Header Row
        final headerCells = prevLineText
            .split('|')
            .where((s) => s.trim().isNotEmpty) // Simple split, naive
            .map(
              (s) => TableCellModel(
                content: [TextSpanModel(text: s.trim())],
                isHeader: true,
              ),
            )
            .toList();

        final rows = [headerCells];

        final lengthToDelete = effectiveEnd - prevLineStart;

        final deleteResult = DocumentManipulator.deleteText(
          document,
          prevLineStart,
          lengthToDelete,
        );
        var newDoc = deleteResult.document;

        // Convert the now empty/placeholder block to TableBlock
        final convertResult = DocumentManipulator.convertBlockToTable(
          newDoc,
          prevLineStart,
          rows,
        );
        newDoc = convertResult.document;

        final finalSelection = TextSelection.collapsed(
          offset: prevLineStart, // Cursor at start of table? Or after?
          // TableBlock is 1 unit length in buffer usually.
          // But here we might want to be after it.
        );
        // Ideally we want to be *after* the table or inside first cell?
        // For now, cursor at start.

        return MarkdownConversionResult(
          document: newDoc,
          selection: finalSelection,
          results: [deleteResult, convertResult],
        );
      }
    }
    return null;
  }

  static MarkdownConversionResult _applyMathBlock(
    DocumentModel document,
    int lineStart,
    String tex,
  ) {
    final convertResult = DocumentManipulator.convertBlockToMath(
      document,
      lineStart,
      tex,
    );
    final newDoc = convertResult.document;

    final finalSelection = TextSelection.collapsed(
      offset: lineStart + tex.length + 4, // $$tex$$
    );

    return MarkdownConversionResult(
      document: newDoc,
      selection: finalSelection,
      results: [convertResult],
    );
  }

  static MarkdownConversionResult _applyTransclusion(
    DocumentModel document,
    int lineStart,
    String title,
  ) {
    final convertResult = DocumentManipulator.convertBlockToTransclusion(
      document,
      lineStart,
      title,
    );
    final newDoc = convertResult.document;

    final finalSelection = TextSelection.collapsed(
      offset: lineStart + title.length + 5, // ![[title]]
    );

    return MarkdownConversionResult(
      document: newDoc,
      selection: finalSelection,
      results: [convertResult],
    );
  }
}
