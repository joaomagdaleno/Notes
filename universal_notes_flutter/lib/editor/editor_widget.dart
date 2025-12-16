import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';
import 'package:universal_notes_flutter/editor/snippet_converter.dart';
import 'package:universal_notes_flutter/editor/text_layout_engine.dart';
import 'package:universal_notes_flutter/editor/virtual_text_buffer.dart';
import 'package:universal_notes_flutter/services/autocomplete_service.dart';
import 'package:universal_notes_flutter/widgets/autocomplete_overlay.dart';

/// A widget that provides a text editor with rich text capabilities.
class EditorWidget extends StatefulWidget {
  /// Creates a new instance of [EditorWidget].
  const EditorWidget({
    required this.document,
    required this.onDocumentChanged,
    required this.onSelectionChanged,
    this.selection,
    this.onSelectionRectChanged,
    super.key,
  });

  /// The current document model.
  final DocumentModel document;

  /// Callback when the document changes.
  final ValueChanged<DocumentModel> onDocumentChanged;

  /// The current text selection.
  final TextSelection? selection;

  /// Callback when the selection changes.
  final ValueChanged<TextSelection> onSelectionChanged;

  /// Callback when the selection rectangle changes (e.g., for toolbar
  /// positioning).
  final ValueChanged<Rect?>? onSelectionRectChanged;

  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  final FocusNode _focusNode = FocusNode();
  late TextSelection _selection;
  late VirtualTextBuffer _buffer;
  final Map<int, GlobalKey> _lineKeys = {};

  // Autocomplete state
  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  int _selectedSuggestionIndex = 0;
  Timer? _autocompleteDebounce;

