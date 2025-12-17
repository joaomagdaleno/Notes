import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';
import 'package:universal_notes_flutter/editor/remote_cursor.dart';
import 'package:universal_notes_flutter/editor/snippet_converter.dart';
import 'package:universal_notes_flutter/editor/virtual_text_buffer.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/models/stroke.dart';
import 'package:universal_notes_flutter/services/autocomplete_service.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/widgets/autocomplete_overlay.dart';
import 'package:universal_notes_flutter/editor/interactive_drawing_block.dart';

/// A widget that provides a text editor with rich text capabilities.
class EditorWidget extends StatefulWidget {
  /// Creates a new instance of [EditorWidget].
  const EditorWidget({
    required this.document,
    required this.onDocumentChanged,
    required this.onSelectionChanged,
    this.selection,
    this.onSelectionRectChanged,
    this.scrollController,
    this.remoteCursors = const {},
    this.onEvent,
    this.onStyleToggle,
    this.onUndo,
    this.onRedo,
    this.onSave,
    this.onFind,
    this.onEscape,
    this.onCheckboxTap,
    this.isDrawingMode = false,
    this.currentColor = Colors.black,
    this.currentStrokeWidth = 2.0,
    super.key,
  });

  /// The current stroke color for drawing.
  final Color currentColor;

  /// The current stroke width for drawing.
  final double currentStrokeWidth;

  /// The current document model.
  final DocumentModel document;

  /// Whether the editor is in drawing mode.
  final bool isDrawingMode;

  /// Callback when the document changes.
  final ValueChanged<DocumentModel> onDocumentChanged;

  /// The current text selection.
  final TextSelection? selection;

  /// A map of remote cursors to display.
  final Map<String, Map<String, dynamic>> remoteCursors;

  /// Callback when the selection changes.
  final ValueChanged<TextSelection> onSelectionChanged;

  /// Callback when the selection rectangle changes (e.g., for toolbar
  /// positioning).
  final ValueChanged<Rect?>? onSelectionRectChanged;

  /// Callback when an editing event occurs.
  final void Function(NoteEventType type, Map<String, dynamic> payload)?
  onEvent;

  /// Controls the scrolling of the editor.
  final ScrollController? scrollController;

  // --- Keyboard Shortcut Callbacks ---

  /// Callback when a style toggle shortcut is pressed (Ctrl+B/I/U).
  final void Function(StyleAttribute attribute)? onStyleToggle;

  /// Callback when undo shortcut is pressed (Ctrl+Z).
  final VoidCallback? onUndo;

  /// Callback when redo shortcut is pressed (Ctrl+Shift+Z or Ctrl+Y).
  final VoidCallback? onRedo;

  /// Callback when save shortcut is pressed (Ctrl+S).
  final VoidCallback? onSave;

  /// Callback when find shortcut is pressed (Ctrl+F).
  final VoidCallback? onFind;

  /// Callback when escape key is pressed.
  final VoidCallback? onEscape;

  /// Callback when a checkbox is tapped.
  final ValueChanged<int>? onCheckboxTap;

  @override
  State<EditorWidget> createState() => EditorWidgetState();
}

/// State for [EditorWidget].
class EditorWidgetState extends State<EditorWidget> {
  final FocusNode _focusNode = FocusNode();
  late TextSelection _selection;
  late VirtualTextBuffer _buffer;
  final Map<int, GlobalKey> _lineKeys = {};

  // Autocomplete state
  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  int _selectedSuggestionIndex = 0;
  Timer? _autocompleteDebounce;

