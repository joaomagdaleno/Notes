import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';

/// Represents a single snapshot in the editor's history.
class HistoryState {
  /// Creates a new instance of [HistoryState].
  const HistoryState({required this.document, required this.selection});

  /// The document state.
  final DocumentModel document;

  /// The selection state.
  final TextSelection selection;
}

/// Manages the undo/redo history for a [DocumentModel].
class HistoryManager {
  /// Creates a new instance of [HistoryManager].
  HistoryManager({required HistoryState initialState}) {
    _undoStack.add(initialState);
  }

  final List<HistoryState> _undoStack = [];
  final List<HistoryState> _redoStack = [];

  /// The current history state.
  HistoryState get current => _undoStack.last;

  /// Whether there is an action to undo.
  bool get canUndo => _undoStack.length > 1;

  /// Whether there is an action to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Records a new history state.
  ///
  /// This should be called when a user action (like typing) is completed.
  /// When a new state is recorded, the redo stack is cleared.
  void record(HistoryState state) {
    // Compare JSON representations to detect changes in style as well as text.
    if (DocumentAdapter.toJson(state.document) ==
        DocumentAdapter.toJson(current.document)) {
      return;
    }

    _undoStack.add(state);
    _redoStack.clear();
  }

  /// Undoes the last action and returns the previous history state.
  ///
  /// If there is nothing to undo, returns the current state.
  HistoryState undo() {
    if (!canUndo) return current;

    final last = _undoStack.removeLast();
    _redoStack.add(last);
    return current;
  }

  /// Redoes the last undone action and returns the restored history state.
  ///
  /// If there is nothing to redo, returns the current state.
  HistoryState redo() {
    if (_redoStack.isNotEmpty) {
      final state = _redoStack.removeLast();
      _undoStack.add(state);
      return state;
    }
    return current;
  }
}