  @override
  void initState() {
    super.initState();
    _selection = widget.selection ?? const TextSelection.collapsed(offset: 0);
    _buffer = VirtualTextBuffer(widget.document);
    _generateKeys();
  }

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document != oldWidget.document) {
      setState(() {
        _buffer = VirtualTextBuffer(widget.document);
        _generateKeys();
      });
    }
    if (widget.selection != null && widget.selection != _selection) {
      // Use a post-frame callback to ensure that the layout is up-to-date
      // before trying to calculate the selection rectangle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifySelectionRectChanged(widget.selection!);
      });
      setState(() {
        _selection = widget.selection!;
      });
    }
  }

  void _generateKeys() {
    _lineKeys.clear();
    for (var i = 0; i < _buffer.lines.length; i++) {
      _lineKeys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _autocompleteDebounce?.cancel();
    _hideAutocomplete();
    super.dispose();
  }

  void _onSelectionChanged(TextSelection newSelection) {
    widget.onSelectionChanged(newSelection);
    _notifySelectionRectChanged(newSelection);
  }

  void _notifySelectionRectChanged(TextSelection selection) {
    if (widget.onSelectionRectChanged == null) return;

    if (selection.isCollapsed) {
      widget.onSelectionRectChanged!(null);
      return;
    }

    final startPos = _buffer.getLineTextPositionForOffset(selection.start);
    final endPos = _buffer.getLineTextPositionForOffset(selection.end);
    Rect? totalRect;

    for (var i = startPos.line; i <= endPos.line; i++) {
      final lineKey = _lineKeys[i];
      if (lineKey == null || lineKey.currentContext == null) continue;

      final lineBox = lineKey.currentContext!.findRenderObject() as RenderBox;
      final painter = TextPainter(
        text: _buffer.lines[i].toTextSpan(),
        textDirection: TextDirection.ltr,
      );
      painter.layout(maxWidth: lineBox.size.width);

      final lineStartOffset = _buffer.getOffsetForLineTextPosition(
        LineTextPosition(line: i, character: 0),
      );

      final localSelection = TextSelection(
        baseOffset: math.max(0, selection.start - lineStartOffset),
        extentOffset: math.min(
          _buffer.lines[i].toPlainText().length,
          selection.end - lineStartOffset,
        ),
      );

      if (localSelection.isCollapsed) continue;

      final boxes = painter.getBoxesForSelection(localSelection);
      for (final box in boxes) {
        final globalRect = Rect.fromLTWH(
          lineBox.localToGlobal(Offset(box.left, box.top)).dx,
          lineBox.localToGlobal(Offset(box.left, box.top)).dy,
          box.width,
          box.height,
        );
        totalRect = totalRect?.expandToInclude(globalRect) ?? globalRect;
      }
    }
    widget.onSelectionRectChanged!(totalRect);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // --- Autocomplete Keyboard Interaction ---
    if (_autocompleteOverlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex + 1) % _suggestions.length;
        });
        _showAutocomplete(); // Rebuild the overlay with the new selection
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedSuggestionIndex =
              (_selectedSuggestionIndex - 1 + _suggestions.length) %
                  _suggestions.length;
        });
        _showAutocomplete();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (_suggestions.isNotEmpty) {
          _acceptAutocomplete(_suggestions[_selectedSuggestionIndex]);
        }
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideAutocomplete();
        return;
      }
    }

    DocumentModel docAfterEdit;
    TextSelection selectionAfterEdit;

    // --- Basic Text Editing ---
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_selection.isCollapsed) {
        if (_selection.start == 0) return;
        docAfterEdit = DocumentManipulator.deleteText(
          widget.document,
          _selection.start - 1,
          1,
        );
        selectionAfterEdit = TextSelection.collapsed(
          offset: _selection.start - 1,
        );
      } else {
        docAfterEdit = DocumentManipulator.deleteText(
          widget.document,
          _selection.start,
          _selection.end - _selection.start,
        );
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start);
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      final character = event.character!;
      if (_selection.isCollapsed) {
        docAfterEdit = DocumentManipulator.insertText(
          widget.document,
          _selection.start,
          character,
        );
        selectionAfterEdit = TextSelection.collapsed(
          offset: _selection.start + character.length,
        );
      } else {
        final docAfterDelete = DocumentManipulator.deleteText(
          widget.document,
          _selection.start,
          _selection.end - _selection.start,
        );
        docAfterEdit = DocumentManipulator.insertText(
          docAfterDelete,
          _selection.start,
          character,
        );
        selectionAfterEdit = TextSelection.collapsed(
          offset: _selection.start + character.length,
        );
      }
    } else {
      _hideAutocomplete();
      return;
    }

    // --- Post-edit Actions (Converters & Autocomplete) ---
    _runPostEditActions(docAfterEdit, selectionAfterEdit);
  }

  void _runPostEditActions(DocumentModel doc, TextSelection selection) {
    // --- Autocomplete ---
    _autocompleteDebounce?.cancel();
    _autocompleteDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_updateAutocomplete(doc, selection));
    });

    // --- Snippets & Markdown ---
    final snippetResult = SnippetConverter.checkAndApply(doc, selection);
    if (snippetResult != null) {
      widget.onDocumentChanged(snippetResult.document);
      _onSelectionChanged(snippetResult.selection);
      return;
    }

    final markdownResult = MarkdownConverter.checkAndApply(doc, selection);
    if (markdownResult != null) {
      widget.onDocumentChanged(markdownResult.document);
      _onSelectionChanged(markdownResult.selection);
      return;
    }

    // If no conversion, just apply the basic edit.
    widget.onDocumentChanged(doc);
    _onSelectionChanged(selection);
  }

  // --- Autocomplete Logic ---
  Future<void> _updateAutocomplete(
    DocumentModel document,
    TextSelection selection,
  ) async {
    final suggestions = await AutocompleteService.getSuggestions(
      document.toPlainText(),
      selection.baseOffset,
    );

    if (!mounted) return;

    setState(() {
      _suggestions = suggestions;
      _selectedSuggestionIndex = 0;
    });

    if (_suggestions.isNotEmpty) {
      _showAutocomplete();
    } else {
      _hideAutocomplete();
    }
  }

  Offset _getCursorScreenPosition() {
    final cursorPosition =
        _buffer.getLineTextPositionForOffset(_selection.baseOffset);
    final lineKey = _lineKeys[cursorPosition.line];
    if (lineKey == null || lineKey.currentContext == null) {
      return Offset.zero;
    }
    final lineBox = lineKey.currentContext!.findRenderObject() as RenderBox;

    final painter = TextPainter(
      text: _buffer.lines[cursorPosition.line].toTextSpan(),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: lineBox.size.width);

    final localOffset = painter.getOffsetForCaret(
      TextPosition(offset: cursorPosition.character),
      Rect.zero,
    );

    return lineBox.localToGlobal(localOffset);
  }

  void _showAutocomplete() {
    _hideAutocomplete(); // Remove existing overlay before showing a new one
    final overlay = Overlay.of(context);
    final cursorPosition = _getCursorScreenPosition();

    _autocompleteOverlay = OverlayEntry(
      builder: (context) => AutocompleteOverlay(
        suggestions: _suggestions,
        selectedIndex: _selectedSuggestionIndex,
        position: cursorPosition +
            const Offset(0, 25), // Position below cursor
        onSuggestionSelected: _acceptAutocomplete,
      ),
    );
    overlay.insert(_autocompleteOverlay!);
  }

  void _hideAutocomplete() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  void _acceptAutocomplete(String suggestion) {
    final plainText = widget.document.toPlainText();
    var start = _selection.baseOffset;
    while (start > 0 &&
        !AutocompleteService.isWordBoundary(plainText[start - 1])) {
      start--;
    }
    final wordInProgress = plainText.substring(start, _selection.baseOffset);

    final docAfterDelete = DocumentManipulator.deleteText(
      widget.document,
      start,
      wordInProgress.length,
    );
    final newDoc = DocumentManipulator.insertText(
      docAfterDelete,
      start,
      suggestion,
    );
    final newSelection = TextSelection.collapsed(
      offset: start + suggestion.length,
    );

    widget.onDocumentChanged(newDoc);
    _onSelectionChanged(newSelection);
    _hideAutocomplete();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: ListView.builder(
        itemCount: _buffer.lines.length,
        itemBuilder: (context, index) {
          final line = _buffer.lines[index];
          return _EditorLine(
            key: _lineKeys[index],
            line: line,
            selection: _selection,
            lineIndex: index,
            buffer: _buffer,
            focusNode: _focusNode,
            onSelectionChanged: _onSelectionChanged,
          );
        },
      ),
    );
  }
}

