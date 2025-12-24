import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/reading_highlight.dart';

void main() {
  group('ReadingHighlight', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    test('creates with required parameters', () {
      final highlight = ReadingHighlight(
        id: 'hl-1',
        noteId: 'note-123',
        startPosition: 100,
        endPosition: 150,
        createdAt: testDate,
      );

      expect(highlight.id, 'hl-1');
      expect(highlight.noteId, 'note-123');
      expect(highlight.startPosition, 100);
      expect(highlight.endPosition, 150);
      expect(highlight.createdAt, testDate);
      expect(highlight.color, HighlightColor.yellow); // default
      expect(highlight.note, isNull);
      expect(highlight.text, isNull);
    });

    test('creates with optional parameters', () {
      final highlight = ReadingHighlight(
        id: 'hl-2',
        noteId: 'note-456',
        startPosition: 200,
        endPosition: 300,
        createdAt: testDate,
        color: HighlightColor.green,
        note: 'Important point',
        text: 'highlighted text content',
      );

      expect(highlight.color, HighlightColor.green);
      expect(highlight.note, 'Important point');
      expect(highlight.text, 'highlighted text content');
    });

    group('JSON serialization', () {
      test('toJson converts to map', () {
        final highlight = ReadingHighlight(
          id: 'hl-1',
          noteId: 'note-123',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
          color: HighlightColor.blue,
          note: 'Test note',
          text: 'Sample',
        );

        final json = highlight.toJson();

        expect(json['id'], 'hl-1');
        expect(json['noteId'], 'note-123');
        expect(json['startPosition'], 100);
        expect(json['endPosition'], 150);
        expect(json['createdAt'], testDate.toIso8601String());
        expect(json['color'], 'blue');
        expect(json['note'], 'Test note');
        expect(json['text'], 'Sample');
      });

      test('fromJson creates from map', () {
        final json = {
          'id': 'hl-3',
          'noteId': 'note-789',
          'startPosition': 50,
          'endPosition': 75,
          'createdAt': testDate.toIso8601String(),
          'color': 'pink',
          'note': 'My note',
          'text': 'Some text',
        };

        final highlight = ReadingHighlight.fromJson(json);

        expect(highlight.id, 'hl-3');
        expect(highlight.noteId, 'note-789');
        expect(highlight.startPosition, 50);
        expect(highlight.endPosition, 75);
        expect(highlight.createdAt, testDate);
        expect(highlight.color, HighlightColor.pink);
        expect(highlight.note, 'My note');
        expect(highlight.text, 'Some text');
      });

      test('fromJson handles unknown color', () {
        final json = {
          'id': 'hl-4',
          'noteId': 'note-999',
          'startPosition': 10,
          'endPosition': 20,
          'createdAt': testDate.toIso8601String(),
          'color': 'unknown_color',
        };

        final highlight = ReadingHighlight.fromJson(json);

        expect(highlight.color, HighlightColor.yellow); // default
      });

      test('roundtrip serialization', () {
        final original = ReadingHighlight(
          id: 'hl-rt',
          noteId: 'note-rt',
          startPosition: 0,
          endPosition: 50,
          createdAt: testDate,
          color: HighlightColor.orange,
          note: 'Roundtrip note',
          text: 'Roundtrip text',
        );

        final json = original.toJson();
        final restored = ReadingHighlight.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = ReadingHighlight(
          id: 'hl-1',
          noteId: 'note-123',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
        );

        final copied = original.copyWith(
          startPosition: 90,
          color: HighlightColor.green,
          note: 'New note',
        );

        expect(copied.id, 'hl-1'); // unchanged
        expect(copied.startPosition, 90); // changed
        expect(copied.endPosition, 150); // unchanged
        expect(copied.color, HighlightColor.green); // changed
        expect(copied.note, 'New note'); // changed
      });
    });

    group('equality', () {
      test('equals with same values', () {
        final highlight1 = ReadingHighlight(
          id: 'hl-1',
          noteId: 'note-1',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
          color: HighlightColor.blue,
        );

        final highlight2 = ReadingHighlight(
          id: 'hl-1',
          noteId: 'note-1',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
          color: HighlightColor.blue,
        );

        expect(highlight1, equals(highlight2));
        expect(highlight1.hashCode, equals(highlight2.hashCode));
      });

      test('not equals with different values', () {
        final highlight1 = ReadingHighlight(
          id: 'hl-1',
          noteId: 'note-1',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
        );

        final highlight2 = ReadingHighlight(
          id: 'hl-2',
          noteId: 'note-1',
          startPosition: 100,
          endPosition: 150,
          createdAt: testDate,
        );

        expect(highlight1, isNot(equals(highlight2)));
      });
    });

    test('flutterColor returns correct color', () {
      final highlight = ReadingHighlight(
        id: 'hl-1',
        noteId: 'note-1',
        startPosition: 0,
        endPosition: 10,
        createdAt: testDate,
        color: HighlightColor.green,
      );

      expect(highlight.flutterColor, HighlightColor.green.toColor());
    });
  });

  group('HighlightColor', () {
    test('all colors have valid flutter colors', () {
      for (final color in HighlightColor.values) {
        expect(color.toColor(), isA<Color>());
      }
    });

    test('toColor returns expected colors', () {
      expect(HighlightColor.yellow.toColor(), const Color(0xFFFFF59D));
      expect(HighlightColor.green.toColor(), const Color(0xFFA5D6A7));
      expect(HighlightColor.blue.toColor(), const Color(0xFF90CAF9));
      expect(HighlightColor.pink.toColor(), const Color(0xFFF48FB1));
      expect(HighlightColor.orange.toColor(), const Color(0xFFFFCC80));
    });
  });
}
