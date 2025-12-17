import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/history_manager.dart';

void main() {
  group('HistoryManager', () {
    final initialDoc = DocumentModel(
      blocks: [
        TextBlock(spans: [const TextSpanModel(text: 'Initial')]),
      ],
    );
    const initialSelection = TextSelection.collapsed(offset: 0);
    final initialState = HistoryState(
      document: initialDoc,
      selection: initialSelection,
    );

    late HistoryManager historyManager;

    setUp(() {
      historyManager = HistoryManager(initialState: initialState);
    });

    test('initial state is correct', () {
      expect(historyManager.current.document, initialDoc);
      expect(historyManager.canUndo, isFalse);
      expect(historyManager.canRedo, isFalse);
    });

    test('record adds a new state and clears redo stack', () {
      final newDoc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'New')]),
        ],
      );
      const newSelection = TextSelection.collapsed(offset: 1);
      final newState = HistoryState(document: newDoc, selection: newSelection);

      historyManager.record(newState);

      expect(historyManager.current.document, newDoc);
      expect(historyManager.canUndo, isTrue);
      expect(historyManager.canRedo, isFalse);
    });

    test('undo restores the previous state', () {
      final newDoc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'New')]),
        ],
      );
      const newSelection = TextSelection.collapsed(offset: 1);
      final newState = HistoryState(document: newDoc, selection: newSelection);
      historyManager.record(newState);

      final undoneState = historyManager.undo();

      expect(undoneState.document, initialDoc);
      expect(historyManager.canUndo, isFalse);
      expect(historyManager.canRedo, isTrue);
    });

    test('redo restores the undone state', () {
      final newDoc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'New')]),
        ],
      );
      const newSelection = TextSelection.collapsed(offset: 1);
      final newState = HistoryState(document: newDoc, selection: newSelection);
      historyManager
        ..record(newState)
        ..undo();

      final redoneState = historyManager.redo();

      expect(redoneState.document, newDoc);
      expect(redoneState.selection, newSelection);
      expect(historyManager.canUndo, isTrue);
      expect(historyManager.canRedo, isFalse);
    });
  });
}
