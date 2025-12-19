import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/note_version.dart';

void main() {
  group('NoteVersion', () {
    final date = DateTime(2023, 5, 20);

    test('should create a NoteVersion instance', () {
      final version = NoteVersion(
        id: 'v1',
        noteId: 'n1',
        content: r'{"ops":[{"insert":"Hello World\n"}]}',
        date: date,
      );

      expect(version.id, 'v1');
      expect(version.noteId, 'n1');
      expect(version.content, r'{"ops":[{"insert":"Hello World\n"}]}');
      expect(version.date, date);
    });

    test('fromMap should create a NoteVersion from a map', () {
      final map = {
        'id': 'v2',
        'noteId': 'n2',
        'content': 'version content',
        'date': date.millisecondsSinceEpoch,
      };

      final version = NoteVersion.fromMap(map);

      expect(version.id, 'v2');
      expect(version.noteId, 'n2');
      expect(version.content, 'version content');
      expect(version.date, date);
    });

    test('toMap should convert a NoteVersion to a map', () {
      final version = NoteVersion(
        id: 'v3',
        noteId: 'n3',
        content: 'content 3',
        date: date,
      );

      final map = version.toMap();

      expect(map['id'], 'v3');
      expect(map['noteId'], 'n3');
      expect(map['content'], 'content 3');
      expect(map['date'], date.millisecondsSinceEpoch);
    });
  });
}
