import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';

void main() {
  group('Note', () {
    final now = DateTime.now();
    final note = Note(
      id: '1',
      title: 'Test Note',
      content: 'This is a test note.',
      createdAt: now,
      lastModified: now,
      ownerId: 'user1',
      collaborators: const {'user2': 'editor'},
      tags: const ['tag1', 'tag2'],
      memberIds: const ['user1', 'user2'],
      isFavorite: true,
      imageUrl: 'http://example.com/image.png',
      folderId: 'folder1',
    );

    test('Note can be created and properties are correct', () {
      expect(note.id, '1');
      expect(note.title, 'Test Note');
      expect(note.content, 'This is a test note.');
      expect(note.createdAt, now);
      expect(note.lastModified, now);
      expect(note.ownerId, 'user1');
      expect(note.collaborators, {'user2': 'editor'});
      expect(note.tags, ['tag1', 'tag2']);
      expect(note.memberIds, ['user1', 'user2']);
      expect(note.isFavorite, isTrue);
      expect(note.isInTrash, isFalse);
      expect(note.imageUrl, 'http://example.com/image.png');
      expect(note.folderId, 'folder1');
      expect(note.syncStatus, SyncStatus.synced);
      expect(note.date, now);
    });

    test('Note.fromMap sets all fields correctly', () {
      final map = {
        'id': '2',
        'title': 'Map Note',
        'content': 'Content from map',
        'date': now.millisecondsSinceEpoch,
        'ownerId': 'user2',
        'isFavorite': 1,
        'isInTrash': 1,
        'folderId': 'folder2',
        'syncStatus': SyncStatus.modified.index,
      };

      final fromMapNote = Note.fromMap(map);

      expect(fromMapNote.id, '2');
      expect(fromMapNote.title, 'Map Note');
      expect(fromMapNote.content, 'Content from map');
      expect(
        fromMapNote.createdAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(
        fromMapNote.lastModified.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(fromMapNote.ownerId, 'user2');
      expect(fromMapNote.isFavorite, isTrue);
      expect(fromMapNote.isInTrash, isTrue);
      expect(fromMapNote.folderId, 'folder2');
      expect(fromMapNote.syncStatus, SyncStatus.modified);
    });

    test('Note.fromMap handles defaults', () {
      final fromMapNote = Note.fromMap(const {});
      expect(fromMapNote.id, '');
      expect(fromMapNote.title, 'Untitled');
      expect(fromMapNote.content, '');
      expect(fromMapNote.ownerId, 'local');
      expect(fromMapNote.isFavorite, isFalse);
      expect(fromMapNote.isInTrash, isFalse);
      expect(fromMapNote.syncStatus, SyncStatus.synced);
    });

    test('Note.toMap returns correct map', () {
      final map = note.toMap();

      expect(map['id'], '1');
      expect(map['title'], 'Test Note');
      expect(map['content'], 'This is a test note.');
      expect(map['date'], now.millisecondsSinceEpoch);
      expect(map['isFavorite'], 1);
      expect(map['isInTrash'], 0);
      expect(map['folderId'], 'folder1');
      expect(map['syncStatus'], SyncStatus.synced.index);
    });

    test('Note.toFirestore returns correct map', () {
      final firestoreMap = note.toFirestore();

      expect(firestoreMap['title'], 'Test Note');
      expect(firestoreMap['content'], 'This is a test note.');
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['lastModified'], isA<Timestamp>());
      expect(firestoreMap['ownerId'], 'user1');
      expect(firestoreMap['collaborators'], {'user2': 'editor'});
      expect(firestoreMap['tags'], ['tag1', 'tag2']);
      expect(firestoreMap['memberIds'], ['user1', 'user2']);
      expect(firestoreMap['isFavorite'], isTrue);
      expect(firestoreMap['isInTrash'], isFalse);
      expect(firestoreMap['imageUrl'], 'http://example.com/image.png');
    });

    test('Note.copyWith works correctly', () {
      final copied = note.copyWith(
        title: 'New Title',
        isFavorite: false,
      );

      expect(copied.title, 'New Title');
      expect(copied.isFavorite, isFalse);
      expect(copied.id, note.id); // unchanged
      expect(copied.content, note.content); // unchanged
    });
  });
}
