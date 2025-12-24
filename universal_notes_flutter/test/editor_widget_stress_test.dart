@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';

// Helper to generate a very long document.
DocumentModel _generateLongDocument(int wordCount) {
  final longText = List.generate(wordCount, (index) => 'word$index ').join();
  return DocumentAdapter.fromJson(
    '[{"type":"text","spans":[{"text":"$longText"}]}]',
  );
}

void main() {
  group('EditorWidget Stress Tests', () {
    testWidgets('should render a 50,000-word document without crashing', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final longDocument = _generateLongDocument(50000);
      var document = longDocument;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorWidget(
              document: document,
              onDocumentChanged: (newDoc) => document = newDoc,
              onSelectionChanged: (newSelection) {},
            ),
          ),
        ),
      );

      // 2. Act
      // The main action is the rendering itself. We'll pump a few frames
      // to ensure any layout calculations or deferred work is completed.
      await tester.pumpAndSettle();

      // 3. Assert
      // The primary assertion is that the pumpAndSettle call didn't time out
      // or crash. If we reach this point, the virtualization is working.
      expect(find.byType(EditorWidget), findsOneWidget);

      // Also, verify that some text from the beginning of the document is
      // visible.
      expect(find.textContaining('word0', findRichText: true), findsOneWidget);
    });
  });
}
