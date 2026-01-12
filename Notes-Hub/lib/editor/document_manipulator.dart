import 'package:flutter/material.dart';
import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/models/document_model.dart';
import 'package:notes_hub/models/note_event.dart';
import 'package:notes_hub/models/stroke.dart';

/// The result of a document manipulation, including the new document state
/// and the event payload describing the change.
class ManipulationResult {
  /// Creates a [ManipulationResult].
  const ManipulationResult({
    required this.document,
    required this.eventPayload,
    required this.eventType,
  });

  /// The new state of the document.
  final DocumentModel document;

  /// The payload description of the operation (JSON-serializable).
  final Map<String, dynamic> eventPayload;

  /// The type of event (insert, delete, etc.).
  final NoteEventType eventType;
}

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
  DocumentManipulator._();

  /// Sets a block-level attribute (e.g., alignment).
  static ManipulationResult setBlockAttribute(
    DocumentModel document,
    int blockIndex,
    String key,
    dynamic value,
  ) {
    if (blockIndex < 0 || blockIndex >= document.blocks.length) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = document.blocks[blockIndex];
    final currentAttributes = Map<String, dynamic>.from(block.attributes);

    if (value == null) {
      currentAttributes.remove(key);
    } else {
      currentAttributes[key] = value;
    }

    DocumentBlock newBlock;
    if (block is TextBlock) {
      newBlock = TextBlock(spans: block.spans, attributes: currentAttributes);
    } else if (block is DrawingBlock) {
      newBlock = DrawingBlock(
        strokes: block.strokes,
        height: block.height,
        attributes: currentAttributes,
      );
    } else if (block is ImageBlock) {
      newBlock = ImageBlock(
        imagePath: block.imagePath,
        attributes: currentAttributes,
      );
    } else {
      // Fallback or generic block copy if we had a copyWith method
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final newBlocks = List<DocumentBlock>.from(document.blocks);
    newBlocks[blockIndex] = newBlock;

    return ManipulationResult(
      document: DocumentModel(blocks: newBlocks),
      eventPayload: {'blockIndex': blockIndex, 'key': key, 'value': value},
      eventType: NoteEventType.format,
    );
  }

  /// Changes the indentation level of a block.
  static ManipulationResult changeBlockIndent(
    DocumentModel document,
    int blockIndex,
    int delta,
  ) {
    if (blockIndex < 0 || blockIndex >= document.blocks.length) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = document.blocks[blockIndex];
    final currentIndent = (block.attributes['indent'] as int?) ?? 0;
    final newIndent = (currentIndent + delta).clamp(0, 10); // Max indent 10

    return setBlockAttribute(document, blockIndex, 'indent', newIndent);
  }

  /// Inserts an image block at the specified position.
  static ManipulationResult insertImage(
    DocumentModel document,
    int position,
    String imagePath,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    DocumentModel newDoc;
    if (pos.blockIndex == -1) {
      blocks.add(ImageBlock(imagePath: imagePath));
      newDoc = DocumentModel(blocks: blocks);
    } else {
      final targetBlock = blocks[pos.blockIndex];
      // simplified logic from original...
      if (targetBlock is! TextBlock) {
        blocks.insert(pos.blockIndex, ImageBlock(imagePath: imagePath));
        newDoc = DocumentModel(blocks: blocks);
      } else {
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
        if (beforeSpans.isNotEmpty) {
          newBlocks.add(TextBlock(spans: beforeSpans));
        }
        newBlocks.add(ImageBlock(imagePath: imagePath));
        if (afterSpans.isNotEmpty) newBlocks.add(TextBlock(spans: afterSpans));

        blocks.insertAll(pos.blockIndex, newBlocks);
        newDoc = DocumentModel(blocks: blocks);
      }
    }

    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.imageInsert,
      eventPayload: {
        'pos': position,
        'path': imagePath,
      },
    );
  }

  /// Toggles a style for the given selection.
  static ManipulationResult toggleStyle(
    DocumentModel document,
    TextSelection selection,
    StyleAttribute attribute,
  ) {
    final newDoc = applyToSelection(
      document,
      selection,
      (span) => span.copyWith(
        isBold: attribute == StyleAttribute.bold ? !span.isBold : span.isBold,
        isItalic:
            attribute == StyleAttribute.italic ? !span.isItalic : span.isItalic,
        isUnderline: attribute == StyleAttribute.underline
            ? !span.isUnderline
            : span.isUnderline,
        isStrikethrough: attribute == StyleAttribute.strikethrough
            ? !span.isStrikethrough
            : span.isStrikethrough,
      ),
    );
    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'pos': selection.start,
        'len': selection.end - selection.start,
        'attr': attribute.name,
      },
    );
  }

  /// Applies a color to the given selection.
  static ManipulationResult applyColor(
    DocumentModel document,
    TextSelection selection,
    Color color,
  ) {
    final newDoc = applyToSelection(
      document,
      selection,
      (span) => span.copyWith(color: color),
    );
    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'pos': selection.start,
        'len': selection.end - selection.start,
        // ignore: deprecated_member_use, documented for clarity: using hex value for storage
        'color': color.value,
      },
    );
  }

  /// Applies a font size to the given selection.
  static ManipulationResult applyFontSize(
    DocumentModel document,
    TextSelection selection,
    double fontSize,
  ) {
    final newDoc = applyToSelection(
      document,
      selection,
      (span) => span.copyWith(fontSize: fontSize),
    );
    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'pos': selection.start,
        'len': selection.end - selection.start,
        'fontSize': fontSize,
      },
    );
  }

  /// Applies a link URL to the given selection.
  static ManipulationResult applyLink(
    DocumentModel document,
    TextSelection selection,
    String? url,
  ) {
    final newDoc = applyToSelection(
      document,
      selection,
      (span) => span.copyWith(linkUrl: url),
    );
    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'pos': selection.start,
        'len': selection.end - selection.start,
        'linkUrl': url,
      },
    );
  }

  /// Applies an update function to the spans within a selection.
  static DocumentModel applyToSelection(
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

      final blockLength =
          block.spans.map((s) => s.text.length).fold(0, (a, b) => a + b);
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
      // Preserve attributes
      newBlocks.add(
        TextBlock(spans: _mergeSpans(newSpans), attributes: block.attributes),
      );
      currentPos = blockEnd; // Ensure currentPos is correct for next block
    }

    return DocumentModel(blocks: newBlocks);
  }

  /// Inserts text into the document at the specified position.
  static ManipulationResult insertText(
    DocumentModel document,
    int position,
    String text,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      if (blocks.isEmpty && position == 0) {
        final newBlock = TextBlock(spans: [TextSpanModel(text: text)]);
        return ManipulationResult(
          document: DocumentModel(blocks: [newBlock]),
          eventType: NoteEventType.insert,
          eventPayload: {
            'pos': 0,
            'text': text,
          },
        );
      }
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    if (blocks[pos.blockIndex] is! TextBlock) {
      // Cannot insert text into an image block
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }
    final targetBlock = blocks[pos.blockIndex] as TextBlock;
    final spans = List<TextSpanModel>.from(targetBlock.spans);

    final spanPos = _findSpanPosition(spans, pos.localOffset);
    final targetSpan = spans[spanPos.spanIndex];
    final newText = '${targetSpan.text.substring(0, spanPos.localOffset)}'
        '$text'
        '${targetSpan.text.substring(spanPos.localOffset)}';
    spans[spanPos.spanIndex] = targetSpan.copyWith(text: newText);
    blocks[pos.blockIndex] = TextBlock(
      spans: spans,
      attributes: targetBlock.attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.insert,
      eventPayload: {
        'pos': position,
        'text': text,
      },
    );
  }

  /// Deletes text from the document.
  static ManipulationResult deleteText(
    DocumentModel document,
    int start,
    int length,
  ) {
    if (length <= 0) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final end = start + length;
    final newBlocks = <DocumentBlock>[];
    var currentPos = 0;

    for (final block in document.blocks) {
      int blockLength;
      if (block is TextBlock) {
        blockLength =
            block.spans.map((s) => s.text.length).fold(0, (a, b) => a + b);
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
            final afterText =
                end < spanEnd ? span.text.substring(end - spanStart) : '';
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
          newBlocks.add(
            TextBlock(
              spans: _mergeSpans(newSpans),
              attributes: block.attributes,
            ),
          );
        } else {
          // Keep the block even if empty, to preserve structure/cursor potential
          newBlocks.add(
            TextBlock(
              spans: [const TextSpanModel(text: '')],
              attributes: block.attributes,
            ),
          );
        }
      }
      // If the block is an ImageBlock and is within the deletion range,
      // it is implicitly not added to newBlocks.
      currentPos = blockEnd;
    }

    return ManipulationResult(
      document: DocumentModel(blocks: newBlocks),
      eventType: NoteEventType.delete,
      eventPayload: {
        'pos': start,
        'len': length,
      },
    );
  }

  /// Sets attributes for the block at the given [position].
  static ManipulationResult setBlockAttributes(
    DocumentModel document,
    int position,
    Map<String, dynamic> attributes,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = blocks[pos.blockIndex];
    if (block is TextBlock) {
      // Merge attributes
      final newAttributes = Map<String, dynamic>.from(block.attributes)
        ..addAll(attributes);
      blocks[pos.blockIndex] = TextBlock(
        spans: block.spans,
        attributes: newAttributes,
      );
    } else if (block is ImageBlock) {
      final newAttributes = Map<String, dynamic>.from(block.attributes)
        ..addAll(attributes);
      blocks[pos.blockIndex] = ImageBlock(
        imagePath: block.imagePath,
        attributes: newAttributes,
      );
    }

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format, // Treat as format event
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'attrs': attributes,
      },
    );
  }

  /// Toggles a block attribute (e.g. alignment).
  /// If [value] is null, removes the attribute.
  static ManipulationResult toggleBlockAttribute(
    DocumentModel document,
    int position,
    String key,
    dynamic value,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = blocks[pos.blockIndex];
    final currentAttributes = Map<String, dynamic>.from(block.attributes);

    if (value == null || currentAttributes[key] == value) {
      currentAttributes.remove(key);
    } else {
      currentAttributes[key] = value;
    }

    // We reuse setBlockAttributes logic but we need to pass the FULL modified
    // map because setBlockAttributes MERGES.
    // Actually, to support removal, we might need a method that REPLACES
    // attributes or supports null to remove.
    // Our setBlockAttributes logic above merges.
    // Let's modify setBlockAttributes or handle it here manually.
    // We'll handle it manually here for precision.

    if (block is TextBlock) {
      blocks[pos.blockIndex] = TextBlock(
        spans: block.spans,
        attributes: currentAttributes,
      );
    } else if (block is ImageBlock) {
      blocks[pos.blockIndex] = ImageBlock(
        imagePath: block.imagePath,
        attributes: currentAttributes,
      );
    }

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'attrs': currentAttributes,
      },
    );
  }

  /// Converts a block to a CalloutBlock with the specified type.
  static ManipulationResult convertBlockToCallout(
    DocumentModel document,
    int position,
    CalloutType type,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = blocks[pos.blockIndex];
    if (block is TextBlock) {
      blocks[pos.blockIndex] = CalloutBlock(
        type: type,
        spans: block.spans,
        attributes: block.attributes,
      );
    } else if (block is CalloutBlock) {
      // Just update type
      blocks[pos.blockIndex] = CalloutBlock(
        type: type,
        spans: block.spans,
        attributes: block.attributes,
      );
    } else {
      // Ignore other block types
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'calloutType': type.name,
      },
    );
  }

  /// Converts a block to a TableBlock.
  static ManipulationResult convertBlockToTable(
    DocumentModel document,
    int position,
    List<List<TableCellModel>> rows,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    // Replace the block with a TableBlock
    blocks[pos.blockIndex] = TableBlock(
      rows: rows,
      // Preserve attributes if possible/desirable?
      attributes: blocks[pos.blockIndex].attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'type': 'table',
      },
    );
  }

  /// Converts a block to a MathBlock.
  static ManipulationResult convertBlockToMath(
    DocumentModel document,
    int position,
    String tex,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    // Replace the block with a MathBlock
    blocks[pos.blockIndex] = MathBlock(
      tex: tex,
      attributes: blocks[pos.blockIndex].attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'type': 'math',
      },
    );
  }

  /// Converts a block to a TransclusionBlock.
  static ManipulationResult convertBlockToTransclusion(
    DocumentModel document,
    int position,
    String noteTitle,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    // Replace the block with a TransclusionBlock
    blocks[pos.blockIndex] = TransclusionBlock(
      noteTitle: noteTitle,
      attributes: blocks[pos.blockIndex].attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': pos.blockIndex,
        'type': 'transclusion',
      },
    );
  }

  /// Changes the indentation level of the block.
  /// [change] can be +1 or -1.
  static ManipulationResult indentBlock(
    DocumentModel document,
    int position,
    int change,
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = blocks[pos.blockIndex];
    final currentLevel = (block.attributes['indent'] as int?) ?? 0;
    final newLevel = (currentLevel + change).clamp(0, 8); // Max indentation 8

    return toggleBlockAttribute(document, position, 'indent', newLevel);
  }

  /// Toggles a list attribute (e.g., 'bullet' or 'ordered').
  /// If the block is already the specified list type, it removes the list
  /// attribute.
  /// Otherwise, it sets the block to the specified list type.
  static ManipulationResult toggleList(
    DocumentModel document,
    int position,
    String listType, // e.g., 'bullet', 'ordered'
  ) {
    final blocks = List<DocumentBlock>.from(document.blocks);
    final pos = _findBlockPosition(blocks, position);

    if (pos.blockIndex == -1) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = blocks[pos.blockIndex];
    final currentListType = block.attributes['list'];

    // If already this list type, remove it. Otherwise, set it.
    final newValue = currentListType == listType ? null : listType;

    return toggleBlockAttribute(document, position, 'list', newValue);
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
          mergedSpans.last.isCode == span.isCode &&
          mergedSpans.last.color == span.color &&
          mergedSpans.last.backgroundColor == span.backgroundColor &&
          mergedSpans.last.fontSize == span.fontSize &&
          mergedSpans.last.linkUrl == span.linkUrl) {
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
        blockLength =
            block.spans.map((s) => s.text.length).fold(0, (a, b) => a + b);
        // Treat trailing newline?
        // Our buffer logic handles block separation implicitly or explicitly.
        // DocumentModel usually has tight blocks.
      } else {
        blockLength = 1; // Placeholder for image
      }

      // We use < because we want to match the block containing the cursor.
      // If cursor is AT the end of block, it usually belongs to that block for
      // formatting purposes UNLESS it's at the very start of next block.
      // Logic: if position == accumulatedLength, it's at start of this block.
      // exception: position 0.

      if (globalPosition >= accumulatedLength &&
          globalPosition < accumulatedLength + blockLength) {
        return _BlockPosition(i, globalPosition - accumulatedLength);
      }

      // Edge case: Cursor at exact end of document or block?
      // If we are appending, we might be at the end.
      if (blockLength > 0 &&
          globalPosition == accumulatedLength + blockLength) {
        return _BlockPosition(i, blockLength);
      }

      // Match empty blocks if we are at their position
      if (blockLength == 0 && globalPosition == accumulatedLength) {
        return _BlockPosition(i, 0);
      }

      accumulatedLength += blockLength;
    }
    // If empty document
    if (blocks.isEmpty && globalPosition == 0) {
      return const _BlockPosition(-1, 0);
    }

    return const _BlockPosition(-1, 0);
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

  /// Adds a stroke to a drawing block.
  static ManipulationResult addStrokeToBlock(
    DocumentModel document,
    int blockIndex,
    Stroke stroke,
  ) {
    if (blockIndex < 0 || blockIndex >= document.blocks.length) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = document.blocks[blockIndex];
    if (block is! DrawingBlock) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final newStrokes = List<Stroke>.from(block.strokes)..add(stroke);
    final blocks = List<DocumentBlock>.from(document.blocks);
    blocks[blockIndex] = DrawingBlock(
      strokes: newStrokes,
      height: block.height,
      attributes: block.attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format, // Treat stroke add as format/update
      eventPayload: {
        'blockIndex': blockIndex,
      },
    );
  }

  /// Removes a stroke from a drawing block.
  static ManipulationResult removeStrokeFromBlock(
    DocumentModel document,
    int blockIndex,
    Stroke stroke,
  ) {
    if (blockIndex < 0 || blockIndex >= document.blocks.length) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    final block = document.blocks[blockIndex];
    if (block is! DrawingBlock) {
      return ManipulationResult(
        document: document,
        eventPayload: {},
        eventType: NoteEventType.unknown,
      );
    }

    // Filter out the stroke. Using equality check.
    // Since we don't have IDs, we remove the first matching stroke logic or by
    // index if passed.
    // Assuming passed 'stroke' is an instance from the list, simple reference
    // removal might fail if reconstructed.
    // But let's try value equality.
    final newStrokes =
        block.strokes.where((s) => !_areStrokesEqual(s, stroke)).toList();

    final blocks = List<DocumentBlock>.from(document.blocks);
    blocks[blockIndex] = DrawingBlock(
      strokes: newStrokes,
      height: block.height,
      attributes: block.attributes,
    );

    return ManipulationResult(
      document: DocumentModel(blocks: blocks),
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': blockIndex,
        'removedStroke': stroke.toJson(),
      },
    );
  }

  static bool _areStrokesEqual(Stroke a, Stroke b) {
    if (a.color != b.color) return false;
    if (a.width != b.width) return false;
    if (a.points.length != b.points.length) return false;
    for (var i = 0; i < a.points.length; i++) {
      final pA = a.points[i];
      final pB = b.points[i];
      if (pA.x != pB.x || pA.y != pB.y) return false;
    }
    return true;
  }

  /// Toggles a link URL on the given selection.
  ///
  /// If [url] is provided, applies the link.
  /// If null, removes any existing link.
  static ManipulationResult toggleLink(
    DocumentModel document,
    TextSelection selection,
    String? url,
  ) {
    final newDoc = applyToSelection(
      document,
      selection,
      (span) => span.copyWith(
        linkUrl: url,
        isUnderline: url != null || span.isUnderline,
      ),
    );
    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'pos': selection.start,
        'len': selection.end - selection.start,
        'linkUrl': url,
      },
    );
  }

  /// Updates the layout metadata (e.g., x, y for Brainstorm) of a block.

  static ManipulationResult updateBlockLayout(
    DocumentModel document,
    int blockIndex,
    Map<String, dynamic> layoutMetadata,
  ) {
    if (blockIndex < 0 || blockIndex >= document.blocks.length) {
      return ManipulationResult(
        document: document,
        eventType: NoteEventType.format,
        eventPayload: {},
      );
    }

    final oldBlock = document.blocks[blockIndex];
    final DocumentBlock newBlock;

    // We need to recreate the specific block type to preserve its data
    if (oldBlock is TextBlock) {
      newBlock = TextBlock(
        spans: oldBlock.spans,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is ImageBlock) {
      newBlock = ImageBlock(
        imagePath: oldBlock.imagePath,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is DrawingBlock) {
      newBlock = DrawingBlock(
        strokes: oldBlock.strokes,
        height: oldBlock.height,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is CalloutBlock) {
      newBlock = CalloutBlock(
        type: oldBlock.type,
        spans: oldBlock.spans,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is TableBlock) {
      newBlock = TableBlock(
        rows: oldBlock.rows,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is MathBlock) {
      newBlock = MathBlock(
        tex: oldBlock.tex,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else if (oldBlock is TransclusionBlock) {
      newBlock = TransclusionBlock(
        noteTitle: oldBlock.noteTitle,
        attributes: oldBlock.attributes,
        layoutMetadata: layoutMetadata,
      );
    } else {
      // Fallback
      newBlock = oldBlock;
    }

    final newBlocks = List<DocumentBlock>.from(document.blocks);
    newBlocks[blockIndex] = newBlock;

    final newDoc = DocumentModel(blocks: newBlocks);

    return ManipulationResult(
      document: newDoc,
      eventType: NoteEventType.format,
      eventPayload: {
        'blockIndex': blockIndex,
        'layoutMetadata': layoutMetadata,
      },
    );
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
