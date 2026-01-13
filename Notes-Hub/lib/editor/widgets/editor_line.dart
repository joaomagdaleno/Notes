import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:notes_hub/editor/interactive_drawing_block.dart';
import 'package:notes_hub/editor/virtual_text_buffer.dart';
import 'package:notes_hub/models/document_model.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/stroke.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that renders a single line in the editor.
///
/// Handles rendering of text, images, tables, math equations, and
/// transclusions.
/// Supports user interaction via tap and pan gestures.
class EditorLine extends StatelessWidget {
  /// Creates an [EditorLine].
  const EditorLine({
    required this.line,
    required this.lineIndex,
    required this.selection,
    required this.buffer,
    required this.showCursor,
    required this.onTapDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.remoteCursors,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.isCurrentLine = false,
    this.onCheckboxTap,
    this.isDrawingMode = false,
    this.onStrokeAdded,
    this.onStrokeRemoved,
    this.softWrap = true,
    this.onLinkTap,
    super.key,
  });

  /// The line data model to render.
  final Line line;

  /// The index of this line in the document.
  final int lineIndex;

  /// The current text selection.
  final TextSelection selection;

  /// The virtual text buffer for text position calculations.
  final VirtualTextBuffer buffer;

  /// Whether to show the blinking cursor.
  final bool showCursor;

  /// Callback when the line is tapped.
  final void Function(TapDownDetails, int, TextSelection) onTapDown;

  /// Callback when a pan gesture starts.
  final void Function(DragStartDetails, int, TextSelection) onPanStart;

  /// Callback when a pan gesture updates.
  final void Function(DragUpdateDetails, int, TextSelection) onPanUpdate;

  /// Remote cursors to display (collaborative editing).
  final List<Map<String, dynamic>> remoteCursors;

  /// Current drawing color.
  final Color currentColor;

  /// Current drawing stroke width.
  final double currentStrokeWidth;

  /// Whether this is the currently focused line.
  final bool isCurrentLine;

  /// Callback when a checkbox is tapped (for checklist items).
  final ValueChanged<int>? onCheckboxTap;

  /// Whether the editor is in drawing mode.
  final bool isDrawingMode;

  /// Callback when a drawing stroke is added.
  final ValueChanged<Stroke>? onStrokeAdded;

  /// Callback when a drawing stroke is removed.
  final ValueChanged<Stroke>? onStrokeRemoved;

  /// Whether text should soft wrap.
  final bool softWrap;

  /// Callback when a link is tapped.
  final ValueChanged<String>? onLinkTap;

  int _getOffsetForPosition(
    BuildContext context,
    Offset localPosition,
    double maxWidth,
  ) {
    if (line is! TextLine) {
      return 0;
    }

    final textLine = line as TextLine;
    final painter = TextPainter(
      text: textLine.toTextSpan(),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final position = painter.getPositionForOffset(localPosition);
    return buffer.getOffsetForLineTextPosition(
      LineTextPosition(line: lineIndex, character: position.offset),
    );
  }

  void _handleTapDown(
    BuildContext context,
    TapDownDetails details,
    double maxWidth,
  ) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(
      context,
      details.localPosition,
      maxWidth,
    );
    onTapDown(details, lineIndex, TextSelection.collapsed(offset: offset));
  }

