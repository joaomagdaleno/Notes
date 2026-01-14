import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/editor/document_manipulator.dart';
import 'package:notes_hub/editor/markdown_converter.dart';
import 'package:notes_hub/editor/remote_cursor.dart';
import 'package:notes_hub/editor/snippet_converter.dart';
import 'package:notes_hub/editor/virtual_text_buffer.dart';
import 'package:notes_hub/editor/widgets/editor_line.dart';
import 'package:notes_hub/editor/widgets/grid_painter.dart';
import 'package:notes_hub/editor/widgets/line_with_index.dart';
import 'package:notes_hub/editor/widgets/reading_fab_menu.dart';
import 'package:notes_hub/models/document_model.dart';
import 'package:notes_hub/models/note_event.dart';
import 'package:notes_hub/models/persona_model.dart';
import 'package:notes_hub/models/reading_annotation.dart';
import 'package:notes_hub/models/reading_settings.dart';
import 'package:notes_hub/models/reading_stats.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/services/autocomplete_service.dart';
import 'package:notes_hub/widgets/autocomplete_overlay.dart';
import 'package:notes_hub/widgets/reading_search_bar.dart';

/// A widget that provides a text editor with rich text capabilities.
class EditorWidget extends StatefulWidget {
  /// Creates a new instance of [EditorWidget].
  const EditorWidget({
    required this.document,
    required this.onDocumentChanged,
    required this.onSelectionChanged,
    this.initialPersona = EditorPersona.architect,
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
    this.onToggleList,
    this.onInsertLink,
    this.onLinkTap,
    this.onToggleLock,
    this.isDrawingMode = false,
    this.currentColor = Colors.black,
    this.currentStrokeWidth = 2,
    this.softWrap = true,
    this.readingSettings,
    this.onOpenReadingSettings,
    this.onOpenOutline,
    this.onOpenBookmarks,
    this.onAddBookmark,
    this.onScrollToTop,
    this.readAloudHighlightRange,
    this.annotations = const [],
    this.readingStats,
    this.onSetReadingGoal,
    this.onNextSmart,
    this.onPrevSmart,
    this.onNextPlanNote,
    this.onPrevPlanNote,
    this.onPersonaChanged,
    super.key,
  });

  /// The current stroke color for drawing.
  final Color currentColor;

  /// The current stroke width for drawing.
  final double currentStrokeWidth;

  /// The current document model.
  final DocumentModel document;

  /// The persona to start with.
  final EditorPersona initialPersona;

  /// Whether the editor is in drawing mode.
  final bool isDrawingMode;

  /// Whether lines should wrap when they exceed the width.
  final bool softWrap;

  /// Callback when the document changes.
  final ValueChanged<DocumentModel> onDocumentChanged;

  /// The current text selection.
  final TextSelection? selection;

  /// A map of remote cursors to display.
  /// A map of remote cursors to display.
  final Map<String, Map<String, dynamic>> remoteCursors;

  /// Callback when the selection changes.
  final ValueChanged<TextSelection> onSelectionChanged;

  /// Callback when the selection rectangle changes (e.g., for toolbar
  /// positioning).
  final ValueChanged<Rect?>? onSelectionRectChanged;

  /// Callback for editor events.
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

  /// Callback when a list toggle shortcut is pressed (Ctrl+L, Ctrl+Shift+L).
  final void Function(String listType)? onToggleList;

  /// Callback when the active persona changes.
  final ValueChanged<EditorPersona>? onPersonaChanged;

  /// Callback when insert link shortcut is pressed (Ctrl+K).
  final VoidCallback? onInsertLink;

  /// Callback when a link is tapped.
  final ValueChanged<String>? onLinkTap;

  /// Callback when toggle lock shortcut is pressed (Ctrl+E).
  final VoidCallback? onToggleLock;

  // --- Reading Mode (Zen/Liquid) ---

  /// Settings for the reading mode.
  final ReadingSettings? readingSettings;

  /// Callback when reading settings button is pressed.
  final VoidCallback? onOpenReadingSettings;

  /// Callback when outline button is pressed.
  final VoidCallback? onOpenOutline;

  /// Callback when bookmarks button is pressed.
  final VoidCallback? onOpenBookmarks;

  /// Callback when add bookmark button is pressed.
  final VoidCallback? onAddBookmark;

  /// Callback when scroll to top is pressed.
  final VoidCallback? onScrollToTop;

  /// Callback for smart navigation to next section.
  final VoidCallback? onNextSmart;

  /// Callback for smart navigation to previous section.
  final VoidCallback? onPrevSmart;

