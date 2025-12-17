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
  /// Inserts an image block at the specified position.
  static DocumentModel insertImage(
    DocumentModel document,
    int position,
    String imagePath,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      blocks.add(ImageBlock(imagePath: imagePath));
      return DocumentModel(blocks: blocks);
    }

    final targetBlock = blocks[pos.blockIndex];
    if (targetBlock is! TextBlock) {
      blocks.insert(pos.blockIndex, ImageBlock(imagePath: imagePath));
      return DocumentModel(blocks: blocks);
    }

    final beforeSpans = <TextSpanModel>[];
    final afterSpans = <TextSpanModel>[];
    var currentOffset = 0;
    var foundSplit = false;

    for (final span in targetBlock.spans) {
      if (foundSplit) {
        afterSpans.add(span);
        continue;
      }
      final spanEnd = currentOffset + span.text.length;
      if (pos.localOffset >= currentOffset && pos.localOffset <= spanEnd) {
        final splitIndex = pos.localOffset - currentOffset;
        final beforeText = span.text.substring(0, splitIndex);
        final afterText = span.text.substring(splitIndex);

        if (beforeText.isNotEmpty) {
          beforeSpans.add(span.copyWith(text: beforeText));
        }
        if (afterText.isNotEmpty) {
          afterSpans.add(span.copyWith(text: afterText));
        }
        foundSplit = true;
      } else {
        beforeSpans.add(span);
      }
      currentOffset += span.text.length;
    }

    blocks.removeAt(pos.blockIndex);
    final newBlocks = <DocumentBlock>[];
    if (beforeSpans.isNotEmpty) newBlocks.add(TextBlock(spans: beforeSpans));
    newBlocks.add(ImageBlock(imagePath: imagePath));
    if (afterSpans.isNotEmpty) newBlocks.add(TextBlock(spans: afterSpans));

    blocks.insertAll(pos.blockIndex, newBlocks);

    return DocumentModel(blocks: blocks);
  }

  /// Toggles a style for the given selection.
  static DocumentModel toggleStyle(
    DocumentModel document,
    TextSelection selection,
    StyleAttribute attribute,
  ) {
    return _applyToSelection(
      document,
      selection,
      (span) => span.copyWith(
        isBold: attribute == StyleAttribute.bold ? !span.isBold : span.isBold,
        isItalic: attribute == StyleAttribute.italic
            ? !span.isItalic
            : span.isItalic,
        isUnderline: attribute == StyleAttribute.underline
            ? !span.isUnderline
            : span.isUnderline,
        isStrikethrough: attribute == StyleAttribute.strikethrough
            ? !span.isStrikethrough
            : span.isStrikethrough,
      ),
    );
  }

  /// Applies a color to the given selection.
  static DocumentModel applyColor(
    DocumentModel document,
    TextSelection selection,
    Color color,
  ) {
    return _applyToSelection(
      document,
      selection,
      (span) => span.copyWith(color: color),
    );
  }

  /// Applies a font size to the given selection.
  static DocumentModel applyFontSize(
    DocumentModel document,
    TextSelection selection,
    double fontSize,
  ) {
    return _applyToSelection(
      document,
      selection,
      (span) => span.copyWith(fontSize: fontSize),
    );
  }

  static DocumentModel _applyToSelection(
    DocumentModel document,
    TextSelection selection,
    TextSpanModel Function(TextSpanModel) updateFunc,
  ) {
    if (selection.isCollapsed) return document;

    final newBlocks = <DocumentBlock>[];
    var currentPos = 0;

    for (final block in document.blocks) {
      if (block is! TextBlock) {
        newBlocks.add(block);
        currentPos += 1; // Placeholder for non-text block
        continue;
      }

      final blockLength = block.spans
          .map((s) => s.text.length)
          .fold(0, (a, b) => a + b);
      final blockEnd = currentPos + blockLength;

      if (blockEnd <= selection.start || currentPos >= selection.end) {
        newBlocks.add(block);
        currentPos = blockEnd;
        continue;
      }

      final newSpans = <TextSpanModel>[];
      for (final span in block.spans) {
        final spanEnd = currentPos + span.text.length;

        // No overlap
        if (spanEnd <= selection.start || currentPos >= selection.end) {
          newSpans.add(span);
        } else {
          // Overlap exists, split the span
          final beforeText = selection.start > currentPos
              ? span.text.substring(0, selection.start - currentPos)
              : '';
          final afterText = selection.end < spanEnd
              ? span.text.substring(selection.end - currentPos)
              : '';
          final selectedText = span.text.substring(
            selection.start > currentPos ? selection.start - currentPos : 0,
            selection.end < spanEnd
                ? selection.end - currentPos
                : span.text.length,
          );

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
        currentPos += span.text.length;
      }
      newBlocks.add(TextBlock(spans: _mergeSpans(newSpans)));
      currentPos = blockEnd; // Ensure currentPos is correct for next block
    }

    return DocumentModel(blocks: newBlocks);
  }

  /// Inserts text into the document at the specified position.
  static DocumentModel insertText(
    DocumentModel document,
    int position,
    String text,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1 || blocks[pos.blockIndex] is! TextBlock) {
      // Cannot insert text into an image block or at the end
      return document;
    }
    final targetBlock = blocks[pos.blockIndex] as TextBlock;
    final spans = List<TextSpanModel>.from(targetBlock.spans);

    final spanPos = _findSpanPosition(spans, pos.localOffset);
    final targetSpan = spans[spanPos.spanIndex];
    final newText =
        '${targetSpan.text.substring(0, spanPos.localOffset)}'
        '$text'
        '${targetSpan.text.substring(spanPos.localOffset)}';
    spans[spanPos.spanIndex] = targetSpan.copyWith(text: newText);
    blocks[pos.blockIndex] = TextBlock(spans: spans);
    return DocumentModel(blocks: blocks);
  }

  /// Deletes text from the document.
  static DocumentModel deleteText(
    DocumentModel document,
    int start,
    int length,
  ) {
    if (length <= 0) return document;

    final end = start + length;
    final newBlocks = <DocumentBlock>[];
    var currentPos = 0;

    for (final block in document.blocks) {
      int blockLength;
      if (block is TextBlock) {
        blockLength = block.spans
            .map((s) => s.text.length)
            .fold(0, (a, b) => a + b);
      } else {
        blockLength = 1;
      }
      final blockEnd = currentPos + blockLength;

      // If block is completely outside the deletion range, keep it.
      if (blockEnd <= start || currentPos >= end) {
        newBlocks.add(block);
      } else if (block is TextBlock) {
        final newSpans = <TextSpanModel>[];
        var spanStart = currentPos;
        for (final span in block.spans) {
          final spanEnd = spanStart + span.text.length;
          if (spanEnd > start && spanStart < end) {
            final beforeText = start > spanStart
                ? span.text.substring(0, start - spanStart)
                : '';
            final afterText = end < spanEnd
                ? span.text.substring(end - spanStart)
                : '';
            if (beforeText.isNotEmpty) {
              newSpans.add(span.copyWith(text: beforeText));
            }
            if (afterText.isNotEmpty) {
              newSpans.add(span.copyWith(text: afterText));
            }
          } else {
            newSpans.add(span);
          }
          spanStart = spanEnd;
        }
        if (newSpans.isNotEmpty) {
          newBlocks.add(TextBlock(spans: _mergeSpans(newSpans)));
        }
      }
      // If the block is an ImageBlock and is within the deletion range,
      // it is implicitly not added to newBlocks.
      currentPos = blockEnd;
    }
    return DocumentModel(blocks: newBlocks);
  }

  static List<TextSpanModel> _mergeSpans(List<TextSpanModel> spans) {
    if (spans.isEmpty) return [];
    final mergedSpans = <TextSpanModel>[];
    for (final span in spans) {
      if (span.text.isEmpty) continue;
      if (mergedSpans.isNotEmpty &&
          mergedSpans.last.isBold == span.isBold &&
          mergedSpans.last.isItalic == span.isItalic &&
          mergedSpans.last.isUnderline == span.isUnderline &&
          mergedSpans.last.isStrikethrough == span.isStrikethrough &&
          mergedSpans.last.color == span.color &&
          mergedSpans.last.fontSize == span.fontSize) {
        final last = mergedSpans.removeLast();
        mergedSpans.add(last.copyWith(text: last.text + span.text));
      } else {
        mergedSpans.add(span);
      }
    }
    return mergedSpans;
  }

  static _BlockPosition _findBlockPosition(
    List<DocumentBlock> blocks,
    int globalPosition,
  ) {
    var accumulatedLength = 0;
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      var blockLength = 0;
      if (block is TextBlock) {
        blockLength = block.spans
            .map((s) => s.text.length)
            .fold(0, (a, b) => a + b);
      } else {
        blockLength = 1; // Placeholder for image
      }

      if (globalPosition <= accumulatedLength + blockLength) {
        return _BlockPosition(i, globalPosition - accumulatedLength);
      }
      accumulatedLength += blockLength;
    }
    return const _BlockPosition(-1, 0); // Not found
  }

  static _SpanPosition _findSpanPosition(
    List<TextSpanModel> spans,
    int localPosition,
  ) {
    if (spans.isEmpty) return const _SpanPosition(0, 0);
    var accumulatedLength = 0;
    for (var i = 0; i < spans.length; i++) {
      final span = spans[i];
      if (localPosition <= accumulatedLength + span.text.length) {
        return _SpanPosition(i, localPosition - accumulatedLength);
      }
      accumulatedLength += span.text.length;
    }
    return _SpanPosition(spans.length - 1, spans.last.text.length);
  }
}

class _BlockPosition {
  const _BlockPosition(this.blockIndex, this.localOffset);
  final int blockIndex;
  final int localOffset;
}

class _SpanPosition {
  const _SpanPosition(this.spanIndex, this.localOffset);
  final int spanIndex;
  final int localOffset;
}
