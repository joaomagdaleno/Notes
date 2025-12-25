import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
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
  });
}