  /// Callback for next plan note.
  final VoidCallback? onNextPlanNote;

  /// Callback for previous plan note.
  final VoidCallback? onPrevPlanNote;

  /// Character range to highlight during read aloud (start, end).
  final (int, int)? readAloudHighlightRange;

  /// Current reading annotations for the note.
  final List<ReadingAnnotation> annotations;

  /// Current reading stats for the note.
  final ReadingStats? readingStats;

  /// Callback to set a reading goal.
  final ValueChanged<int>? onSetReadingGoal;

  @override
  State<EditorWidget> createState() => EditorWidgetState();
}

/// State for [EditorWidget].
class EditorWidgetState extends State<EditorWidget>
    implements TextInputClient, DeltaTextInputClient {
  late EditorPersona _activePersona;
  final FocusNode _focusNode = FocusNode();

  /// The focus node for the editor widget.
  FocusNode get focusNode => _focusNode;
  late TextSelection _selection;
  late VirtualTextBuffer _buffer;
  final Map<int, GlobalKey> _lineKeys = {};

  // Text Input System
  TextInputConnection? _textInputConnection;
  TextEditingValue _currentTextEditingValue = TextEditingValue.empty;

  // Autocomplete state
  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  int _selectedSuggestionIndex = 0;
  Timer? _autocompleteDebounce;

  // Cursor state
  bool _showCursor = true;
  Timer? _cursorTimer;

  // Reading Mode Search State
  bool _isReadingSearchVisible = false;
  String _readingSearchQuery = '';
  List<int> _readingSearchMatchOffsets = [];
  int _currentReadingSearchMatchIndex = 0;

  /// Gets the number of search matches found in reading mode.
  int get readingSearchMatchCount => _readingSearchMatchOffsets.length;

  @override
  void initState() {
    super.initState();
    _activePersona = widget.initialPersona;
    _selection = widget.selection ?? const TextSelection.collapsed(offset: 0);
    _buffer = VirtualTextBuffer(widget.document);
    _generateKeys();
    _startCursorTimer();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openTextInputConnection();
    } else {
      _closeTextInputConnection();
    }
  }

  void _openTextInputConnection() {
    if (_textInputConnection != null && _textInputConnection!.attached) {
      return;
    }
    _updateCurrentTextEditingValue();
    _textInputConnection = TextInput.attach(
      this,
      const TextInputConfiguration(
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableDeltaModel: true,
      ),
    );
    _textInputConnection!.setEditingState(_currentTextEditingValue);
    _textInputConnection!.show();
  }

  void _closeTextInputConnection() {
    _textInputConnection?.close();
    _textInputConnection = null;
  }

  void _updateCurrentTextEditingValue() {
    final text = widget.document.toPlainText();
    _currentTextEditingValue = TextEditingValue(
      text: text,
      selection: _selection,
    );
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
      // Sync text input connection with new document
      _updateCurrentTextEditingValue();
      _textInputConnection?.setEditingState(_currentTextEditingValue);
    }
    if (widget.initialPersona != oldWidget.initialPersona) {
      setState(() {
        _activePersona = widget.initialPersona;
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
      // Sync text input connection with new selection
      _updateCurrentTextEditingValue();
      _textInputConnection?.setEditingState(_currentTextEditingValue);
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
    _focusNode.removeListener(_onFocusChanged);
    _closeTextInputConnection();
    _focusNode.dispose();
    _autocompleteDebounce?.cancel();
    _cursorTimer?.cancel();
    _hideAutocomplete();
    super.dispose();
  }

  // --- TextInputClient Implementation ---

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => _currentTextEditingValue;

  @override
  void updateEditingValue(TextEditingValue value) {
    // Handle text changes from the input method
    final oldText = _currentTextEditingValue.text;
    final newText = value.text;

    if (oldText == newText) {
      // Selection change only
      if (value.selection != _selection) {
        setState(() {
          _selection = value.selection;
        });
        _onSelectionChanged(value.selection);
      }
      _currentTextEditingValue = value;
      return;
    }

    // Text has changed - determine what was inserted or deleted
    final oldLength = oldText.length;
    final newLength = newText.length;

    if (newLength > oldLength) {
      // Text was inserted
      final insertionStart =
          value.selection.baseOffset - (newLength - oldLength);
      final insertedText = newText.substring(
        insertionStart,
        insertionStart + (newLength - oldLength),
      );

      // Learn words passively when typing word boundaries
      if (AutocompleteService.isWordBoundary(insertedText) &&
          insertionStart > 0) {
        var start = insertionStart;
        while (start > 0 &&
            !AutocompleteService.isWordBoundary(oldText[start - 1])) {
          start--;
        }
        if (insertionStart > start) {
          final word = oldText.substring(start, insertionStart);
          if (word.trim().isNotEmpty) {
            unawaited(NoteRepository.instance.learnWord(word));
          }
        }
      }

      // Apply the insertion to the document
      final result = DocumentManipulator.insertText(
        widget.document,
        insertionStart,
        insertedText,
      );
      widget.onEvent?.call(result.eventType, result.eventPayload);

      _currentTextEditingValue = value;
      _selection = value.selection;

      // Run post-edit actions (snippets, markdown, autocomplete)
      _runPostEditActions(result.document, value.selection);
    } else if (newLength < oldLength) {
      // Text was deleted
      final deletionLength = oldLength - newLength;
      final deletionStart = value.selection.baseOffset;

      final result = DocumentManipulator.deleteText(
        widget.document,
        deletionStart,
        deletionLength,
      );
      widget.onEvent?.call(result.eventType, result.eventPayload);

      _currentTextEditingValue = value;
      _selection = value.selection;

      widget.onDocumentChanged(result.document);
      _onSelectionChanged(value.selection);
    }
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    // Handle delta-based text input (preferred for IME)
    for (final delta in textEditingDeltas) {
      if (delta is TextEditingDeltaInsertion) {
        // Learn words passively
        final insertedText = delta.textInserted;
        final insertionOffset = delta.insertionOffset;
        final currentText = widget.document.toPlainText();

        if (AutocompleteService.isWordBoundary(insertedText) &&
            insertionOffset > 0) {
          var start = insertionOffset;
          while (start > 0 &&
              !AutocompleteService.isWordBoundary(currentText[start - 1])) {
            start--;
          }
          if (insertionOffset > start) {
            final word = currentText.substring(start, insertionOffset);
            if (word.trim().isNotEmpty) {
              unawaited(NoteRepository.instance.learnWord(word));
            }
          }
        }

        final result = DocumentManipulator.insertText(
          widget.document,
          insertionOffset,
          insertedText,
        );
        widget.onEvent?.call(result.eventType, result.eventPayload);

        final newSelection = TextSelection.collapsed(
          offset: insertionOffset + insertedText.length,
        );
        _selection = newSelection;
        _updateCurrentTextEditingValue();
        _textInputConnection?.setEditingState(_currentTextEditingValue);

        _runPostEditActions(result.document, newSelection);
      } else if (delta is TextEditingDeltaDeletion) {
        final deleteStart = delta.deletedRange.start;
        final deleteLength = delta.deletedRange.end - delta.deletedRange.start;

        final result = DocumentManipulator.deleteText(
          widget.document,
          deleteStart,
          deleteLength,
        );
        widget.onEvent?.call(result.eventType, result.eventPayload);

        final newSelection = TextSelection.collapsed(offset: deleteStart);
        _selection = newSelection;

        widget.onDocumentChanged(result.document);
        _onSelectionChanged(newSelection);
        _updateCurrentTextEditingValue();
        _textInputConnection?.setEditingState(_currentTextEditingValue);
      } else if (delta is TextEditingDeltaReplacement) {
        // Handle replacement (selection + insert)
        final deleteStart = delta.replacedRange.start;
        final deleteLength =
            delta.replacedRange.end - delta.replacedRange.start;

        final deleteResult = DocumentManipulator.deleteText(
          widget.document,
          deleteStart,
          deleteLength,
        );
        widget.onEvent?.call(deleteResult.eventType, deleteResult.eventPayload);

        final insertResult = DocumentManipulator.insertText(
          deleteResult.document,
          deleteStart,
          delta.replacementText,
        );
        widget.onEvent?.call(insertResult.eventType, insertResult.eventPayload);

        final newSelection = TextSelection.collapsed(
          offset: deleteStart + delta.replacementText.length,
        );
        _selection = newSelection;

        _runPostEditActions(insertResult.document, newSelection);
        _updateCurrentTextEditingValue();
        _textInputConnection?.setEditingState(_currentTextEditingValue);
      } else if (delta is TextEditingDeltaNonTextUpdate) {
        // Selection/composing region change only
        _selection = delta.selection;
        _onSelectionChanged(delta.selection);
      }
    }
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) {
      // Insert a newline
      final result = DocumentManipulator.insertText(
        widget.document,
        _selection.start,
        '\n',
      );
      widget.onEvent?.call(result.eventType, result.eventPayload);

      final newSelection = TextSelection.collapsed(
        offset: _selection.start + 1,
      );
      _selection = newSelection;
      _runPostEditActions(result.document, newSelection);
      _updateCurrentTextEditingValue();
      _textInputConnection?.setEditingState(_currentTextEditingValue);
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // Not used
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // Not used
  }

  @override
  void connectionClosed() {
    // Connection closed by system
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // Not used on desktop
  }

  @override
  void insertTextPlaceholder(Size size) {
    // Not used
  }

  @override
  void removeTextPlaceholder() {
    // Not used
  }

  @override
  void showToolbar() {
    // Not used
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    // Handle content insertion (e.g., images from keyboard)
    // Not implemented for this editor
  }

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {
    // Input control changed
  }

  @override
  void performSelector(String selectorName) {
    // Platform-specific selector (macOS)
  }

  void _onSelectionChanged(TextSelection newSelection) {
    setState(() {
      _selection = newSelection;
    });
    widget.onSelectionChanged(newSelection);
    _notifySelectionRectChanged(newSelection);
    // Sync with text input connection
    _updateCurrentTextEditingValue();
    _textInputConnection?.setEditingState(_currentTextEditingValue);
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

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
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
        widget.onSelectionChanged.call(_selection);
        setState(() {});
        return;
      }

      // List shortcuts
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        if (isShiftPressed) {
          // Ctrl+Shift+L: Toggle ordered list
          widget.onToggleList?.call('ordered');
        } else {
          // Ctrl+L: Toggle bullet list
          widget.onToggleList?.call('bullet');
        }
        return;
      }

      // Insert link shortcut (Ctrl+K)
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        widget.onInsertLink?.call();
        return;
      }

      // Toggle lock shortcut (Ctrl+E)
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        widget.onToggleLock?.call();
        return;
      }
    }

    // Escape key - exit focus mode or close overlays
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onEscape?.call();
      return;
    }

    // --- Navigation Keys ---
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_selection.baseOffset > 0) {
        final newOffset = isShiftPressed
            ? _selection.extentOffset - 1
            : math.max(
                0,
                _selection.start - (isCtrlPressed ? 5 : 1),
              ); // Simple ctrl+jump
        final newSelection = isShiftPressed
            ? _selection.copyWith(extentOffset: newOffset)
            : TextSelection.collapsed(offset: newOffset);
        _onSelectionChanged(newSelection);
        return;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final textLength = widget.document.toPlainText().length;
      if (_selection.extentOffset < textLength) {
        final newOffset = isShiftPressed
            ? _selection.extentOffset + 1
            : math.min(textLength, _selection.end + (isCtrlPressed ? 5 : 1));
        final newSelection = isShiftPressed
            ? _selection.copyWith(extentOffset: newOffset)
            : TextSelection.collapsed(offset: newOffset);
        _onSelectionChanged(newSelection);
        return;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Vertical navigation is complex with custom line height,
      // handled by Selection logic usually.
      // For now, let the key event propagate to potential parent
      // or just returned to avoid "a" typing.
      return;
    }

    // Note: Text input (characters, backspace, etc.) is now handled
    // by the TextInputClient implementation via updateEditingValueWithDeltas.
    // KeyboardListener is kept for shortcuts and navigation.
    _hideAutocomplete();
    return;
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
    final line =
        _buffer.getLineTextPositionForOffset(_selection.baseOffset).line;
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
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          // Dispatch view based on active persona
          _buildEditorContent(),
          ..._buildRemoteCursors(),
        ],
      ),
    );
  }

  /// Dispatches to the appropriate view builder based on active persona.
  Widget _buildEditorContent() {
    switch (_activePersona) {
      case EditorPersona.architect:
        return _buildArchitectView();
      case EditorPersona.writer:
        return _buildWriterView();
      case EditorPersona.brainstorm:
        return _buildBrainstormView();
      case EditorPersona.reading:
        return _buildReadingView();
    }
  }

  Widget _buildArchitectView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _focusNode.requestFocus();
        // Move cursor to the end of the document if tapped in empty area
        final textLength = widget.document.toPlainText().length;
        _onSelectionChanged(TextSelection.collapsed(offset: textLength));
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _buffer.lines.length,
              itemBuilder: (context, index) => _buildEditorLine(index),
            ),
          ),
        ),
      ),
    );
  }

  /// Writer mode: Paginated document view.
  Widget _buildWriterView() {
    const pageWidth = 595.0; // A4 width in points
    const pageHeight = 842.0; // A4 height in points
    const contentHeightPerPage = pageHeight - (60.0 * 2); // margins

    final pages = _splitLinesIntoPages(contentHeightPerPage);
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            children: pages.map((pageLines) {
              return Container(
                width: pageWidth,
                constraints: const BoxConstraints(minHeight: pageHeight),
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.canvasColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pageLines
                      .map((item) => _buildEditorLine(item.index))
                      .toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Groups lines into pages based on estimated height.
  List<List<LineWithIndex>> _splitLinesIntoPages(double maxHeight) {
    final pages = <List<LineWithIndex>>[];
    var currentPage = <LineWithIndex>[];
    var currentHeight = 0.0;

    for (var i = 0; i < _buffer.lines.length; i++) {
      final line = _buffer.lines[i];
      // Estimate line height
      var lineHeight = 24.0; // Standard text line
      if (line is ImageLine) lineHeight = 200.0;
      // Note: DrawingBlock is currently not in _buffer.lines
      if (line is TableLine) {
        lineHeight = 40.0 + (line.rows.length * 30.0);
      }
      if (line is MathLine) lineHeight = 60.0;

      // Check if it fits in current page
      if (currentHeight + lineHeight > maxHeight && currentPage.isNotEmpty) {
        pages.add(currentPage);
        currentPage = [];
        currentHeight = 0.0;
      }

      currentPage.add(LineWithIndex(line, i));
      currentHeight += lineHeight;
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    return pages.isEmpty ? [[]] : pages;
  }

  /// Brainstorm mode: Free-form canvas.
  Widget _buildBrainstormView() {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.only(top: 60),
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(500),
        minScale: 0.5,
        maxScale: 3,
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: Stack(
            children: [
              // Grid background
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              // Blocks positioned based on layoutMetadata
              ...List.generate(_buffer.lines.length, (index) {
                final line = _buffer.lines[index];
                // Get position from layoutMetadata if available
                var x = 100 + (index % 3) * 350.0;
                var y = 100 + (index ~/ 3) * 200.0;

                final block = (widget.document.blocks.isNotEmpty &&
                        index < widget.document.blocks.length)
                    ? widget.document.blocks[index]
                    : null;

                if (block != null) {
                  x = (block.layoutMetadata['x'] as num?)?.toDouble() ?? x;
                  y = (block.layoutMetadata['y'] as num?)?.toDouble() ?? y;
                }

                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      if (block == null) return;
                      final currentMetadata = Map<String, dynamic>.from(
                        block.layoutMetadata,
                      );
                      currentMetadata['x'] = x + details.delta.dx;
                      currentMetadata['y'] = y + details.delta.dy;

                      final result = DocumentManipulator.updateBlockLayout(
                        widget.document,
                        index,
                        currentMetadata,
                      );
                      widget.onDocumentChanged(result.document);
                    },
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: line is TextLine
                          ? Text.rich(
                              TextSpan(
                                children: line.spans
                                    .map(
                                      (s) => s.toTextSpan(
                                        onLinkTap: widget.onLinkTap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                          : EditorLine(
                              key: _lineKeys[index],
                              line: line,
                              lineIndex: index,
                              selection: _selection,
                              buffer: _buffer,
                              showCursor: _showCursor,
                              onTapDown: _handleTapDown,
                              onPanStart: _handlePanStart,
                              onPanUpdate: _handlePanUpdate,
                              remoteCursors: widget.remoteCursors.values.where((
                                c,
                              ) {
                                final sel =
                                    c['selection'] as Map<String, dynamic>;
                                final base = sel['base'] as int;
                                final extent = sel['extent'] as int;
                                final lineStart =
                                    _buffer.getOffsetForLineTextPosition(
                                  LineTextPosition(
                                    line: index,
                                    character: 0,
                                  ),
                                );
                                final lineEnd = lineStart +
                                    (line is TextLine
                                        ? line.toPlainText().length
                                        : 1);
                                return (base >= lineStart && base <= lineEnd) ||
                                    (extent >= lineStart && extent <= lineEnd);
                              }).toList(),
                              currentColor: widget.currentColor,
                              currentStrokeWidth: widget.currentStrokeWidth,
                              isDrawingMode: widget.isDrawingMode,
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Reading mode: Distraction-free reading with Liquid Mode features.
  Widget _buildReadingView() {
    final settings = widget.readingSettings ?? ReadingSettings.defaults;
    final theme = settings.theme;

    // Apply night light filter
    var content = _buildReadingContent(settings);
    if (settings.nightLightEnabled) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.orange.withValues(alpha: settings.nightLightIntensity * 0.3),
          BlendMode.multiply,
        ),
        child: content,
      );
    }

    return ColoredBox(
      color: theme.backgroundColor,
      child: Stack(
        children: [
          // Main content
          Column(
            children: [
              if (widget.readingStats != null &&
                  widget.readingStats!.readingGoalMinutes > 0)
                _buildReadingGoalProgress(),
              if (_isReadingSearchVisible)
                ReadingSearchBar(
                  onFindChanged: _onReadingSearchChanged,
                  onFindNext: _onReadingSearchNext,
                  onFindPrevious: _onReadingSearchPrev,
                  onClose: _onReadingSearchClose,
                  resultsCount: _readingSearchMatchOffsets.length,
                  currentIndex: _currentReadingSearchMatchIndex,
                ),
              Expanded(child: content),
            ],
          ),

          // FAB menu for reading controls
          Positioned(
            right: 16,
            bottom: 16,
            child: ReadingFabMenu(
              onSettingsTap: widget.onOpenReadingSettings,
              onOutlineTap: widget.onOpenOutline,
              onBookmarksTap: widget.onOpenBookmarks,
              onAddBookmarkTap: widget.onAddBookmark,
              onScrollToTopTap: widget.onScrollToTop,
              onNextTap: widget.onNextSmart,
              onPrevTap: widget.onPrevSmart,
              onNextPlanNote: widget.onNextPlanNote,
              onPrevPlanNote: widget.onPrevPlanNote,
              onSearchTap: () {
                setState(() {
                  _isReadingSearchVisible = !_isReadingSearchVisible;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingContent(ReadingSettings settings) {
    final textStyle = TextStyle(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      letterSpacing: settings.letterSpacing,
      color: settings.theme.textColor,
      fontFamily: settings.fontFamily == 'Default' ? null : settings.fontFamily,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 80,
            bottom: 100,
          ),
          itemCount: _buffer.lines.length,
          itemBuilder: (context, index) {
            final line = _buffer.lines[index];
            final lineStartGlobal = _buffer.getOffsetForLineTextPosition(
              LineTextPosition(line: index, character: 0),
            );
            final lineLength = line is TextLine ? line.toPlainText().length : 1;
            final lineEndGlobal = lineStartGlobal + lineLength;

            // Check if this range has a note (comment)
            final noteAnnotations = widget.annotations
                .where(
                  (a) =>
                      a.comment != null &&
                      a.startOffset < lineEndGlobal &&
                      a.endOffset > lineStartGlobal,
                )
                .toList();

            Widget content;
            if (line is TextLine) {
              content = Padding(
                padding: EdgeInsets.symmetric(
                  vertical: settings.paragraphSpacing / 2,
                ),
                child: Text.rich(
                  TextSpan(
                    children: _buildReadingTextSpans(
                      line,
                      index,
                      settings,
                      widget.readAloudHighlightRange,
                    ),
                  ),
                  style: textStyle,
                  textAlign: settings.textAlign,
                ),
              );
            } else if (line is ImageLine) {
              content = Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: EditorLine(
                    key: ValueKey('reading_line_$index'),
                    line: line,
                    lineIndex: index,
                    selection: const TextSelection.collapsed(offset: 0),
                    buffer: _buffer,
                    showCursor: false,
                    onTapDown: (a, b, c) {},
                    onPanStart: (a, b, c) {},
                    onPanUpdate: (a, b, c) {},
                    remoteCursors: const [],
                    currentColor: Colors.black,
                    currentStrokeWidth: 2,
                  ),
                ),
              );
            } else {
              content = EditorLine(
                key: ValueKey('reading_line_$index'),
                line: line,
                lineIndex: index,
                selection: const TextSelection.collapsed(offset: 0),
                buffer: _buffer,
                showCursor: false,
                onTapDown: (a, b, c) {},
                onPanStart: (a, b, c) {},
                onPanUpdate: (a, b, c) {},
                remoteCursors: const [],
                currentColor: Colors.black,
                currentStrokeWidth: 2,
              );
            }

            if (noteAnnotations.isEmpty) return content;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                content,
                Positioned(
                  right: -32,
                  top: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.note,
                      size: 20,
                      color: settings.theme.accentColor,
                    ),
                    onPressed: () {
                      _showNoteDetails(context, noteAnnotations);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadingGoalProgress() {
    final stats = widget.readingStats!;
    final goalMinutes = stats.readingGoalMinutes;
    final currentTimeSeconds = stats.totalReadingTimeSeconds;
    final currentMinutes = currentTimeSeconds / 60;
    final progress = math.min<double>(1, currentMinutes / goalMinutes);
    final remaining = math.max(0, goalMinutes - currentMinutes.toInt());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: widget.readingSettings?.theme.backgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Goal: ${currentMinutes.toInt()}/$goalMinutes min',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.readingSettings?.theme.textColor.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              if (remaining > 0)
                Text(
                  '$remaining min remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.readingSettings?.theme.textColor.withValues(
                      alpha: 0.7,
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: widget.readingSettings?.theme.textColor.withValues(
              alpha: 0.1,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.readingSettings?.theme.accentColor ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showNoteDetails(
    BuildContext context,
    List<ReadingAnnotation> annotations,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Margin Notes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ...annotations.map(
                  (a) => ListTile(
                    leading: const Icon(Icons.sticky_note_2),
                    title: Text(a.comment ?? ''),
                    subtitle: Text(
                      'Ref: "${a.textExcerpt ?? "..."}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // We need a callback to NoteEditorScreen to delete
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<InlineSpan> _buildReadingTextSpans(
    TextLine line,
    int lineIndex,
    ReadingSettings settings,
    (int, int)? highlightRange,
  ) {
    final spans = <InlineSpan>[];
    final lineStartGlobal = _buffer.getOffsetForLineTextPosition(
      LineTextPosition(line: lineIndex, character: 0),
    );
    var currentOffset = 0;

    for (final span in line.spans) {
      final spanText = span.text;
      final spanEnd = currentOffset + spanText.length;
      final spanStartGlobal = lineStartGlobal + currentOffset;
      final spanEndGlobal = lineStartGlobal + spanEnd;

      // Check for reading annotations
      final annotation = widget.annotations.firstWhere(
        (a) => a.startOffset < spanEndGlobal && a.endOffset > spanStartGlobal,
        orElse: () => ReadingAnnotation(
          id: '',
          noteId: '',
          startOffset: 0,
          endOffset: 0,
          createdAt: DateTime.now(),
        ),
      );

      final hasAnnotation = annotation.id.isNotEmpty;
      final annotationColor = hasAnnotation
          ? Color(annotation.color ?? Colors.yellow.toARGB32()).withValues(
              alpha: 0.3,
            )
          : null;

      // Check for read aloud highlight
      if (highlightRange != null) {
        final (hlStart, hlEnd) = highlightRange;
        if (spanStartGlobal < hlEnd && spanEndGlobal > hlStart) {
          final localStart = math.max(0, hlStart - spanStartGlobal);
          final localEnd = math.min(spanText.length, hlEnd - spanStartGlobal);

          // Before highlight
          if (localStart > 0) {
            spans.add(
              TextSpan(
                text: spanText.substring(0, localStart),
                style: span.toTextSpan().style?.copyWith(
                      backgroundColor: annotationColor,
                    ),
              ),
            );
          }

          // Highlighted portion
          if (localStart < localEnd) {
            spans.add(
              TextSpan(
                text: spanText.substring(localStart, localEnd),
                style: span.toTextSpan().style?.copyWith(
                      backgroundColor: settings.theme.accentColor.withValues(
                        alpha: 0.5,
                      ),
                    ),
              ),
            );
          }

          // After highlight
          if (localEnd < spanText.length) {
            spans.add(
              TextSpan(
                text: spanText.substring(localEnd),
                style: span.toTextSpan().style?.copyWith(
                      backgroundColor: annotationColor,
                    ),
              ),
            );
          }

          currentOffset = spanEnd;
          continue;
        }
      }

      // No read aloud highlight, check for annotation and search highlights
      final matchStart = _readingSearchMatchOffsets.firstWhere(
        (offset) =>
            offset < spanEndGlobal &&
            offset + _readingSearchQuery.length > spanStartGlobal,
        orElse: () => -1,
      );

      if (matchStart != -1) {
        final localStart = math.max(0, matchStart - spanStartGlobal);
        final localEnd = math.min(
          spanText.length,
          matchStart + _readingSearchQuery.length - spanStartGlobal,
        );
        final isCurrentMatch = matchStart ==
            (_readingSearchMatchOffsets.isNotEmpty
                ? _readingSearchMatchOffsets[_currentReadingSearchMatchIndex]
                : -1);

        final highlightColor = isCurrentMatch
            ? Colors.orange.withValues(alpha: 0.6)
            : Colors.yellow.withValues(alpha: 0.4);

        if (localStart > 0) {
          spans.add(
            TextSpan(
              text: spanText.substring(0, localStart),
              style: span.toTextSpan().style?.copyWith(
                    backgroundColor: annotationColor,
                  ),
            ),
          );
        }

        spans.add(
          TextSpan(
            text: spanText.substring(localStart, localEnd),
            style: span.toTextSpan().style?.copyWith(
                  backgroundColor: highlightColor,
                ),
          ),
        );

        if (localEnd < spanText.length) {
          spans.add(
            TextSpan(
              text: spanText.substring(localEnd),
              style: span.toTextSpan().style?.copyWith(
                    backgroundColor: annotationColor,
                  ),
            ),
          );
        }
      } else if (hasAnnotation) {
        spans.add(
          TextSpan(
            text: spanText,
            style: span.toTextSpan().style?.copyWith(
                  backgroundColor: annotationColor,
                ),
          ),
        );
      } else {
        spans.add(span.toTextSpan(onLinkTap: widget.onLinkTap) as InlineSpan);
      }

      currentOffset = spanEnd;
    }

    return spans;
  }

  // Reading Mode Search Logic
  void _onReadingSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _readingSearchQuery = '';
        _readingSearchMatchOffsets = [];
        _currentReadingSearchMatchIndex = 0;
      });
      return;
    }

    final text = widget.document.toPlainText().toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <int>[];
    var index = text.indexOf(lowerQuery);
    while (index != -1) {
      matches.add(index);
      index = text.indexOf(lowerQuery, index + lowerQuery.length);
    }

    setState(() {
      _readingSearchQuery = query;
      _readingSearchMatchOffsets = matches;
      _currentReadingSearchMatchIndex = 0;
    });

    if (matches.isNotEmpty) {
      _scrollToReadingMatch(matches[0]);
    }
  }

  void _onReadingSearchNext() {
    if (_readingSearchMatchOffsets.isEmpty) return;
    setState(() {
      _currentReadingSearchMatchIndex = (_currentReadingSearchMatchIndex + 1) %
          _readingSearchMatchOffsets.length;
    });
    _scrollToReadingMatch(
      _readingSearchMatchOffsets[_currentReadingSearchMatchIndex],
    );
  }

  void _onReadingSearchPrev() {
    if (_readingSearchMatchOffsets.isEmpty) return;
    setState(() {
      _currentReadingSearchMatchIndex = (_currentReadingSearchMatchIndex -
              1 +
              _readingSearchMatchOffsets.length) %
          _readingSearchMatchOffsets.length;
    });
    _scrollToReadingMatch(
      _readingSearchMatchOffsets[_currentReadingSearchMatchIndex],
    );
  }

  void _onReadingSearchClose() {
    setState(() {
      _isReadingSearchVisible = false;
      _readingSearchQuery = '';
      _readingSearchMatchOffsets = [];
      _currentReadingSearchMatchIndex = 0;
    });
  }

  void _scrollToReadingMatch(int offset) {
    final targetLineIndex = _buffer.getLineTextPositionForOffset(offset).line;
    final scrollOffset = targetLineIndex *
        (widget.readingSettings?.fontSize ?? 18) *
        (widget.readingSettings?.lineHeight ?? 1.6);

    unawaited(
      widget.scrollController?.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Builds a single editor line widget.
  Widget _buildEditorLine(int index) {
    final line = _buffer.lines[index];
    final cursorsOnLine = widget.remoteCursors.entries
        .where((entry) {
          final data = entry.value;
          final selectionData = data['selection'] as Map<String, dynamic>?;
          if (selectionData == null) return false;
          final base = selectionData['base'] as int?;
          final extent = selectionData['extent'] as int?;
          if (base == null || extent == null) return false;

          final remoteSelection = TextSelection(
            baseOffset: base,
            extentOffset: extent,
          );
          final lineStartOffset = _buffer.getOffsetForLineTextPosition(
            LineTextPosition(line: index, character: 0),
          );
          final lineLength = line is TextLine ? line.toPlainText().length : 1;
          final lineEndOffset = lineStartOffset + lineLength;

          return remoteSelection.start < lineEndOffset &&
              remoteSelection.end > lineStartOffset;
        })
        .map((e) => e.value)
        .toList();

    final cursorLine =
        _buffer.getLineTextPositionForOffset(_selection.baseOffset).line;
    final isCurrentLine = cursorLine == index;

    return EditorLine(
      key: _lineKeys[index],
      line: line,
      lineIndex: index,
      selection: _selection,
      buffer: _buffer,
      showCursor: _showCursor,
      isCurrentLine: isCurrentLine,
      onTapDown: _handleTapDown,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      remoteCursors: cursorsOnLine,
      onCheckboxTap: widget.onCheckboxTap,
      isDrawingMode: widget.isDrawingMode,
      onStrokeAdded: (stroke) {
        final blockIndex = index;
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
      softWrap: widget.softWrap,
      onLinkTap: widget.onLinkTap,
    );
  }

  /// Builds the remote cursors overlay.
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