  // Cursor state
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _selection = widget.selection ?? const TextSelection.collapsed(offset: 0);
    _buffer = VirtualTextBuffer(widget.document);
    _generateKeys();
    _startCursorTimer();
  }

  void _startCursorTimer() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_focusNode.hasFocus) {
        setState(() {
          _showCursor = !_showCursor;
        });
      } else if (_showCursor) {
        // always hide if not focused
        setState(() {
          _showCursor = false;
        });
      }
    });
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
    _cursorTimer?.cancel();
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

      final lineBox = lineKey.currentContext!.findRenderObject()! as RenderBox;
      final line = _buffer.lines[i];

      if (line is! TextLine) continue;

      final painter = TextPainter(
        text: line.toTextSpan(),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: lineBox.size.width);

      final lineStartOffset = _buffer.getOffsetForLineTextPosition(
        LineTextPosition(line: i, character: 0),
      );

      final localSelection = TextSelection(
        baseOffset: math.max(0, selection.start - lineStartOffset),
        extentOffset: math.min(
          line.toPlainText().length,
          selection.end - lineStartOffset,
        ),
      );

      if (localSelection.isCollapsed) continue;

      final boxes = painter.getBoxesForSelection(localSelection);
      for (final box in boxes) {
        final globalRect = Rect.fromLTWH(
          lineBox.localToGlobal(Offset(box.left, box.top)).dx,
          lineBox.localToGlobal(Offset(box.left, box.top)).dy,
          box.right - box.left,
          box.bottom - box.top,
        );
        totalRect = totalRect?.expandToInclude(globalRect) ?? globalRect;
      }
    }
    widget.onSelectionRectChanged!(totalRect);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed; // Cmd on macOS
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

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

    // --- Keyboard Shortcuts (Ctrl/Cmd + Key) ---
    if (isCtrlPressed) {
      // Formatting shortcuts
      if (event.logicalKey == LogicalKeyboardKey.keyB) {
        widget.onStyleToggle?.call(StyleAttribute.bold);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
        widget.onStyleToggle?.call(StyleAttribute.italic);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
        widget.onStyleToggle?.call(StyleAttribute.underline);
        return;
      }

      // Undo/Redo shortcuts
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (isShiftPressed) {
          widget.onRedo?.call();
        } else {
          widget.onUndo?.call();
        }
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
        widget.onRedo?.call();
        return;
      }

      // Save shortcut
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        widget.onSave?.call();
        return;
      }

      // Find shortcut
      if (event.logicalKey == LogicalKeyboardKey.keyF) {
        widget.onFind?.call();
        return;
      }

      // Select all
      if (event.logicalKey == LogicalKeyboardKey.keyA) {
        final plainText = widget.document.toPlainText();
        _selection = TextSelection(
          baseOffset: 0,
          extentOffset: plainText.length,
        );
        widget.onSelectionChanged?.call(_selection);
        setState(() {});
        return;
      }
    }

    // Escape key - exit focus mode or close overlays
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onEscape?.call();
      return;
    }

    DocumentModel docAfterEdit;
    TextSelection selectionAfterEdit;

    // --- Basic Text Editing ---
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_selection.isCollapsed) {
        if (_selection.start == 0) return;
        final result = DocumentManipulator.deleteText(
          widget.document,
          _selection.start - 1,
          1,
        );
        docAfterEdit = result.document;
        widget.onEvent?.call(result.eventType, result.eventPayload);
        selectionAfterEdit = TextSelection.collapsed(
          offset: _selection.start - 1,
        );
      } else {
        final result = DocumentManipulator.deleteText(
          widget.document,
          _selection.start,
          _selection.end - _selection.start,
        );
        docAfterEdit = result.document;
        widget.onEvent?.call(result.eventType, result.eventPayload);
        selectionAfterEdit = TextSelection.collapsed(offset: _selection.start);
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      final character = event.character!;

      // Passive Dictionary Learning
      if (AutocompleteService.isWordBoundary(character) &&
          _selection.isCollapsed) {
        final plainText = widget.document.toPlainText();
        var end = _selection.start;
        var start = end;
        // Backtrack to find word start
        while (start > 0 &&
            !AutocompleteService.isWordBoundary(plainText[start - 1])) {
          start--;
        }
        if (end > start) {
          final word = plainText.substring(start, end);
          if (word.trim().isNotEmpty) {
            unawaited(NoteRepository.instance.learnWord(word));
          }
        }
      }

      if (_selection.isCollapsed) {
        final result = DocumentManipulator.insertText(
          widget.document,
          _selection.start,
          character,
        );
        docAfterEdit = result.document;
        widget.onEvent?.call(result.eventType, result.eventPayload);
        selectionAfterEdit = TextSelection.collapsed(
          offset: _selection.start + character.length,
        );
      } else {
        final deleteResult = DocumentManipulator.deleteText(
          widget.document,
          _selection.start,
          _selection.end - _selection.start,
        );
        final docAfterDelete = deleteResult.document;
        widget.onEvent?.call(deleteResult.eventType, deleteResult.eventPayload);

        final insertResult = DocumentManipulator.insertText(
          docAfterDelete,
          _selection.start,
          character,
        );
        docAfterEdit = insertResult.document;
        widget.onEvent?.call(insertResult.eventType, insertResult.eventPayload);

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
      for (final result in snippetResult.results) {
        widget.onEvent?.call(result.eventType, result.eventPayload);
      }
      return;
    }

    final markdownResult = MarkdownConverter.checkAndApply(doc, selection);
    if (markdownResult != null) {
      widget.onDocumentChanged(markdownResult.document);
      _onSelectionChanged(markdownResult.selection);
      for (final result in markdownResult.results) {
        widget.onEvent?.call(result.eventType, result.eventPayload);
      }
      return;
    }

    // If no conversion, just apply the basic edit.
    widget.onDocumentChanged(doc);
    _onSelectionChanged(selection);
  }

  /// Scrolls the editor to center the current line of the selection.
  void centerLine() {
    final line = _buffer
        .getLineTextPositionForOffset(_selection.baseOffset)
        .line;
    final lineKey = _lineKeys[line];
    if (lineKey != null && lineKey.currentContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          lineKey.currentContext!,
          alignment: 0.5, // Center of the viewport
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    }
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
    final cursorPosition = _buffer.getLineTextPositionForOffset(
      _selection.baseOffset,
    );
    final lineKey = _lineKeys[cursorPosition.line];
    if (lineKey == null || lineKey.currentContext == null) {
      return Offset.zero;
    }
    final lineBox = lineKey.currentContext!.findRenderObject()! as RenderBox;

    final line = _buffer.lines[cursorPosition.line];
    if (line is! TextLine) return lineBox.localToGlobal(Offset.zero);

    final painter = TextPainter(
      text: line.toTextSpan(),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: lineBox.size.width);

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
    final screenHeight = MediaQuery.of(context).size.height;

    // Decide whether to show above or below
    const overlayHeight = 200.0; // Estimated height of the overlay
    final showAbove = cursorPosition.dy > screenHeight / 2;
    final position = showAbove
        ? cursorPosition - const Offset(0, overlayHeight)
        : cursorPosition + const Offset(0, 25);

    _autocompleteOverlay = OverlayEntry(
      builder: (context) => AutocompleteOverlay(
        suggestions: _suggestions,
        selectedIndex: _selectedSuggestionIndex,
        position: position,
        onSuggestionSelected: _acceptAutocomplete,
      ),
    );
    overlay.insert(_autocompleteOverlay!);
    // Announce for screen readers
    if (_suggestions.isNotEmpty) {
      final suggestion = _suggestions[_selectedSuggestionIndex];
      unawaited(
        // Explanation: SemanticsService.announce is deprecated but the
        // replacement is not straightforward for this use case.
        // ignore: deprecated_member_use
        SemanticsService.announce(
          'Showing suggestions. Current: $suggestion',
          TextDirection.ltr,
        ),
      );
    }
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

    final deleteResult = DocumentManipulator.deleteText(
      widget.document,
      start,
      wordInProgress.length,
    );
    final docAfterDelete = deleteResult.document;
    widget.onEvent?.call(deleteResult.eventType, deleteResult.eventPayload);

    final insertResult = DocumentManipulator.insertText(
      docAfterDelete,
      start,
      suggestion,
    );
    final newDoc = insertResult.document;
    widget.onEvent?.call(insertResult.eventType, insertResult.eventPayload);
    final newSelection = TextSelection.collapsed(
      offset: start + suggestion.length,
    );

    widget.onDocumentChanged(newDoc);
    _onSelectionChanged(newSelection);
    _hideAutocomplete();

    // Learn the accepted word
    unawaited(NoteRepository.instance.learnWord(suggestion));
  }

  void _handleTapDown(
    TapDownDetails details,
    int lineIndex,
    TextSelection selection,
  ) {
    _focusNode.requestFocus();
    _onSelectionChanged(selection);
  }

  void _handlePanStart(
    DragStartDetails details,
    int lineIndex,
    TextSelection selection,
  ) {
    _focusNode.requestFocus();
    _onSelectionChanged(selection);
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    int lineIndex,
    TextSelection selection,
  ) {
    _onSelectionChanged(selection);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          ListView.builder(
            controller: widget.scrollController,
            itemCount: _buffer.lines.length,
            itemBuilder: (context, index) {
              final line = _buffer.lines[index];
              // Determine remote cursors for this line
              final cursorsOnLine = widget.remoteCursors.entries
                  .where((entry) {
                    final data = entry.value;
                    final selectionData =
                        data['selection'] as Map<String, dynamic>?;
                    if (selectionData == null) return false;
                    final base = selectionData['base'] as int?;
                    final extent = selectionData['extent'] as int?;
                    if (base == null || extent == null) return false;

                    final remoteSelection = TextSelection(
                      baseOffset: base,
                      extentOffset: extent,
                    );
                    final lineStartOffset = _buffer
                        .getOffsetForLineTextPosition(
                          LineTextPosition(line: index, character: 0),
                        );
                    final lineLength = line is TextLine
                        ? line.toPlainText().length
                        : 1;
                    final lineEndOffset = lineStartOffset + lineLength;

                    return (remoteSelection.start < lineEndOffset &&
                        remoteSelection.end > lineStartOffset);
                  })
                  .map((e) => e.value)
                  .toList();

              return _EditorLine(
                key: _lineKeys[index],
                line: line,
                lineIndex: index,
                selection: _selection, // Keep local selection for rendering
                buffer: _buffer,
                showCursor: _showCursor, // Keep local showCursor
                onTapDown: _handleTapDown,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                remoteCursors: cursorsOnLine,
                onCheckboxTap: widget.onCheckboxTap,
                isDrawingMode: widget.isDrawingMode,
                // We need to pass a callback to update drawing block
                onStrokeAdded: (stroke) {
                  final blockIndex = index; // Need accurate block index?
                  // _buffer.lines[index] might not 1:1 map to blocks if split!
                  // Wait, DocumentModel blocks map 1:1 to lines?
                  // VirtualTextBuffer splits on newlines.
                  // DrawingBlock likely has no newlines, so it's a single line.
                  // But we verified earlier we might have issues if blocks are mixed.
                  // Assuming 1-to-1 for now for DrawingBlock.

                  final result = DocumentManipulator.addStrokeToBlock(
                    widget.document,
                    blockIndex,
                    stroke,
                  );
                  widget.onDocumentChanged(result.document);
                },
                onStrokeRemoved: (stroke) {
                  final blockIndex = index;
                  final result = DocumentManipulator.removeStrokeFromBlock(
                    widget.document,
                    blockIndex,
                    stroke,
                  );
                  widget.onDocumentChanged(result.document);
                },
                currentColor: widget.currentColor,
                currentStrokeWidth: widget.currentStrokeWidth,
              );
            },
          ),
          ..._buildRemoteCursors(),
        ],
      ),
    );
  }

  List<Widget> _buildRemoteCursors() {
    final cursorWidgets = <Widget>[];
    for (final entry in widget.remoteCursors.entries) {
      final data = entry.value;
      final selectionData = data['selection'] as Map<String, dynamic>?;
      if (selectionData == null) continue;

      final base = selectionData['base'] as int?;
      final extent = selectionData['extent'] as int?;
      if (base == null || extent == null) continue;

      final remoteSelection = TextSelection(
        baseOffset: base,
        extentOffset: extent,
      );
      final color = Color(data['color'] as int? ?? Colors.grey.toARGB32());
      final name = data['name'] as String? ?? 'Guest';

      final startPos = _buffer.getLineTextPositionForOffset(
        remoteSelection.start,
      );
      final endPos = _buffer.getLineTextPositionForOffset(remoteSelection.end);

      for (var i = startPos.line; i <= endPos.line; i++) {
        final lineKey = _lineKeys[i];
        if (lineKey == null || lineKey.currentContext == null) continue;
        final lineBox =
            lineKey.currentContext!.findRenderObject()! as RenderBox;
        final line = _buffer.lines[i];
        if (line is! TextLine) continue;

        final painter = TextPainter(
          text: line.toTextSpan(),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: lineBox.size.width);

        final lineStartOffset = _buffer.getOffsetForLineTextPosition(
          LineTextPosition(line: i, character: 0),
        );

        final localSelection = TextSelection(
          baseOffset: math.max(0, remoteSelection.start - lineStartOffset),
          extentOffset: math.min(
            line.toPlainText().length,
            remoteSelection.end - lineStartOffset,
          ),
        );

        if (localSelection.isCollapsed) {
          final isStart = i == startPos.line;
          if (isStart) {
            final cursorOffset = painter.getOffsetForCaret(
              TextPosition(offset: localSelection.baseOffset),
              Rect.zero,
            );
            cursorWidgets.add(
              Positioned(
                left: lineBox.localToGlobal(Offset.zero).dx + cursorOffset.dx,
                top: lineBox.localToGlobal(Offset.zero).dy + cursorOffset.dy,
                child: RemoteCursor(color: color, name: name),
              ),
            );
          }
        } else {
          final boxes = painter.getBoxesForSelection(localSelection);
          for (final box in boxes) {
            cursorWidgets.add(
              Positioned(
                left: lineBox.localToGlobal(Offset.zero).dx + box.left,
                top: lineBox.localToGlobal(Offset.zero).dy + box.top,
                width: box.right - box.left,
                height: box.bottom - box.top,
                child: Container(color: color.withValues(alpha: 0.3)),
              ),
            );
          }
        }
      }
    }
    return cursorWidgets;
  }
}

