import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';

/// A base class for a line in the virtualized editor.
@immutable
abstract class Line {
  /// Creates a [Line] with optional [attributes].
  const Line({this.attributes = const {}});

  /// The attributes associated with this line (from the block).
  final Map<String, dynamic> attributes;
}

/// Represents a single line of text.
class TextLine extends Line {
  /// Creates a new instance of [TextLine].
  const TextLine({required this.spans, super.attributes});

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

/// Represents a line within a callout block.
class CalloutLine extends TextLine {
  /// Creates a new instance of [CalloutLine].
  const CalloutLine({
    required this.type,
    required this.isFirst,
    required this.isLast,
    required super.spans,
    super.attributes,
  });

  /// The type of callout.
  final CalloutType type;

  /// Whether this is the first line of the callout (should show header/icon).
  final bool isFirst;

  /// Whether this is the last line of the callout.
  final bool isLast;
}

/// Represents a line containing an image.
class ImageLine extends Line {
  /// Creates a new instance of [ImageLine].
  const ImageLine({required this.imagePath, super.attributes});

  /// The path to the image file.
  final String imagePath;
}

/// Represents a line containing a table.
class TableLine extends Line {
  /// Creates a new instance of [TableLine].
  const TableLine({
    required this.rows,
    super.attributes,
  });

  /// The rows of the table.
  final List<List<TableCellModel>> rows;
}

/// Represents a line containing a math equation.
class MathLine extends Line {
  /// Creates a new instance of [MathLine].
  const MathLine({
    required this.tex,
    super.attributes,
  });

  /// The LaTeX equation.
  final String tex;
}

/// Represents a line containing a transclusion.
class TransclusionLine extends Line {
  /// Creates a new instance of [TransclusionLine].
  const TransclusionLine({
    required this.noteTitle,
    super.attributes,
  });

  /// The title of the note.
  final String noteTitle;
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
    final currentLineSpans = <TextSpanModel>[];

    for (final block in document.blocks) {
      if (block is ImageBlock) {
        // If there's pending text, finish that line first.
        if (currentLineSpans.isNotEmpty) {
          // IMPORTANT: Previous block's attributes are lost if better logic
          // isn't applied. Since blocks usually separate content, this case
          // (pending text from previous block) implies a TextBlock was
          // followed by an ImageBlock. The pending text belongs to the
          // PREVIOUS TextBlock.
          // But here we are iterating blocks.
          // The variable `currentLineSpans` accumulates spans from `TextBlock`.
          // When we hit `ImageBlock`, we flush.
          // We need to know the attributes of the block `currentLineSpans`
          // came from.
          // Since `currentLineSpans` is greedy across blocks only if we merged
          // them (which we don't, we iterate blocks), we should actually flush
          // inside the TextBlock loop or track the current attributes.
          // Wait, the original logic accumulated lines within a TextBlock.
          // Ah, actually the original logic reset `currentLineSpans` inside
          // `TextBlock` loop on newlines. But if a `TextBlock` didn't end
          // with newline, it kept `currentLineSpans` and continued to next
          // block?
          // DocumentModel usually has distinct blocks.
          // Let's refine: Use the attributes of the *current* block.
        }
        // Actually, let's look at the TextBlock handling.
      }
    }

    // Correct re-implementation of loop
    lines.clear();

