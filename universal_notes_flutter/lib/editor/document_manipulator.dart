import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';

/// An attribute that can be applied to a text span.
enum StyleAttribute {
  /// Bold style.
  bold,
  /// Italic style.
  italic,
  /// Underline style.
  underline,
  /// Strikethrough style.
  strikethrough,
}

/// A class containing static methods to manipulate a [DocumentModel].
class DocumentManipulator {
  /// Toggles a style for the given selection.
  static DocumentModel toggleStyle(
    DocumentModel document,
    TextSelection selection,
    StyleAttribute attribute,
  ) {
    if (selection.isCollapsed) return document;

    final spans = document.spans;
    final selectionStart = selection.start;
    final selectionEnd = selection.end;

    final newSpans = <TextSpanModel>[];
    int currentPos = 0;

    for (final span in spans) {
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;
      currentPos = spanEnd;

      if (spanEnd <= selectionStart || spanStart >= selectionEnd) {
        newSpans.add(span);
        continue;
      }

      final beforeText = selectionStart > spanStart
          ? span.text.substring(0, selectionStart - spanStart)
          : '';

      final selectedTextStart = selectionStart > spanStart ? selectionStart - spanStart : 0;
      final selectedTextEnd = selectionEnd < spanEnd ? selectionEnd - spanStart : span.text.length;
      final selectedText = span.text.substring(selectedTextStart, selectedTextEnd);

      final afterText = selectionEnd < spanEnd
          ? span.text.substring(selectionEnd - spanStart)
          : '';

      if (beforeText.isNotEmpty) {
        newSpans.add(span.copyWith(text: beforeText));
      }

      if (selectedText.isNotEmpty) {
        newSpans.add(span.copyWith(
          text: selectedText,
          isBold: attribute == StyleAttribute.bold ? !span.isBold : span.isBold,
          isItalic: attribute == StyleAttribute.italic ? !span.isItalic : span.isItalic,
          isUnderline: attribute == StyleAttribute.underline ? !span.isUnderline : span.isUnderline,
          isStrikethrough: attribute == StyleAttribute.strikethrough ? !span.isStrikethrough : span.isStrikethrough,
        ));
      }

      if (afterText.isNotEmpty) {
        newSpans.add(span.copyWith(text: afterText));
      }
    }

    return DocumentModel(spans: _mergeSpans(newSpans));
  }

  /// Applies a color to the given selection.
  static DocumentModel applyColor(DocumentModel document, TextSelection selection, Color color) {
    return _applyStyleValue(document, selection, (span) => span.copyWith(color: color));
  }

  /// Applies a font size to the given selection.
  static DocumentModel applyFontSize(DocumentModel document, TextSelection selection, double fontSize) {
     return _applyStyleValue(document, selection, (span) => span.copyWith(fontSize: fontSize));
  }

  /// Generic function to apply a style value to the selection.
  static DocumentModel _applyStyleValue(DocumentModel document, TextSelection selection, TextSpanModel Function(TextSpanModel) updateFunc) {
     if (selection.isCollapsed) return document;

    final spans = document.spans;
    final selectionStart = selection.start;
    final selectionEnd = selection.end;

    final newSpans = <TextSpanModel>[];
    int currentPos = 0;

    for (final span in spans) {
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;
      currentPos = spanEnd;

      if (spanEnd <= selectionStart || spanStart >= selectionEnd) {
        newSpans.add(span);
        continue;
      }

      final beforeText = selectionStart > spanStart
          ? span.text.substring(0, selectionStart - spanStart)
          : '';

      final selectedTextStart = selectionStart > spanStart ? selectionStart - spanStart : 0;
      final selectedTextEnd = selectionEnd < spanEnd ? selectionEnd - spanStart : span.text.length;
      final selectedText = span.text.substring(selectedTextStart, selectedTextEnd);

      final afterText = selectionEnd < spanEnd
          ? span.text.substring(selectionEnd - spanStart)
          : '';

      if (beforeText.isNotEmpty) {
        newSpans.add(span.copyWith(text: beforeText));
      }

      if (selectedText.isNotEmpty) {
        newSpans.add(updateFunc(span.copyWith(text: selectedText)));
      }

      if (afterText.isNotEmpty) {
        newSpans.add(span.copyWith(text: afterText));
      }
    }

    return DocumentModel(spans: _mergeSpans(newSpans));
  }

  // --- Insert and Delete methods remain the same ---
  static DocumentModel insertText(
    DocumentModel document,
    int position,
    String text,
  ) {
    final spans = List<TextSpanModel>.from(document.spans);
    if (spans.isEmpty) {
      spans.add(TextSpanModel(text: text));
      return DocumentModel(spans: spans);
    }
    final pos = _findSpanPosition(spans, position);
    final targetSpan = spans[pos.spanIndex];
    final newText = targetSpan.text.substring(0, pos.localOffset) + text + targetSpan.text.substring(pos.localOffset);
    spans[pos.spanIndex] = targetSpan.copyWith(text: newText);
    return DocumentModel(spans: spans);
  }

  static DocumentModel deleteText(
    DocumentModel document,
    int start,
    int length,
  ) {
    if (length <= 0) return document;
    final end = start + length;
    final newSpans = <TextSpanModel>[];
    int currentPos = 0;
    for (final span in document.spans) {
      final spanStart = currentPos;
      final spanEnd = currentPos + span.text.length;
      currentPos = spanEnd;
      if (spanEnd <= start || spanStart >= end) {
        newSpans.add(span);
        continue;
      }
      final beforeText = start > spanStart ? span.text.substring(0, start - spanStart) : '';
      final afterText = end < spanEnd ? span.text.substring(end - spanStart) : '';
      if (beforeText.isNotEmpty) newSpans.add(span.copyWith(text: beforeText));
      if (afterText.isNotEmpty) newSpans.add(span.copyWith(text: afterText));
    }
    return DocumentModel(spans: _mergeSpans(newSpans));
  }

  static List<TextSpanModel> _mergeSpans(List<TextSpanModel> spans) {
    if (spans.isEmpty) return [];
    final mergedSpans = <TextSpanModel>[spans.first];
    for (int i = 1; i < spans.length; i++) {
      final last = mergedSpans.last;
      final current = spans[i];
      if (last.hasSameStyle(current) && last.text.isNotEmpty && current.text.isNotEmpty) {
        mergedSpans[mergedSpans.length - 1] = last.copyWith(text: last.text + current.text);
      } else if (current.text.isNotEmpty) {
        mergedSpans.add(current);
      }
    }
    return mergedSpans;
  }

  static _SpanPosition _findSpanPosition(
      List<TextSpanModel> spans, int globalPosition) {
    if (spans.isEmpty) return _SpanPosition(0, 0);
    int accumulatedLength = 0;
    for (int i = 0; i < spans.length; i++) {
      final span = spans[i];
      if (globalPosition <= accumulatedLength + span.text.length) {
        return _SpanPosition(i, globalPosition - accumulatedLength);
      }
      accumulatedLength += span.text.length;
    }
    return _SpanPosition(spans.length - 1, spans.last.text.length);
  }
}

class _SpanPosition {
  const _SpanPosition(this.spanIndex, this.localOffset);
  final int spanIndex;
  final int localOffset;
}
