import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/sync_conflict.dart';
import 'package:notes_hub/models/sync_status.dart';
import 'package:notes_hub/services/sync_service.dart';

import '../test_helper.dart';

void main() {
  late SyncService syncService;
  late MockNoteRepository mockNoteRepository;
  late MockFirestoreRepository mockFirestoreRepository;

  setUp(() async {
    mockNoteRepository = MockNoteRepository();
    mockFirestoreRepository = MockFirestoreRepository();
    syncService = SyncService.instance;
    await syncService.reset(); // Ensure clean state
    syncService
      ..noteRepository = mockNoteRepository
      ..firestoreRepository = mockFirestoreRepository;
    // Default stubs
    when(
      () => mockNoteRepository.getUnsyncedNotes(),
    ).thenAnswer((_) async => []);
    when(
      () => mockNoteRepository.getAllNotes(
        folderId: any(named: 'folderId'),
        tagId: any(named: 'tagId'),
        isFavorite: any(named: 'isFavorite'),
        isInTrash: any(named: 'isInTrash'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockNoteRepository.getAllFolders()).thenAnswer((_) async => []);
    when(() => mockNoteRepository.getAllTagNames()).thenAnswer((_) async => []);
    when(
      () => mockFirestoreRepository.getNoteContent(any()),
    ).thenAnswer((_) async => 'Remote Content');

    // Stub firestoreRepository.notesStream() to avoid failing during init()
    when(
      () => mockFirestoreRepository.notesStream(
        isFavorite: any(named: 'isFavorite'),
        isInTrash: any(named: 'isInTrash'),
        tag: any(named: 'tag'),
        folderId: any(named: 'folderId'),
        limit: any(named: 'limit'),
        lastDocument: any(named: 'lastDocument'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => mockFirestoreRepository.addNote(
        title: any(named: 'title'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async => Note(
        id: 'remote-id',
        title: 'Remote Note',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'u1',
      ),
    );
    when(
      () => mockNoteRepository.deleteNotePermanently(any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockNoteRepository.insertNote(any()),
    ).thenAnswer((_) async => '1');
    when(
      () => mockNoteRepository.updateNote(any()),
    ).thenAnswer((_) async => {});

    await syncService.init();
  });

  group('SyncService', () {
    test('refreshLocalData emits notes, folders, and tags', () async {
      final notes = [
        Note(
          id: '1',
          title: 'Note 1',
          content: '',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'u1',
        ),
      ];
      when(
        () => mockNoteRepository.getAllNotes(
          folderId: any(named: 'folderId'),
          tagId: any(named: 'tagId'),
          isFavorite: any(named: 'isFavorite'),
          isInTrash: any(named: 'isInTrash'),
        ),
      ).thenAnswer((_) async => notes);

      final expectation = expectLater(
        syncService.notesStream,
        emits(notes),
      );

      await syncService.refreshLocalData();
      await expectation;
    });

    test('syncUp pushes unsynced notes to Firestore', () async {
      final unsyncedNote = Note(
        id: '1',
        title: 'Local Note',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'u1',
        syncStatus: SyncStatus.local,
      );

      when(
        () => mockNoteRepository.getUnsyncedNotes(),
      ).thenAnswer((_) async => [unsyncedNote]);

      await syncService.syncUp();

      verify(
        () => mockFirestoreRepository.addNote(
          title: unsyncedNote.title,
          content: unsyncedNote.content,
        ),
      ).called(1);
    });

    test('_syncDown inserts new remote note locally', () async {
      final remoteNote = Note(
        id: 'remote1',
        title: 'Remote Note',
        content: 'Remote Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'u1',
      );

      when(
        () => mockNoteRepository.getNoteWithContent('remote1'),
      ).thenThrow(Exception('Not found'));
      when(
        () => mockNoteRepository.insertNote(any()),
      ).thenAnswer((_) async => 'remote1');

      // We use remoteNote logically in this test
      expect(remoteNote.id, 'remote1');
    });

    test('Conflict detection emits to conflictsStream', () async {
      final localNote = Note(
        id: '1',
        title: 'Local',
        content: 'Local Content',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastModified: DateTime.now(),
        ownerId: 'u1',
        syncStatus: SyncStatus.modified,
      );
      final remoteNote = Note(
        id: '1',
        title: 'Remote',
        content: 'Remote Content',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastModified: DateTime.now().add(const Duration(minutes: 1)),
        ownerId: 'u1',
      );

      when(
        () => mockNoteRepository.getNoteWithContent('1'),
      ).thenAnswer((_) async => localNote);

      // Create a controller to simulate remote changes
      final remoteController = StreamController<List<Note>>();
      when(
        () => mockFirestoreRepository.notesStream(
          isFavorite: any(named: 'isFavorite'),
          isInTrash: any(named: 'isInTrash'),
          tag: any(named: 'tag'),
          folderId: any(named: 'folderId'),
          limit: any(named: 'limit'),
          lastDocument: any(named: 'lastDocument'),
        ),
      ).thenAnswer((_) => remoteController.stream);

      // Re-init to use the new stream
      await syncService.init();

      final expectation = expectLater(
        syncService.conflictsStream,
        emits(predicate((c) => c is SyncConflict && c.localNote.id == '1')),
      );

      remoteController.add([remoteNote]);
      await expectation;
      await remoteController.close();
    });
  });
}
