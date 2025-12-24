import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/stroke.dart';
import 'package:universal_notes_flutter/models/tag.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/models/sync_conflict.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/persona_model.dart';

void main() {
  group('Stroke and Point', () {
    test('Point toJson/fromJson symmetry', () {
      const p = Point(10, 20, 0.5);
      final json = p.toJson();
      final fromJson = Point.fromJson(json);

      expect(fromJson.x, 10.0);
      expect(fromJson.y, 20.0);
      expect(fromJson.pressure, 0.5);
    });

    test('Stroke toJson/fromJson symmetry', () {
      const s = Stroke(
        points: [Point(0, 0), Point(1, 1)],
        color: Colors.red,
        width: 2,
      );
      final json = s.toJson();
      final fromJson = Stroke.fromJson(json);

      expect(fromJson.points.length, 2);
      expect(fromJson.color.toARGB32(), Colors.red.toARGB32());
      expect(fromJson.width, 2.0);
    });
  });

  group('Tag', () {
    test('toMap/fromMap symmetry', () {
      const tag = Tag(id: '1', name: 'Work', color: Colors.blue);
      final map = tag.toMap();
      final fromMap = Tag.fromMap(map);

      expect(fromMap.id, '1');
      expect(fromMap.name, 'Work');
      expect(fromMap.color?.toARGB32(), Colors.blue.toARGB32());
    });
  });

  group('SyncConflict', () {
    test('SyncConflict properties', () {
      final localNote = Note(
        id: '1',
        title: 'L',
        content: 'Local',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'u1',
      );
      final remoteNote = Note(
        id: '1',
        title: 'R',
        content: 'Remote',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'u1',
      );
      final conflict = SyncConflict(
        localNote: localNote,
        remoteNote: remoteNote,
      );

      expect(conflict.localNote, localNote);
      expect(conflict.remoteNote, remoteNote);
    });
  });

  group('SyncStatus', () {
    test('values should exist', () {
      expect(SyncStatus.values.length, greaterThan(0));
      expect(SyncStatus.synced, isNotNull);
      expect(SyncStatus.local, isNotNull);
      expect(SyncStatus.modified, isNotNull);
    });
  });

  group('EditorPersona', () {
    test('values should exist', () {
      expect(EditorPersona.values.length, 4);
      expect(EditorPersona.architect, isNotNull);
      expect(EditorPersona.writer, isNotNull);
      expect(EditorPersona.brainstorm, isNotNull);
      expect(EditorPersona.zen, isNotNull);
    });
  });
}
