/// Use these pre-built objects instead of creating new ones in each test
// ignore_for_file: avoid_redundant_argument_values
library;

import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/note_event.dart';

/// Pre-built test data to avoid object creation overhead in tests
class TestFixtures {
  TestFixtures._();

  /// Standard test note - use for most tests
  static final sampleNote = Note(
    id: 'test-note-1',
    title: 'Test Note',
    content: r'{"ops":[{"insert":"Test content\n"}]}',
    createdAt: DateTime(2024, 1),
    lastModified: DateTime(2024, 1),
    ownerId: 'test-user-1',
  );

  /// Favorite note for testing favorites filter
  static final favoriteNote = Note(
    id: 'fav-note-1',
    title: 'Favorite Note',
    content: r'{"ops":[{"insert":"Favorite content\n"}]}',
    createdAt: DateTime(2024, 1),
    lastModified: DateTime(2024, 1),
    ownerId: 'test-user-1',
    isFavorite: true,
  );

  /// Trashed note for testing trash filter
  static final trashedNote = Note(
    id: 'trash-note-1',
    title: 'Trashed Note',
    content: r'{"ops":[{"insert":"Trashed content\n"}]}',
    createdAt: DateTime(2024, 1),
    lastModified: DateTime(2024, 1),
    ownerId: 'test-user-1',
    isInTrash: true,
  );

  /// List of sample notes for list tests
  static final List<Note> sampleNotes = [
    sampleNote,
    Note(
      id: 'test-note-2',
      title: 'Second Note',
      content: r'{"ops":[{"insert":"Second content\n"}]}',
      createdAt: DateTime(2024, 1, 2),
      lastModified: DateTime(2024, 1, 2),
      ownerId: 'test-user-1',
    ),
    Note(
      id: 'test-note-3',
      title: 'Third Note',
      content: r'{"ops":[{"insert":"Third content\n"}]}',
      createdAt: DateTime(2024, 1, 3),
      lastModified: DateTime(2024, 1, 3),
      ownerId: 'test-user-1',
    ),
  ];

  /// Sample note event for event tests
  static final sampleEvent = NoteEvent(
    id: 'event-1',
    noteId: 'test-note-1',
    type: NoteEventType.insert,
    payload: const {'title': 'Test Note'},
    timestamp: DateTime(2024, 1),
  );

  /// Empty note for edge case tests
  static final emptyNote = Note(
    id: 'empty-note',
    title: '',
    content: '',
    createdAt: DateTime(2024, 1),
    lastModified: DateTime(2024, 1),
    ownerId: 'test-user-1',
  );
}