  void _handlePanStart(
    BuildContext context, {
    required DragStartDetails details,
    required double maxWidth,
  }) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(
      context,
      details.localPosition,
      maxWidth,
    );
    onPanStart(details, lineIndex, TextSelection.collapsed(offset: offset));
  }

  void _handlePanUpdate(
    BuildContext context, {
    required DragUpdateDetails details,
    required double maxWidth,
  }) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(
      context,
      details.localPosition,
      maxWidth,
    );
    onPanUpdate(details, lineIndex, selection.copyWith(extentOffset: offset));
  }

  Widget _buildImage(BuildContext context, ImageLine line) {
    final isNetwork = line.imagePath.startsWith('http');
    Widget getImage() => isNetwork
        ? Image.network(line.imagePath)
        : Image.file(File(line.imagePath));

    return GestureDetector(
      onTap: () {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => Dialog(child: getImage()),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: getImage(),
      ),
    );
  }

  Widget _buildText(BuildContext context, TextLine line) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // 1. Calculate geometry helper values
        final lineStartOffset = buffer.getOffsetForLineTextPosition(
          LineTextPosition(line: lineIndex, character: 0),
        );
        final lineLength = line.toPlainText().length;
        final lineEndOffset = lineStartOffset + lineLength;

        // 2. Check if we need to render cursor or selection
        final cursorPosition = buffer.getLineTextPositionForOffset(
          selection.baseOffset,
        );
        final isCursorInThisLine =
            selection.isCollapsed && cursorPosition.line == lineIndex;

        // Strict intersection check
        final hasSelection = selection.isValid &&
            !selection.isCollapsed &&
            selection.start < lineEndOffset &&
            selection.end > lineStartOffset;

        // --- Prepare visual wrapping based on attributes ---
        final attributes = line.attributes;
        final blockType = attributes['blockType'] as String?;
        final textAlignStr = attributes['textAlign'] as String? ?? 'left';

        TextAlign textAlign;
        switch (textAlignStr) {
          case 'center':
            textAlign = TextAlign.center;
          case 'right':
            textAlign = TextAlign.right;
          case 'justify':
            textAlign = TextAlign.justify;
          case 'left':
          default:
            textAlign = TextAlign.left;
        }

        var textSpan = TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: line.spans
              .map((s) => s.toTextSpan(onLinkTap: onLinkTap))
              .toList(),
        );

        if (blockType == 'heading') {
          final level = attributes['level'] as int? ?? 1;
          final fontSize = 32.0 - (level * 4); // Simple scaling
          textSpan = TextSpan(
            text: textSpan.text,
            children: textSpan.children,
            style: (textSpan.style ?? const TextStyle()).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        if (blockType == 'code-block') {
          textSpan = TextSpan(
            text: textSpan.text,
            children: textSpan.children,
            style: (textSpan.style ?? const TextStyle()).copyWith(
              fontFamily: 'monospace',
              color: Colors.grey[800],
            ),
          );
        }

        // 3. Early return optimization
        final painter = TextPainter(
          text: textSpan,
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
        )..layout(
            maxWidth: softWrap ? maxWidth : double.infinity,
          );

        final selectionBoxes = <Widget>[];
        if (hasSelection) {
          final selectionStart = math.max(lineStartOffset, selection.start);
          final selectionEnd = math.min(lineEndOffset, selection.end);

          final localSelection = TextSelection(
            baseOffset: selectionStart - lineStartOffset,
            extentOffset: selectionEnd - lineStartOffset,
          );

          selectionBoxes.addAll(
            painter.getBoxesForSelection(localSelection).map(
                  (box) => Positioned(
                    left: box.left,
                    top: box.top,
                    width: box.right - box.left,
                    height: box.bottom - box.top,
                    child: Container(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                ),
          );
        }

        // Core text widget (Stack of text + selection + cursor)
        final Widget textStack = Stack(
          children: [
            RichText(
              text: textSpan,
              textAlign: textAlign,
              softWrap: softWrap,
              overflow: softWrap ? TextOverflow.clip : TextOverflow.visible,
            ),
            ...selectionBoxes,
            if (isCursorInThisLine && showCursor)
              Positioned.fromRect(
                rect: painter.getOffsetForCaret(
                      TextPosition(offset: cursorPosition.character),
                      Rect.zero,
                    ) &
                    Size(2, painter.preferredLineHeight),
                child: Container(color: Colors.blue),
              ),
          ],
        );

        Widget content;

        // --- Apply Block Decorations ---
        if (attributes['blockType'] == 'drawing') {
          final strokesRaw = attributes['strokes'] as List<dynamic>? ?? [];
          final strokes = strokesRaw
              .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
              .toList();
          final height = (attributes['height'] as num?)?.toDouble() ?? 200.0;

          content = InteractiveDrawingBlock(
            strokes: strokes,
            height: height,
            isDrawingMode: isDrawingMode,
            onStrokeAdded: (stroke) => onStrokeAdded?.call(stroke),
            onStrokeRemoved: (stroke) => onStrokeRemoved?.call(stroke),
            currentColor: currentColor,
            currentStrokeWidth: currentStrokeWidth,
          );
        } else if (blockType == 'quote') {
          content = Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey, width: 4)),
            ),
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            child: textStack,
          );
        } else if (blockType == 'code-block') {
          content = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: textStack,
          );
        } else if (blockType == 'unordered-list') {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 24,
                child: Text('•', style: TextStyle(fontSize: 24, height: 1)),
              ),
              Expanded(child: textStack),
            ],
          );
        } else if (blockType == 'ordered-list') {
          var listIndex = 1;
          for (var i = lineIndex - 1; i >= 0; i--) {
            final prevLine = buffer.lines[i];
            if (prevLine is TextLine &&
                prevLine.attributes['blockType'] == 'ordered-list') {
              listIndex++;
            } else {
              break;
            }
          }

          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$listIndex.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              Expanded(child: textStack),
            ],
          );
        } else {
          final currentLine = line;

          // Use a text stack for better performance with large
          // blocks of text. This `textStack` is the one defined earlier,
          // so we don't redefine it here.
          // The instruction seems to imply a new textStack, but the
          // context suggests it's about how `content` is assigned based
          // on `currentLine` type.

          if (blockType == 'checklist') {
            // This was previously `else if (blockType == 'checklist')`
            final isChecked = attributes['checked'] as bool? ?? false;
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onCheckboxTap?.call(lineStartOffset),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 2),
                    child: defaultTargetPlatform == TargetPlatform.windows
                        ? fluent.Icon(
                            isChecked
                                ? fluent.FluentIcons.checkbox_composite
                                : fluent.FluentIcons.checkbox,
                            size: 20,
                            color: isChecked
                                ? fluent.Colors.grey
                                : fluent.Colors.black,
                          )
                        : Icon(
                            isChecked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 20,
                            color: isChecked ? Colors.grey : Colors.black87,
                          ),
                  ),
                ),
                Expanded(
                  child: Opacity(
                    opacity: isChecked ? 0.5 : 1.0,
                    child: textStack,
                  ),
                ),
              ],
            );
          } else if (currentLine is CalloutLine) {
            final calloutLine = currentLine;
            final type = calloutLine.type;
            Color color;
            IconData icon;
            final isWindows = defaultTargetPlatform == TargetPlatform.windows;
            switch (type) {
              case CalloutType.note:
                color = isWindows ? fluent.Colors.blue : Colors.blue;
                icon = isWindows ? fluent.FluentIcons.info : Icons.info;
              case CalloutType.tip:
                color = isWindows ? fluent.Colors.green : Colors.green;
                icon =
                    isWindows ? fluent.FluentIcons.lightbulb : Icons.lightbulb;
              case CalloutType.warning:
                color = isWindows ? fluent.Colors.orange : Colors.orange;
                icon = isWindows ? fluent.FluentIcons.warning : Icons.warning;
              case CalloutType.danger:
                color = isWindows ? fluent.Colors.red : Colors.red;
                icon = isWindows ? fluent.FluentIcons.error : Icons.error;
              case CalloutType.info:
                color = isWindows ? fluent.Colors.teal : Colors.lightBlue;
                icon = isWindows ? fluent.FluentIcons.info : Icons.info_outline;
              case CalloutType.success:
                color = isWindows ? fluent.Colors.green : Colors.greenAccent;
                icon = isWindows
                    ? fluent.FluentIcons.completed
                    : Icons.check_circle;
            }

            const iconSize = 20.0;
            const spacing = 12.0;

            var inner = textStack;
            if (calloutLine.isFirst) {
              inner = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  defaultTargetPlatform == TargetPlatform.windows
                      ? fluent.Icon(icon, color: color, size: iconSize)
                      : Icon(icon, color: color, size: iconSize),
                  const SizedBox(width: spacing),
                  Expanded(child: textStack),
                ],
              );
            } else {
              inner = Padding(
                padding: const EdgeInsets.only(left: iconSize + spacing),
                child: textStack,
              );
            }

            content = Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(color: color, width: 4),
                  top: calloutLine.isFirst
                      ? BorderSide(color: color.withValues(alpha: 0.1))
                      : BorderSide.none,
                  bottom: calloutLine.isLast
                      ? BorderSide(color: color.withValues(alpha: 0.1))
                      : BorderSide.none,
                  right: BorderSide(color: color.withValues(alpha: 0.1)),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: calloutLine.isFirst
                      ? const Radius.circular(4)
                      : Radius.zero,
                  topRight: calloutLine.isFirst
                      ? const Radius.circular(4)
                      : Radius.zero,
                  bottomLeft: calloutLine.isLast
                      ? const Radius.circular(4)
                      : Radius.zero,
                  bottomRight: calloutLine.isLast
                      ? const Radius.circular(4)
                      : Radius.zero,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                12,
                calloutLine.isFirst ? 12 : 4,
                12,
                calloutLine.isLast ? 12 : 4,
              ),
              child: inner,
            );
          } else if (currentLine is TableLine) {
            final tableLine = currentLine as TableLine;
            content = Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: tableLine.rows.map((row) {
                  return TableRow(
                    decoration: row.any((c) => c.isHeader)
                        ? BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                          )
                        : null,
                    children: row.map((cell) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: RichText(
                          text: TextSpan(
                            style: (Theme.of(context).textTheme.bodyMedium ??
                                    const TextStyle())
                                .copyWith(
                              fontWeight: cell.isHeader
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            children: cell.content
                                .map((s) => s.toTextSpan(onLinkTap: onLinkTap))
                                .toList(),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            );
          } else {
            content = textStack;
          }
        }

        final indentPadding = (attributes['indent'] as int? ?? 0) * 24.0;
        if (indentPadding > 0) {
          content = Padding(
            padding: EdgeInsets.only(left: indentPadding),
            child: content,
          );
        }

        // Wrap with highlight if this is the current line
        final highlightedContent = isCurrentLine
            ? ColoredBox(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                child: content,
              )
            : content;

        return GestureDetector(
          onTapDown: (d) {
            // Handle Link Taps
            final localTapOffset = d.localPosition;

            // Adjust local position for block padding
            var effectiveOffset = localTapOffset;
            if (blockType == 'quote') {
              effectiveOffset -= const Offset(16, 4);
            } else if (blockType == 'code-block') {
              effectiveOffset -= const Offset(8, 8);
            } else if (blockType == 'unordered-list') {
              effectiveOffset -= const Offset(24, 0);
            }

            // Find text position from offset
            final textPosition = painter.getPositionForOffset(effectiveOffset);

            var currentOffset = 0;
            // if (line is TextLine) - Always true
            for (final s in line.spans) {
              final len = s.text.length;
              if (textPosition.offset >= currentOffset &&
                  textPosition.offset < currentOffset + len) {
                if (s.linkUrl != null) {
                  final url = Uri.tryParse(s.linkUrl!);
                  if (url != null) {
                    unawaited(
                      launchUrl(url, mode: LaunchMode.externalApplication),
                    );
                  }
                  return;
                }
                break;
              }
              currentOffset += len;
            }

            _handleTapDown(context, d, maxWidth);
          },
          onPanStart: (d) =>
              _handlePanStart(context, details: d, maxWidth: maxWidth),
          onPanUpdate: (d) =>
              _handlePanUpdate(context, details: d, maxWidth: maxWidth),
          child: highlightedContent,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (line is ImageLine) {
      return _buildImage(context, line as ImageLine);
    } else if (line is TextLine) {
      return _buildText(context, line as TextLine);
    } else if (line is TableLine) {
      return _buildTable(context, line as TableLine);
    } else if (line is MathLine) {
      return _buildMath(context, line as MathLine);
    } else if (line is TransclusionLine) {
      return _buildTransclusion(context, line as TransclusionLine);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransclusion(BuildContext context, TransclusionLine line) {
    return FutureBuilder<Note?>(
      future: NoteRepository.instance.getNoteByTitle(line.noteTitle),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }

        final note = snapshot.data;
        if (note == null) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Nota não encontrada: ${line.noteTitle}',
              style: const TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final doc = DocumentModel.fromJson(json.decode(note.content));

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Divider(),
              ...doc.blocks.take(3).map((block) {
                if (block is TextBlock) {
                  return Text(
                    block.spans.map((s) => s.text).join(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMath(BuildContext context, MathLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Math.tex(
          line.tex,
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, TableLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: line.rows.map((row) {
          return TableRow(
            decoration: row.any((c) => c.isHeader)
                ? BoxDecoration(color: Colors.grey.withValues(alpha: 0.05))
                : null,
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: RichText(
                  text: TextSpan(
                    style: (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle())
                        .copyWith(
                      fontWeight:
                          cell.isHeader ? FontWeight.bold : FontWeight.normal,
                    ),
                    children: cell.content
                        .map((s) => s.toTextSpan(onLinkTap: onLinkTap))
                        .toList(),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
