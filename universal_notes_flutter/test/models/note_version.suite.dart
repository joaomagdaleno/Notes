@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note_version.dart';

void main() {
  group('NoteVersion', () {
    final date = DateTime.now();
    final version = NoteVersion(
      id: 'v1',
      noteId: 'n1',
      content: 'Version 1 content',
      date: date,
    );

    test('should create a NoteVersion instance', () {
      expect(version.id, 'v1');
      expect(version.noteId, 'n1');
      expect(version.content, 'Version 1 content');
      expect(version.date, date);
    });

    test('fromMap should create a NoteVersion from a map', () {
      final map = {
        'id': 'v2',
        'noteId': 'n2',
        'content': 'Version 2 content',
        'date': date.millisecondsSinceEpoch,
      };

      final fromMap = NoteVersion.fromMap(map);

      expect(fromMap.id, 'v2');
      expect(fromMap.noteId, 'n2');
      expect(fromMap.content, 'Version 2 content');
      expect(fromMap.date.millisecondsSinceEpoch, date.millisecondsSinceEpoch);
    });

    test('toMap should convert a NoteVersion to a map', () {
      final map = version.toMap();

      expect(map['id'], 'v1');
      expect(map['noteId'], 'n1');
      expect(map['content'], 'Version 1 content');
      expect(map['date'], date.millisecondsSinceEpoch);
    });
  });
}