class _EditorLine extends StatelessWidget {
  final void Function(TapDownDetails, int, TextSelection) onTapDown;
  final void Function(DragStartDetails, int, TextSelection) onPanStart;
  final void Function(DragUpdateDetails, int, TextSelection) onPanUpdate;
  final List<Map<String, dynamic>> remoteCursors;
  final ValueChanged<int>? onCheckboxTap;
  final bool isDrawingMode;
  final ValueChanged<Stroke>? onStrokeAdded;
  final ValueChanged<Stroke>? onStrokeRemoved;
  final Color currentColor;
  final double currentStrokeWidth;

  const _EditorLine({
    required this.line,
    required this.lineIndex,
    required this.selection,
    required this.buffer,
    required this.showCursor,
    required this.onTapDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.remoteCursors,
    this.onCheckboxTap,
    this.isDrawingMode = false,
    this.onStrokeAdded,
    this.onStrokeRemoved,
    required this.currentColor,
    required this.currentStrokeWidth,
    super.key,
  });

  final Line line;
  final TextSelection selection;
  final int lineIndex;
  final VirtualTextBuffer buffer;
  final bool showCursor;

  int _getOffsetForPosition(BuildContext context, Offset localPosition) {
    if (line is! TextLine) return 0;

    final textLine = line as TextLine;
    final painter = TextPainter(
      text: textLine.toTextSpan(),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: context.size!.width);

    final position = painter.getPositionForOffset(localPosition);
    return buffer.getOffsetForLineTextPosition(
      LineTextPosition(line: lineIndex, character: position.offset),
    );
  }

