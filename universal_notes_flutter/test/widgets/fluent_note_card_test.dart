import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/fluent_note_card.dart';

void main() {
  group('FluentNoteCard', () {
    final noteWithValidContent = Note(
      id: '1',
      title: 'Test Note',
      content: r'[{"insert":"This is a test note.\n"}]',
      date: DateTime.now(),
    );

    final noteWithInvalidContent = Note(
      id: '2',
      title: 'Test Note 2',
      content: 'invalid json',
      date: DateTime.now(),
    );

    testWidgets('displays title and content preview for valid content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: FluentNoteCard(
              note: noteWithValidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
            ),
          ),
        ),
      );

      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('This is a test note.'), findsOneWidget);
    });

    testWidgets('displays fallback text for invalid content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: FluentNoteCard(
              note: noteWithInvalidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
            ),
          ),
        ),
      );

      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('tapping FluentNoteCard calls onTap',
        (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: FluentNoteCard(
              note: noteWithValidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FluentNoteCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tapping FluentNoteCard navigates to editor when onTap is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: FluentNoteCard(
              note: noteWithValidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FluentNoteCard));
      await tester.pumpAndSettle();

      expect(find.text('Test Note'), findsOneWidget);
    });
  });
  group('getPreviewText', () {
    test('extracts text from valid JSON', () {
      const json = r'[{"insert":"Hello World"},{"insert":"\n"}]';
      expect(getPreviewText(json), 'Hello World');
    });

    test('returns ellipsis for invalid JSON', () {
      const json = r'invalid-json';
      expect(getPreviewText(json), '...');
    });
  });
}
