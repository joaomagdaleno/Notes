import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';

/// Represents a single line of text in the virtualized editor,
/// potentially containing multiple styles.
@immutable
class TextLine {
  /// Creates a new instance of [TextLine].
  const TextLine({required this.spans});

  /// The list of styled text spans that make up this line.
  final List<TextSpanModel> spans;

  /// Converts this line to a Flutter [TextSpan] for rendering.
  TextSpan toTextSpan() {
    return TextSpan(
      children: spans.map((s) => s.toTextSpan()).toList(),
    );
  }

  /// Gets the plain text of the line.
  String toPlainText() {
    return spans.map((s) => s.text).join();
  }
}

/// Represents a position within the virtualized text buffer as a line and
/// character index.
class LineTextPosition {
  /// Creates a new instance of [LineTextPosition].
  const LineTextPosition({required this.line, required this.character});

  /// The index of the line.
  final int line;

  /// The index of the character within the line.
  final int character;
}

/// Manages the collection of text lines derived from a [DocumentModel].
class VirtualTextBuffer {
  /// Creates a new instance of [VirtualTextBuffer] and processes the document.
  VirtualTextBuffer(this.document) {
    _buildLines();
  }

  /// The source document.
  final DocumentModel document;

  /// The list of text lines generated from the document.
  final List<TextLine> lines = [];
  final List<int> _lineLengths = [];

  void _buildLines() {
    lines.clear();
    var currentLineSpans = <TextSpanModel>[];

    for (final span in document.spans) {
      final text = span.text;
      var start = 0;
      int end;

      while ((end = text.indexOf('\n', start)) != -1) {
        final lineText = text.substring(start, end);
        if (lineText.isNotEmpty) {
          currentLineSpans.add(span.copyWith(text: lineText));
        }
        lines.add(TextLine(spans: currentLineSpans));
        currentLineSpans = [];
        start = end + 1;
      }

      if (start < text.length) {
        currentLineSpans.add(span.copyWith(text: text.substring(start)));
      }
    }
    lines.add(TextLine(spans: currentLineSpans));

    // Now, calculate lengths consistently.
    _lineLengths.clear();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final length = line.spans.fold<int>(0, (sum, s) => sum + s.text.length);
      // Add 1 for the newline character, except for the last line.
      _lineLengths.add(i == lines.length - 1 ? length : length + 1);
    }
  }

  /// Converts a global character offset into a local line and character index.
  LineTextPosition getLineTextPositionForOffset(int offset) {
    var currentOffset = 0;
    for (var i = 0; i < lines.length; i++) {
      final lineLength = _lineLengths[i];
      if (offset <= currentOffset + lineLength) {
        return LineTextPosition(line: i, character: offset - currentOffset);
      }
      currentOffset += lineLength;
    }
    // Default to the end of the last line if offset is out of bounds.
    return LineTextPosition(
      line: lines.length - 1,
      character: lines.last.toPlainText().length,
    );
  }

  /// Converts a local line and character index into a global character offset.
  int getOffsetForLineTextPosition(LineTextPosition position) {
    var offset = 0;
    for (var i = 0; i < position.line; i++) {
      offset += _lineLengths[i];
    }
    return offset + position.character;
  }
}
