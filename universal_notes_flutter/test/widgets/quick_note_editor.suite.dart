@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/widgets/quick_note_editor.dart';

void main() {
  Widget createWidgetUnderTest(void Function(String) onSave) {
    return MaterialApp(
      home: Scaffold(
        body: QuickNoteEditor(onSave: onSave),
      ),
    );
  }

  group('QuickNoteEditor', () {
    testWidgets('calls onSave and pops when Salvar is clicked', (
      WidgetTester tester,
    ) async {
      String? savedText;
      await tester.pumpWidget(
        createWidgetUnderTest((text) => savedText = text),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.tap(find.text('Salvar'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(savedText, 'Hello World');
      expect(find.byType(QuickNoteEditor), findsNothing);
    });

    testWidgets('does not call onSave and pops when Cancelar is clicked', (
      WidgetTester tester,
    ) async {
      String? savedText;
      await tester.pumpWidget(
        createWidgetUnderTest((text) => savedText = text),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(savedText, isNull);
      expect(find.byType(QuickNoteEditor), findsNothing);
    });

    testWidgets('autosaves every 10 seconds if text is not empty', (
      WidgetTester tester,
    ) async {
      String? savedText;
      await tester.pumpWidget(
        createWidgetUnderTest((text) => savedText = text),
      );

      await tester.enterText(find.byType(TextField), 'Autosave me');

      // Advance time by 10 seconds
      await tester.pump(const Duration(seconds: 10));

      expect(savedText, 'Autosave me');
    });

    testWidgets('does not autosave if text is empty', (
      WidgetTester tester,
    ) async {
      String? savedText;
      await tester.pumpWidget(
        createWidgetUnderTest((text) => savedText = text),
      );

      // Advance time by 10 seconds
      await tester.pump(const Duration(seconds: 10));

      expect(savedText, isNull);
    });
  });
}