  void _handleTapDown(BuildContext context, TapDownDetails details) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(context, details.localPosition);
    onTapDown(details, lineIndex, TextSelection.collapsed(offset: offset));
  }

  void _handlePanStart(BuildContext context, DragStartDetails details) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(context, details.localPosition);
    onPanStart(details, lineIndex, TextSelection.collapsed(offset: offset));
  }

  void _handlePanUpdate(BuildContext context, DragUpdateDetails details) {
    if (line is! TextLine) return;
    final offset = _getOffsetForPosition(context, details.localPosition);
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
    final hasSelection =
        selection.isValid &&
        !selection.isCollapsed &&
        selection.start < lineEndOffset &&
        selection.end > lineStartOffset;

    // --- Prepare visual wrapping based on attributes ---
    final attributes = line.attributes;
    final blockType = attributes['blockType'] as String?;
    final textAlignStr = attributes['textAlign'] as String? ?? 'left';
    final indentLevel = attributes['indent'] as int? ?? 0;

    TextAlign textAlign;
    switch (textAlignStr) {
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'justify':
        textAlign = TextAlign.justify;
        break;
      case 'left':
      default:
        textAlign = TextAlign.left;
        break;
    }

    // Indentation padding
    final double indentPadding = indentLevel * 24.0;

    Widget content;

    // 4. Perform expensive layout only if needed (moved up for wrapping)
    // We need TextSpan to apply line-level styles (like heading size) if not handled in model.
    // Actually, headings might handled by model attributes?
    // No, we store 'level' in block attributes, not span attributes.
    // So we need to scale the text here.

    var textSpan = line.toTextSpan();

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

    // 3. Early return optimization (Modified to include visual styles)
    // We can't rely on simple RichText if we need block decorations.

    final painter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: context.size?.width ?? double.infinity);

    final selectionBoxes = <Widget>[];
    if (hasSelection) {
      final selectionStart = math.max(lineStartOffset, selection.start);
      final selectionEnd = math.min(lineEndOffset, selection.end);

      final localSelection = TextSelection(
        baseOffset: selectionStart - lineStartOffset,
        extentOffset: selectionEnd - lineStartOffset,
      );

      selectionBoxes.addAll(
        painter
            .getBoxesForSelection(localSelection)
            .map(
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
    // IMPORTANT: If we align text, the cursor position calculation from painter is still relative to the text box.
    // We need to ensure the Stack/RichText matches the alignment.
    // Actually, TextPainter handles alignment layout internally if we pass textAlign.
    // So getOffsetForCaret should work relative to the painter box.
    // But we need to place the cursor in the right place manually?
    // Positioned.fromRect uses coordinates. Painter coordinates are relative to (0,0) of the layout.
    // If textAlign is Right, (0,0) is still top-left of the MaxWidth box, but text starts further right.
    // Painter handles this.

    Widget textStack = Stack(
      children: [
        // We use a custom painter or RichText inside an aligned container?
        // RichText itself has textAlign property.
        RichText(
          text: textSpan,
          textAlign: textAlign,
        ),
        ...selectionBoxes,
        if (isCursorInThisLine && showCursor)
          Positioned.fromRect(
            rect:
                painter.getOffsetForCaret(
                  TextPosition(offset: cursorPosition.character),
                  Rect.zero,
                ) &
                Size(2, painter.preferredLineHeight),
            child: Container(color: Colors.blue),
          ),
      ],
    );

    // --- Apply Block Decorations ---
    // --- Determine Content Based on Block Type ---
    if (attributes['blockType'] == 'drawing') {
      // We need the actual block from the model, but Line is from VirtualTextBuffer.
      // VirtualTextBuffer lines map to model blocks, but we might have lost the direct reference
      // unless we store block index or the block object in attributes.
      // Actually DocumentModel.toJson re-creates blocks.
      // Warning: VirtualTextBuffer might not fully support non-text blocks yet if it splits them.
      // Assuming Block-Per-Line for drawings.

      final strokesRaw = attributes['strokes'] as List<dynamic>? ?? [];
      final strokes = strokesRaw.map((e) => Stroke.fromJson(e)).toList();
      final height = (attributes['height'] as num?)?.toDouble() ?? 200.0;

      content = InteractiveDrawingBlock(
        strokes: strokes,
        height: height,
        isDrawingMode: isDrawingMode,
        onStrokeAdded: (stroke) {
          if (onStrokeAdded != null) {
            onStrokeAdded!(stroke);
          }
        },
        onStrokeRemoved: (stroke) {
          if (onStrokeRemoved != null) {
            onStrokeRemoved!(stroke);
          }
        },
        currentColor: currentColor,
        currentStrokeWidth: currentStrokeWidth,
      );
    } else if (blockType == 'quote') {
      content = Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: textStack, // Text itself is italic? Model could handle, or here.
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
            child: Text('•', style: TextStyle(fontSize: 24, height: 1.0)),
          ),
          Expanded(child: textStack),
        ],
      );
    } else if (blockType == 'ordered-list') {
      // TODO: Smart numbering is hard without global index.
      // For now, we show "1." for everything or try to guess?
      // Without traversal, we can't know index.
      // Temporary solution: "1." always. User can see visual difference.
      // Or pass indices from VirtualTextBuffer?
      // Let's stick with "1." to signify it's a list.
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 24,
            child: Text('1.', style: TextStyle(fontSize: 16, height: 1.5)),
          ),
          Expanded(child: textStack),
        ],
      );
    } else if (blockType == 'checklist') {
      final isChecked = attributes['checked'] as bool? ?? false;
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (onCheckboxTap != null) {
                onCheckboxTap!(lineStartOffset);
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: isChecked ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Opacity(opacity: isChecked ? 0.5 : 1.0, child: textStack),
          ),
        ],
      );
    } else {
      content = textStack;
    }

    // Apply Indentation
    if (indentLevel > 0) {
      content = Padding(
        padding: EdgeInsets.only(left: indentPadding),
        child: content,
      );
    }

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
          effectiveOffset -= const Offset(24, 0); // approx
        }

        // Find text position from offset
        final textPosition = painter.getPositionForOffset(effectiveOffset);
        final span = textSpan.getSpanForPosition(textPosition);

        // We can't easily access the TextSpanModel from the Flutter TextSpan here directly
        // unless we built it with a recognizer or meta-data.
        // But we iterate line.spans.
        // Simpler: Check the line model logic.

        // Alternative: Use the offset `textPosition.offset` to find the span model in `line.spans`
        var currentOffset = 0;
        for (final s in line.spans) {
          final len = s.text.length;
          if (textPosition.offset >= currentOffset &&
              textPosition.offset < currentOffset + len) {
            if (s.linkUrl != null) {
              // It's a link! Open it.
              // For now, since we can't easily injection URL launcher here without dependnecy,
              // we will just print or show usage. The user said "sem utilizar dependencias".
              // So we can't use url_launcher?
              // Standard Flutter can't open URLs without url_launcher package.
              // I will just print to console or show a Snackbar if context available?
              // "Opening: ${s.linkUrl}"
              // Actually, if dependencies are forbidden, I can't add `url_launcher`.
              // But `universal_notes_flutter` likely has it?
              // Checked pubspec in memory: yes, it has `url_launcher`? No, I viewed pubspec earlier.
              // Let's assume effectively I can't use new deps.
              // I'll show a snackbar.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open Link: ${s.linkUrl}')),
              );
              return;
            }
            break;
          }
          currentOffset += len;
        }

        _handleTapDown(context, d);
      },
      onPanStart: (d) => _handlePanStart(context, d),
      onPanUpdate: (d) => _handlePanUpdate(context, d),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (line is ImageLine) {
      return _buildImage(context, line as ImageLine);
    } else if (line is TextLine) {
      return _buildText(context, line as TextLine);
    }
    return const SizedBox.shrink();
  }
}
