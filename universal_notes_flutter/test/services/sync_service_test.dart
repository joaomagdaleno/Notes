import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  late SyncService syncService;
  late MockNoteRepository mockNoteRepository;
  late MockFirestoreRepository mockFirestoreRepository;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockFirestoreRepository = MockFirestoreRepository();
    syncService = SyncService.instance;
    syncService.noteRepository = mockNoteRepository;
    syncService.firestoreRepository = mockFirestoreRepository;
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
        mockNoteRepository.getAllNotes(
          folderId: anyNamed('folderId'),
          tagId: anyNamed('tagId'),
          isFavorite: anyNamed('isFavorite'),
          isInTrash: anyNamed('isInTrash'),
        ),
      ).thenAnswer((_) async => notes);
      when(mockNoteRepository.getAllFolders()).thenAnswer((_) async => []);
      when(mockNoteRepository.getAllTagNames()).thenAnswer((_) async => []);

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
        mockNoteRepository.getUnsyncedNotes(),
      ).thenAnswer((_) async => [unsyncedNote]);
      when(
        mockFirestoreRepository.addNote(
          title: anyNamed('title'),
          content: anyNamed('content'),
        ),
      ).thenAnswer((_) async => unsyncedNote.copyWith(id: 'remote-id'));

      // Need to mock these for internal calls in syncUpNote
      when(
        mockNoteRepository.deleteNotePermanently(any),
      ).thenAnswer((_) async => 1);
      when(mockNoteRepository.insertNote(any)).thenAnswer((_) async => 1);

      await syncService.syncUp();

      verify(
        mockFirestoreRepository.addNote(
          title: 'Local Note',
          content: 'Content',
        ),
      ).called(1);
      verify(mockNoteRepository.deleteNotePermanently('1')).called(1);
    });

    test('syncDown updates local note if remote is newer', () async {
      final now = DateTime.now();
      final remoteNote = Note(
        id: '1',
        title: 'Remote Note',
        content: 'Remote Content',
        createdAt: now,
        lastModified: now.add(const Duration(minutes: 5)),
        ownerId: 'u1',
      );
      final localNote = Note(
        id: '1',
        title: 'Local Note',
        content: 'Local Content',
        createdAt: now,
        lastModified: now,
        ownerId: 'u1',
        syncStatus: SyncStatus.synced,
      );

      when(
        mockNoteRepository.getNoteWithContent('1'),
      ).thenAnswer((_) async => localNote);
      when(
        mockNoteRepository.updateNoteContent(any),
      ).thenAnswer((_) async => 1);

      // Also needed for refreshLocalData inside syncDown
      when(
        mockNoteRepository.getAllNotes(
          folderId: anyNamed('folderId'),
          tagId: anyNamed('tagId'),
          isFavorite: anyNamed('isFavorite'),
          isInTrash: anyNamed('isInTrash'),
        ),
      ).thenAnswer((_) async => []);
      when(mockNoteRepository.getAllFolders()).thenAnswer((_) async => []);
      when(mockNoteRepository.getAllTagNames()).thenAnswer((_) async => []);

      // Directly calling private syncDown for testing logic
      // In a real test we might trigger it through the stream if possible
      // but syncDown is not public. However we can use the method from the plan.
      // Wait, _syncDown is private. I'll test it via init if I can mock firestore notesStream.

      final remoteStreamController = StreamController<List<Note>>();
      when(
        mockFirestoreRepository.notesStream(),
      ).thenAnswer((_) => remoteStreamController.stream);

      await syncService.init();
      remoteStreamController.add([remoteNote]);

      // Wait for async processing
      await Future.delayed(const Duration(milliseconds: 100));

      verify(
        mockNoteRepository.updateNoteContent(
          argThat(
            predicate<Note>(
              (n) => n.content == 'Remote Content' && n.id == '1',
            ),
          ),
        ),
      ).called(1);

      await syncService.reset();
      await remoteStreamController.close();
    });
  });
}
