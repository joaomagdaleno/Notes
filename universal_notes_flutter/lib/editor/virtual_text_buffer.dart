import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';

/// A base class for a line in the virtualized editor.
@immutable
abstract class Line {}

/// Represents a single line of text.
class TextLine extends Line {
  /// Creates a new instance of [TextLine].
  TextLine({required this.spans});

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

/// Represents a line containing an image.
class ImageLine extends Line {
  /// Creates a new instance of [ImageLine].
  ImageLine({required this.imagePath});

  /// The path to the image file.
  final String imagePath;
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

  /// The list of lines generated from the document.
  final List<Line> lines = [];
  final List<int> _lineLengths = [];

  void _buildLines() {
    lines.clear();
    var currentLineSpans = <TextSpanModel>[];

    for (final block in document.blocks) {
      if (block is ImageBlock) {
        // If there's pending text, finish that line first.
        if (currentLineSpans.isNotEmpty) {
          lines.add(TextLine(spans: currentLineSpans));
          currentLineSpans = [];
        }
        lines.add(ImageLine(imagePath: block.imagePath));
      } else if (block is TextBlock) {
        for (final span in block.spans) {
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
      }
    }
    // Add the last line of text if any.
    if (currentLineSpans.isNotEmpty) {
      lines.add(TextLine(spans: currentLineSpans));
    }

    // Now, calculate lengths consistently.
    _lineLengths.clear();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line is TextLine) {
        final length = line.spans.fold<int>(0, (sum, s) => sum + s.text.length);
        _lineLengths.add(i == lines.length - 1 ? length : length + 1);
      } else {
        _lineLengths.add(1); // Treat images as a single character offset.
      }
    }
  }

  /// Converts a global character offset into a local line and character index.
  LineTextPosition getLineTextPositionForOffset(int offset) {
    var currentOffset = 0;
    for (var i = 0; i < lines.length; i++) {
      final lineLength = _lineLengths[i];
      if (offset < currentOffset + lineLength) {
        return LineTextPosition(line: i, character: offset - currentOffset);
      }
      currentOffset += lineLength;
    }
    // Default to the end of the last line if offset is out of bounds.
    return LineTextPosition(
      line: lines.length - 1,
      character: (lines.last as TextLine).toPlainText().length,
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