class _EditorLine extends StatefulWidget {
  const _EditorLine({
    required this.line,
    required this.selection,
    required this.lineIndex,
    required this.buffer,
    required this.focusNode,
    required this.onSelectionChanged,
    super.key,
  });

  final TextLine line;
  final TextSelection selection;
  final int lineIndex;
  final VirtualTextBuffer buffer;
  final FocusNode focusNode;
  final ValueChanged<TextSelection> onSelectionChanged;

  @override
  State<_EditorLine> createState() => _EditorLineState();
}

class _EditorLineState extends State<_EditorLine> {
  final TextPainter _painter = TextPainter(textDirection: TextDirection.ltr);
  bool _showCursor = false;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (widget.focusNode.hasFocus) {
        final cursorPosition = widget.buffer
            .getLineTextPositionForOffset(widget.selection.baseOffset);
        if (cursorPosition.line == widget.lineIndex) {
          setState(() => _showCursor = !_showCursor);
        } else if (_showCursor) {
          setState(() => _showCursor = false);
        }
      } else if (_showCursor) {
        setState(() => _showCursor = false);
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _painter.dispose();
    super.dispose();
  }

  int _getOffsetForPosition(Offset localPosition) {
    _painter.text = widget.line.toTextSpan();
    _painter.layout(maxWidth: context.size!.width);
    final position = _painter.getPositionForOffset(localPosition);
    return widget.buffer.getOffsetForLineTextPosition(
      LineTextPosition(line: widget.lineIndex, character: position.offset),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    widget.focusNode.requestFocus();
    final offset = _getOffsetForPosition(details.localPosition);
    widget.onSelectionChanged(TextSelection.collapsed(offset: offset));
  }

  void _handlePanStart(DragStartDetails details) {
    widget.focusNode.requestFocus();
    final offset = _getOffsetForPosition(details.localPosition);
    widget.onSelectionChanged(TextSelection.collapsed(offset: offset));
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final offset = _getOffsetForPosition(details.localPosition);
    widget.onSelectionChanged(
      widget.selection.copyWith(extentOffset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    _painter.text = widget.line.toTextSpan();
    _painter.layout(maxWidth: context.size?.width ?? double.infinity);

    final cursorPosition =
        widget.buffer.getLineTextPositionForOffset(widget.selection.baseOffset);
    final bool isCursorInThisLine =
        widget.selection.isCollapsed && cursorPosition.line == widget.lineIndex;

    final lineStartOffset = widget.buffer
        .getOffsetForLineTextPosition(LineTextPosition(line: widget.lineIndex, character: 0));
    final lineEndOffset = lineStartOffset + widget.line.toPlainText().length;

    final selectionStart = math.max(
      lineStartOffset,
      widget.selection.start,
    );
    final selectionEnd = math.min(
      lineEndOffset,
      widget.selection.end,
    );

    List<Widget> selectionBoxes = [];
    if (selectionStart < selectionEnd) {
      final localSelection = TextSelection(
        baseOffset: selectionStart - lineStartOffset,
        extentOffset: selectionEnd - lineStartOffset,
      );
      selectionBoxes = _painter.getBoxesForSelection(localSelection).map((box) {
        return Positioned(
          left: box.left,
          top: box.top,
          width: box.width,
          height: box.height,
          child: Container(color: Colors.blue.withOpacity(0.3)),
        );
      }).toList();
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      child: Stack(
        children: [
          RichText(text: widget.line.toTextSpan()),
          ...selectionBoxes,
          if (isCursorInThisLine && _showCursor)
            Positioned.fromRect(
              rect: _painter.getOffsetForCaret(
                    TextPosition(offset: cursorPosition.character),
                    Rect.zero,
                  ) &
                  Size(2, _painter.preferredLineHeight),
              child: Container(color: Colors.blue),
            ),
        ],
      ),
    );
  }
}
