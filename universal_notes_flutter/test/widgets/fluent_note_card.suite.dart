@Tags(['widget'])
library;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';

void main() {
  group('NoteCard (Fluent)', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    final noteWithValidContent = Note(
      id: '1',
      title: 'Test Note',
      content: '[{"type":"text","spans":[{"text":"This is a test note."}]}]',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    final noteWithInvalidContent = Note(
      id: '2',
      title: 'Test Note 2',
      content: 'invalid content',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );

    testWidgets('displays title and content preview for valid content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: NoteCard(
              note: noteWithValidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('This is a test note.'), findsOneWidget);
    });

    testWidgets('displays fallback text for invalid content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: NoteCard(
              note: noteWithInvalidContent,
              onDelete: (note) {},
              onSave: (note) async => note,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('invalid content'), findsOneWidget);
    });

    testWidgets('tapping NoteCard calls onTap', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Scaffold(
            body: NoteCard(
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

      await tester.tap(find.byType(NoteCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tapping NoteCard triggers default navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: Builder(
            builder: (context) {
              return NoteCard(
                note: noteWithValidContent,
                onDelete: (note) {},
                onSave: (note) async => note,
                onTap: () async {
                  await Navigator.of(context).push(
                    fluent.FluentPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Edit Note'),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      // Verify the NoteCard is rendered
      expect(find.byType(NoteCard), findsOneWidget);

      // Tap the NoteCard
      await tester.tap(find.byType(NoteCard));
      await tester.pumpAndSettle(); // Wait for navigation to complete

      // Verify that navigation occurred by finding text on the new screen
      expect(find.text('Edit Note'), findsOneWidget);
    });
  });
}
