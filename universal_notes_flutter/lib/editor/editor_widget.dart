import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';

/// A widget that renders a [DocumentModel] and allows text selection and editing.
class EditorWidget extends StatefulWidget {
  /// Creates a new instance of [EditorWidget].
  const EditorWidget({
    required this.document,
    required this.onDocumentChanged,
    required this.onSelectionChanged,
    this.selection,
    super.key,
  });

  /// The document to render.
  final DocumentModel document;
  /// Callback for when the document is changed by user input.
  final ValueChanged<DocumentModel> onDocumentChanged;
  /// The current text selection.
  final TextSelection? selection;
  /// Callback for when the text selection changes.
  final ValueChanged<TextSelection> onSelectionChanged;


  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  final FocusNode _focusNode = FocusNode();

  late TextSelection _selection;
  bool _showCursor = true;
  Timer? _cursorTimer;

  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  @override
  void initState() {
    super.initState();
    _selection = widget.selection ?? const TextSelection.collapsed(offset: 0);

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_focusNode.hasFocus) {
        if (_showCursor) setState(() => _showCursor = false);
        return;
      }
      setState(() => _showCursor = !_showCursor);
    });
  }

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != null && widget.selection != _selection) {
      setState(() {
        _selection = widget.selection!;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _cursorTimer?.cancel();
    _textPainter.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    DocumentModel docAfterEdit;
    TextSelection selectionAfterEdit;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_selection.isCollapsed) {
        if (_selection.start == 0) return;
        docAfterEdit = DocumentManipulator.deleteText(widget.document, _selection.start - 1, 1);
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start - 1);
      } else {
        docAfterEdit = DocumentManipulator.deleteText(widget.document, _selection.start, _selection.end - _selection.start);
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start);
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      final character = event.character!;
      if (_selection.isCollapsed) {
        docAfterEdit = DocumentManipulator.insertText(widget.document, _selection.start, character);
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start + character.length);
      } else {
        final docAfterDelete = DocumentManipulator.deleteText(widget.document, _selection.start, _selection.end - _selection.start);
        docAfterEdit = DocumentManipulator.insertText(docAfterDelete, _selection.start, character);
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start + character.length);
      }
    } else {
      return;
    }

    // After a key event, check for Markdown conversions.
    final conversionResult = MarkdownConverter.checkAndApply(docAfterEdit, selectionAfterEdit);

    if (conversionResult != null) {
      widget.onDocumentChanged(conversionResult.document);
      widget.onSelectionChanged(conversionResult.selection);
    } else {
      widget.onDocumentChanged(docAfterEdit);
      widget.onSelectionChanged(selectionAfterEdit);
    }
  }

  Offset _getCursorOffset() {
    if (widget.document.toPlainText().isEmpty) return Offset.zero;
    _updateTextPainter();
    return _textPainter.getOffsetForCaret(
      TextPosition(offset: _selection.extentOffset),
      Rect.zero,
    );
  }

  void _updateTextPainter() {
    _textPainter.text = widget.document.toTextSpan();
    _textPainter.layout(
      minWidth: 0,
      maxWidth: MediaQuery.of(context).size.width,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
    _updateTextPainter();
    final position = _textPainter.getPositionForOffset(details.localPosition);
    final newSelection = TextSelection.collapsed(offset: position.offset);
    widget.onSelectionChanged(newSelection);
    setState(() => _showCursor = true);
  }

  void _handlePanStart(DragStartDetails details) {
     _focusNode.requestFocus();
    _updateTextPainter();
    final position = _textPainter.getPositionForOffset(details.localPosition);
    final newSelection = TextSelection.fromPosition(position);
    widget.onSelectionChanged(newSelection);
    setState(() => _showCursor = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _updateTextPainter();
    final position = _textPainter.getPositionForOffset(details.localPosition);
    final newSelection = _selection.copyWith(extentOffset: position.offset);
    widget.onSelectionChanged(newSelection);
  }

  List<Widget> _buildSelectionHighlights() {
    if (_selection.isCollapsed) return [];
    _updateTextPainter();
    final List<TextBox> boxes = _textPainter.getBoxesForSelection(_selection);
    return boxes.map((box) {
      return Positioned(
        left: box.left,
        top: box.top,
        width: box.right - box.left,
        height: box.bottom - box.top,
        child: Container(color: Colors.blue.withOpacity(0.3)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: Stack(
          children: [
            RichText(
              text: widget.document.toTextSpan(),
            ),
            ..._buildSelectionHighlights(),
            if (_focusNode.hasFocus && _showCursor && _selection.isCollapsed)
              Positioned(
                left: _getCursorOffset().dx,
                top: _getCursorOffset().dy,
                child: Container(
                  width: 2,
                  height: 20, // Approximate height
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