    for (final block in document.blocks) {
      if (block is ImageBlock) {
        lines.add(
          ImageLine(
            imagePath: block.imagePath,
            attributes: block.attributes,
          ),
        );
      } else if (block is DrawingBlock) {
        // NoteEditor handles drawings via EditorWidget custom logic?
        // Actually DocumentModel has DrawingBlock but VirtualTextBuffer
        // didn't handle it. Assuming EditorWidget renders drawings
        // separately or we add DrawingLine later. For consistency with
        // existing code (which had ImageBlock), I'll ignore Drawing here
        // or add a dummy if needed. The model has it.
        // Existing code: Lines 107 in original view ONLY handled ImageBlock
        // and TextBlock.
      } else if (block is TextBlock) {
        var currentBlockSpans = <TextSpanModel>[];
        // We process spans. On newline, we emit a line WITH this block's
        // attributes.
        for (final span in block.spans) {
          final text = span.text;
          var start = 0;
          int end;

          while ((end = text.indexOf('\n', start)) != -1) {
            final lineText = text.substring(start, end);
            if (lineText.isNotEmpty) {
              currentBlockSpans.add(span.copyWith(text: lineText));
            }
            // Flush line
            lines.add(
              TextLine(
                spans: currentBlockSpans,
                attributes: block.attributes,
              ),
            );
            currentBlockSpans = [];
            start = end + 1;
          }

          if (start < text.length) {
            currentBlockSpans.add(span.copyWith(text: text.substring(start)));
          }
        }
        // If there is leftover text in this block (no trailing newline),
        // we emit it as a line. (Assuming blocks are paragraph-like
        // boundaries). If we want to support inline blocks merging, we'd
        // need more complex logic.
        // For Markdown, blocks are usually distinct paragraphs/elements.
        if (currentBlockSpans.isNotEmpty) {
          lines.add(
            TextLine(
              spans: currentBlockSpans,
              attributes: block.attributes,
            ),
          );
        }
      } else if (block is CalloutBlock) {
        // Similar to TextBlock but produces CalloutLines
        final allLinesSpans = <List<TextSpanModel>>[];
        var currentBlockSpans = <TextSpanModel>[];

        for (final span in block.spans) {
          final text = span.text;
          var start = 0;
          int end;

          while ((end = text.indexOf('\n', start)) != -1) {
            final lineText = text.substring(start, end);
            if (lineText.isNotEmpty) {
              currentBlockSpans.add(span.copyWith(text: lineText));
            }
            allLinesSpans.add(currentBlockSpans);
            currentBlockSpans = [];
            start = end + 1;
          }

          if (start < text.length) {
            currentBlockSpans.add(span.copyWith(text: text.substring(start)));
          }
        }
        if (currentBlockSpans.isNotEmpty) {
          allLinesSpans.add(currentBlockSpans);
        }

        // Now create lines with isFirst/isLast
        for (var i = 0; i < allLinesSpans.length; i++) {
          lines.add(
            CalloutLine(
              type: block.type,
              isFirst: i == 0,
              isLast: i == allLinesSpans.length - 1,
              spans: allLinesSpans[i],
              attributes: block.attributes,
            ),
          );
        }
      } else if (block is TableBlock) {
        // TableBlock becomes a single TableLine
        lines.add(
          TableLine(
            rows: block.rows,
            attributes: block.attributes,
          ),
        );
      } else if (block is MathBlock) {
        lines.add(
          MathLine(
            tex: block.tex,
            attributes: block.attributes,
          ),
        );
      } else if (block is TransclusionBlock) {
        lines.add(
          TransclusionLine(
            noteTitle: block.noteTitle,
            attributes: block.attributes,
          ),
        );
      }
    }

    // Now, calculate lengths consistently.
    _lineLengths.clear();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line is TextLine) {
        final length = line.spans.fold<int>(0, (sum, s) => sum + s.text.length);
        _lineLengths.add(i == lines.length - 1 ? length : length + 1);
      } else if (line is TableLine) {
        _lineLengths.add(1); // Table is 1 unit length
      } else if (line is MathLine) {
        _lineLengths.add(1); // Math is 1 unit length
      } else if (line is TransclusionLine) {
        _lineLengths.add(1); // Transclusion is 1 unit length
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
    if (lines.isEmpty) return const LineTextPosition(line: 0, character: 0);
    return LineTextPosition(
      line: lines.length - 1,
      character: (lines.last is TextLine)
          ? (lines.last as TextLine).toPlainText().length
          : 0,
    );
  }

  /// Converts a local line and character index into a global character offset.
  int getOffsetForLineTextPosition(LineTextPosition position) {
    var offset = 0;
    for (var i = 0; i < position.line; i++) {
      if (i < _lineLengths.length) offset += _lineLengths[i];
    }
    return offset + position.character;
  }
}
