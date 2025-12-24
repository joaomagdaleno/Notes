@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/reading_settings.dart';
import 'package:universal_notes_flutter/widgets/reading_search_bar.dart';
import 'package:universal_notes_flutter/models/persona_model.dart';

void main() {
  group('EditorWidget Reading Mode', () {
    testWidgets('Reading search highlights results', (
      WidgetTester tester,
    ) async {
      final doc = DocumentModel.fromPlainText('Hello world. Hello reading.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorWidget(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
              initialPersona: EditorPersona.reading,
              readingSettings: const ReadingSettings(),
              onDocumentChanged: (_) {},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );

      // Open search
      final state = tester.state<EditorWidgetState>(find.byType(EditorWidget));

      // Tap FAB to open menu
      await tester.tap(find.byIcon(Icons.add)); // The main FAB has Icons.add
      await tester.pumpAndSettle();

      final searchIcon = find.byIcon(Icons.search);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(find.byType(ReadingSearchBar), findsOneWidget);

      // Type "Hello" in search
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pumpAndSettle();

      // Check if there are matches
      expect(state.readingSearchMatchCount, 2);
    });

    testWidgets('Advanced formatting is applied', (WidgetTester tester) async {
      final doc = DocumentModel.fromPlainText('Some content for formatting.');
      final settings = const ReadingSettings(
        fontSize: 24,
        fontFamily: 'Serif',
        paragraphSpacing: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorWidget(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
              initialPersona: EditorPersona.reading,
              readingSettings: settings,
              onDocumentChanged: (_) {},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify text style (we can search for the text and check style)
      final textWidget = find.byType(RichText).first;
      final RichText richText = tester.widget<RichText>(textWidget);
      final textSpan = richText.text as TextSpan;

      // The style should have fontSize 24 and fontFamily 'Serif'
      expect(textSpan.style?.fontSize, 24);
      expect(textSpan.style?.fontFamily, 'Serif');
    });
  });
}
