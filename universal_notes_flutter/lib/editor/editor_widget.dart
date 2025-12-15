import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';
import 'package:universal_notes_flutter/editor/snippet_converter.dart';
import 'package:universal_notes_flutter/services/autocomplete_service.dart';
import 'package:universal_notes_flutter/widgets/autocomplete_overlay.dart';

class EditorWidget extends StatefulWidget {
  const EditorWidget({
    required this.document,
    required this.onDocumentChanged,
    required this.onSelectionChanged,
    this.selection,
    super.key,
  });

  final DocumentModel document;
  final ValueChanged<DocumentModel> onDocumentChanged;
  final TextSelection? selection;
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

  // Autocomplete state
  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  int _selectedSuggestionIndex = 0;
  Timer? _autocompleteDebounce;

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
    _autocompleteDebounce?.cancel();
    _hideAutocomplete();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    // --- Autocomplete Keyboard Interaction ---
    if (_autocompleteOverlay != null) {
      if (event.logicalKey == LogicalKey.arrowDown) {
        setState(() {
          _selectedSuggestionIndex = (_selectedSuggestionIndex + 1) % _suggestions.length;
        });
        _showAutocomplete(); // Rebuild the overlay with the new selection
        return;
      } else if (event.logicalKey == LogicalKey.arrowUp) {
         setState(() {
          _selectedSuggestionIndex = (_selectedSuggestionIndex - 1 + _suggestions.length) % _suggestions.length;
        });
        _showAutocomplete();
        return;
      } else if (event.logicalKey == LogicalKey.tab || event.logicalKey == LogicalKey.enter) {
        if (_suggestions.isNotEmpty) {
          _acceptAutocomplete(_suggestions[_selectedSuggestionIndex]);
        }
        return;
      } else if (event.logicalKey == LogicalKey.escape) {
        _hideAutocomplete();
        return;
      }
    }

    DocumentModel docAfterEdit;
    TextSelection selectionAfterEdit;

    // --- Basic Text Editing ---
    if (event.logicalKey == LogicalKey.backspace) {
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
      _updateAutocomplete(doc, selection);
    });

    // --- Snippets & Markdown ---
    final snippetResult = SnippetConverter.checkAndApply(doc, selection);
    if (snippetResult != null) {
      widget.onDocumentChanged(snippetResult.document);
      widget.onSelectionChanged(snippetResult.selection);
      return;
    }

    final markdownResult = MarkdownConverter.checkAndApply(doc, selection);
    if (markdownResult != null) {
      widget.onDocumentChanged(markdownResult.document);
      widget.onSelectionChanged(markdownResult.selection);
      return;
    }

    // If no conversion, just apply the basic edit.
    widget.onDocumentChanged(doc);
    widget.onSelectionChanged(selection);
  }

  // --- Autocomplete Logic ---
  Future<void> _updateAutocomplete(DocumentModel document, TextSelection selection) async {
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

  void _showAutocomplete() {
    _hideAutocomplete(); // Remove existing overlay before showing a new one
    final overlay = Overlay.of(context);
    _autocompleteOverlay = OverlayEntry(
      builder: (context) => AutocompleteOverlay(
        suggestions: _suggestions,
        selectedIndex: _selectedSuggestionIndex,
        position: _getCursorOffset() + const Offset(0, 20), // Position below cursor
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
    int start = _selection.baseOffset;
    while (start > 0 && !AutocompleteService.isWordBoundary(plainText[start - 1])) {
      start--;
    }
    final wordInProgress = plainText.substring(start, _selection.baseOffset);

    final docAfterDelete = DocumentManipulator.deleteText(widget.document, start, wordInProgress.length);
    final newDoc = DocumentManipulator.insertText(docAfterDelete, start, suggestion);
    final newSelection = TextSelection.collapsed(offset: start + suggestion.length);

    widget.onDocumentChanged(newDoc);
    widget.onSelectionChanged(newSelection);
    _hideAutocomplete();
  }


  // --- UI and Gesture Handling ---
  // ... (methods remain the same)
  void _updateTextPainter() {
    _textPainter.text = widget.document.toTextSpan();
    _textPainter.layout(minWidth: 0, maxWidth: MediaQuery.of(context).size.width);
  }

  Offset _getCursorOffset() {
    if (widget.document.toPlainText().isEmpty) return Offset.zero;
    _updateTextPainter();
    return _textPainter.getOffsetForCaret(
      TextPosition(offset: _selection.extentOffset),
      Rect.zero,
    );
  }

   void _handleTapDown(TapDownDetails details) {
    _focusNode.requestFocus();
    _hideAutocomplete();
    _updateTextPainter();
    final position = _textPainter.getPositionForOffset(details.localPosition);
    final newSelection = TextSelection.collapsed(offset: position.offset);
    widget.onSelectionChanged(newSelection);
    setState(() => _showCursor = true);
  }
   void _handlePanStart(DragStartDetails details) {
     _focusNode.requestFocus();
    _hideAutocomplete();
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
    final boxes = _textPainter.getBoxesForSelection(_selection);
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
            RichText(text: widget.document.toTextSpan()),
            ..._buildSelectionHighlights(),
            if (_focusNode.hasFocus && _showCursor && _selection.isCollapsed)
              Positioned(
                left: _getCursorOffset().dx,
                top: _getCursorOffset().dy,
                child: Container(width: 2, height: 20, color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}
