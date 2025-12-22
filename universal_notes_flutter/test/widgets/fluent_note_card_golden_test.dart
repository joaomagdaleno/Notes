import 'package:alchemist/alchemist.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/widgets/fluent_note_card.dart';

void main() {
  group('FluentNoteCard Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'fluent_note_card_grid',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default',
            child: FluentTheme(
              data: FluentThemeData(
                brightness: Brightness.light,
                accentColor: Colors.blue,
              ),
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: FluentNoteCard(
                    note: Note(
                      id: '1',
                      title: 'Test Note',
                      content:
                          '{"blocks": [{"type": "text", '
                          '"spans": [{"text": "Test content"}]}]}',
                      createdAt: DateTime(2023, 10, 27),
                      lastModified: DateTime(2023, 10, 27),
                      ownerId: 'test-user',
                    ),
                    onSave: (note) async => note,
                    onDelete: (note) {},
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'long content',
            child: FluentTheme(
              data: FluentThemeData(
                brightness: Brightness.light,
                accentColor: Colors.blue,
              ),
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: FluentNoteCard(
                    note: Note(
                      id: '2',
                      title:
                          'A very long title that should '
                          'definitely truncate',
                      content:
                          '{"blocks": [{"type": "text", "spans": '
                          '[{"text": "This is very long content..."}]}]}',
                      createdAt: DateTime(2023, 10, 27),
                      lastModified: DateTime(2023, 10, 27),
                      ownerId: 'test-user',
                    ),
                    onSave: (note) async => note,
                    onDelete: (note) {},
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
