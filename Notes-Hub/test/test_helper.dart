import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/note_event.dart';
import 'package:notes_hub/models/reading_stats.dart';
import 'package:notes_hub/repositories/firestore_repository.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/notes_screen.dart';
import 'package:notes_hub/services/encryption_service.dart';
import 'package:notes_hub/services/firebase_service.dart';
import 'package:notes_hub/services/media_service.dart';
import 'package:notes_hub/services/reading_bookmarks_service.dart';
import 'package:notes_hub/services/reading_interaction_service.dart';
import 'package:notes_hub/services/reading_plan_service.dart';
import 'package:notes_hub/services/reading_stats_service.dart';
import 'package:notes_hub/services/storage_service.dart';
import 'package:notes_hub/services/sync_service.dart';
import 'package:notes_hub/services/tracing_service.dart';
import 'package:notes_hub/services/update_service.dart';
import 'package:opentelemetry/api.dart' as otel;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:sqflite/sqflite.dart'; // Disabled for FFI issues
// import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

const String inMemoryDatabasePath = ':memory:';

class MockSyncService extends Mock implements SyncService {}

class MockNoteRepository extends Mock implements NoteRepository {}

class MockFirestoreRepository extends Mock implements FirestoreRepository {}

class MockFirebaseService extends Mock implements FirebaseService {}

class MockUpdateService extends Mock implements UpdateService {}

class MockWindowManager extends Mock implements WindowManager {}

class MockStorageService extends Mock implements StorageService {}

class MockMediaService extends Mock implements MediaService {}

class MockReadingBookmarksService extends Mock
    implements ReadingBookmarksService {}

class MockReadingInteractionService extends Mock
    implements ReadingInteractionService {}

class MockReadingStatsService extends Mock implements ReadingStatsService {}

class MockReadingPlanService extends Mock implements ReadingPlanService {}

MockFirestoreRepository createDefaultMockRepository([List<Note>? notes]) {
  final mockRepo = MockFirestoreRepository();

  when(
    () => mockRepo.notesStream(
      isFavorite: any(named: 'isFavorite'),
      isInTrash: any(named: 'isInTrash'),
      tag: any(named: 'tag'),
      folderId: any(named: 'folderId'),
      limit: any(named: 'limit'),
      lastDocument: any(named: 'lastDocument'),
    ),
  ).thenAnswer((_) => const Stream.empty());

  when(
    mockRepo.notesStream,
  ).thenAnswer((_) => const Stream.empty());

  when(
    () => mockRepo.addNote(
      title: any(named: 'title'),
      content: any(named: 'content'),
    ),
  ).thenAnswer((_) async {
    return Note(
      id: 'new-id',
      title: 'New Note',
      content: 'New Content',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    );
  });

  when(() => mockRepo.updateNote(any())).thenAnswer((_) async {});
  when(() => mockRepo.deleteNote(any())).thenAnswer((_) async {});
  when(() => mockRepo.getNoteContent(any())).thenAnswer((_) async => '');
  when(() => mockRepo.addNoteEvent(any())).thenAnswer((_) async {});
  when(() => mockRepo.addNoteEvents(any())).thenAnswer((_) async {});
  when(
    () => mockRepo.getNoteEventsSince(any(), any()),
  ).thenAnswer((_) async => []);

  return mockRepo;
}

bool _fallbacksRegistered = false;

void _ensureFallbacksRegistered() {
  if (_fallbacksRegistered) return;
  registerFallbackValue(
    Note(
      id: '',
      title: '',
      content: '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: '',
    ),
  );
  registerFallbackValue(
    NoteEvent(
      id: '',
      noteId: '',
      type: NoteEventType.unknown,
      payload: const {},
      timestamp: DateTime(0),
    ),
  );
  _fallbacksRegistered = true;
}

Future<void> setupTestEnvironment() async {
  PackageInfo.setMockInitialValues(
    appName: 'Notes Hub',
    packageName: 'com.example',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues({});

  registerFallbackValue(
    Note(
      id: '',
      title: '',
      content: '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: '',
    ),
  );
  registerFallbackValue(
    NoteEvent(
      id: '',
      noteId: '',
      type: NoteEventType.unknown,
      payload: const {},
      timestamp: DateTime(0),
    ),
  );
}

Future<void> setupTest() async {
  _ensureFallbacksRegistered();
  SyncService.resetInstance();
  EncryptionService.iterations = 1;

  final mockNoteRepo = MockNoteRepository();
  final defaultNotes = [
    Note(
      id: 'default-1',
      title: 'Default Note',
      content: 'Default Content',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user1',
    ),
  ];

  when(
    () => mockNoteRepo.getAllNotes(
      folderId: any(named: 'folderId'),
      tagId: any(named: 'tagId'),
      isFavorite: any(named: 'isFavorite'),
      isInTrash: any(named: 'isInTrash'),
    ),
  ).thenAnswer((_) async => defaultNotes);

  when(mockNoteRepo.getAllFolders).thenAnswer((_) async => []);
  when(mockNoteRepo.getAllTagNames).thenAnswer((_) async => []);
  when(mockNoteRepo.getAllSnippets).thenAnswer((_) async => []);
  when(mockNoteRepo.getUnsyncedNotes).thenAnswer((_) async => []);
  when(mockNoteRepo.getUnsyncedWords).thenAnswer((_) async => []);
  when(
    () => mockNoteRepo.getNoteWithContent(any()),
  ).thenAnswer((_) async => defaultNotes.first);

  when(() => mockNoteRepo.insertNote(any())).thenAnswer((_) async => 'new-id');
  when(() => mockNoteRepo.updateNote(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.updateNoteContent(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.deleteNote(any())).thenAnswer((_) async {});
  when(
    () => mockNoteRepo.deleteNotePermanently(any()),
  ).thenAnswer((_) async {});
  when(() => mockNoteRepo.addNoteEvent(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.getNoteEvents(any())).thenAnswer((_) async => []);
  when(() => mockNoteRepo.updateNoteEvent(any())).thenAnswer((_) async {});

  // Stub reading services
  final mockBookmarks = MockReadingBookmarksService();
  final mockInteraction = MockReadingInteractionService();
  final mockStats = MockReadingStatsService();
  final mockPlan = MockReadingPlanService();

  when(() => mockNoteRepo.bookmarksService).thenReturn(mockBookmarks);
  when(
    () => mockNoteRepo.readingInteractionService,
  ).thenReturn(mockInteraction);
  when(() => mockNoteRepo.readingStatsService).thenReturn(mockStats);
  when(() => mockNoteRepo.readingPlanService).thenReturn(mockPlan);

  // Stub stats service listeners/session
  when(() => mockStats.addListener(any())).thenReturn(null);
  when(() => mockStats.removeListener(any())).thenReturn(null);
  when(mockStats.stopSession).thenAnswer((_) async {});
  when(
    () => mockStats.getStatsForNote(any()),
  ).thenAnswer((_) async => const ReadingStats(noteId: 'test'));
  when(() => mockStats.startSession(any())).thenAnswer((_) async {});

  // Stub interaction service
  when(
    () => mockInteraction.getAnnotationsForNote(any()),
  ).thenAnswer((_) async => []);

  // Stub plan service
  when(() => mockPlan.findPlanForNote(any())).thenAnswer((_) async => null);

  // Replace the static singleton
  NoteRepository.instance = mockNoteRepo;

  StorageService.instance = MockStorageService();
  MediaService.instance = MockMediaService();

  final mockFirestore = createDefaultMockRepository();
  FirestoreRepository.instance = mockFirestore;
  SyncService.instance.firestoreRepository = mockFirestore;
  SyncService.instance.noteRepository = mockNoteRepo;

  // Stub TracingService
  final mockTracing = MockTracingService();
  TracingService.instance = mockTracing;
  when(() => mockTracing.startSpan(any())).thenReturn(MockSpan());
  when(() => mockTracing.tracer).thenReturn(MockTracer());

  // REMOVED: await SyncService.instance.init();
  // We should not trigger global service initialization by default in all
  // tests.
}

class MockSpan extends Mock implements otel.Span {}

class MockTracingService extends Mock implements TracingService {}

class MockTracer extends Mock implements otel.Tracer {}

Future<void> setupNotesTest() async {
  _ensureFallbacksRegistered();
  // Initialize FFI - DISABLED due to environment issues
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;

  // Mock NoteRepository instead of real DB setup to bypass FFI requirement
  final mockNoteRepo = MockNoteRepository();
  // Setup default mocks for repository to prevent NPAs
  when(
    () => mockNoteRepo.getAllNotes(
      folderId: any(named: 'folderId'),
      tagId: any(named: 'tagId'),
      isFavorite: any(named: 'isFavorite'),
      isInTrash: any(named: 'isInTrash'),
    ),
  ).thenAnswer((_) async => []);

  when(mockNoteRepo.getAllFolders).thenAnswer((_) async => []);
  when(mockNoteRepo.getAllTagNames).thenAnswer((_) async => []);
  when(mockNoteRepo.getUnsyncedNotes).thenAnswer((_) async => []);
  when(mockNoteRepo.getUnsyncedWords).thenAnswer((_) async => []);
  when(mockNoteRepo.getAllSnippets).thenAnswer((_) async => []);

  when(() => mockNoteRepo.insertNote(any())).thenAnswer((_) async => 'new-id');
  when(() => mockNoteRepo.updateNote(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.updateNoteContent(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.deleteNote(any())).thenAnswer((_) async {});
  when(
    () => mockNoteRepo.deleteNotePermanently(any()),
  ).thenAnswer((_) async {});
  when(() => mockNoteRepo.addNoteEvent(any())).thenAnswer((_) async {});
  when(() => mockNoteRepo.getNoteEvents(any())).thenAnswer((_) async => []);
  when(() => mockNoteRepo.updateNoteEvent(any())).thenAnswer((_) async {});

  // Stub reading services
  final mockBookmarks = MockReadingBookmarksService();
  final mockInteraction = MockReadingInteractionService();
  final mockStats = MockReadingStatsService();
  final mockPlan = MockReadingPlanService();

  when(() => mockNoteRepo.bookmarksService).thenReturn(mockBookmarks);
  when(
    () => mockNoteRepo.readingInteractionService,
  ).thenReturn(mockInteraction);
  when(() => mockNoteRepo.readingStatsService).thenReturn(mockStats);
  when(() => mockNoteRepo.readingPlanService).thenReturn(mockPlan);

  // Stub stats service listeners/session
  when(() => mockStats.addListener(any())).thenReturn(null);
  when(() => mockStats.removeListener(any())).thenReturn(null);
  when(mockStats.stopSession).thenAnswer((_) async {});
  when(
    () => mockStats.getStatsForNote(any()),
  ).thenAnswer((_) async => const ReadingStats(noteId: 'test'));
  when(() => mockStats.startSession(any())).thenAnswer((_) async {});

  // Stub interaction service
  when(
    () => mockInteraction.getAnnotationsForNote(any()),
  ).thenAnswer((_) async => []);

  // Stub plan service
  when(() => mockPlan.findPlanForNote(any())).thenAnswer((_) async => null);

  // NoteRepository.resetInstance(); // Don't reset to real, use mock
  NoteRepository.instance = mockNoteRepo;
  FirestoreRepository.instance = createDefaultMockRepository();
  StorageService.instance = MockStorageService();
  EncryptionService.iterations = 1;

  // Initialize database early - DISABLED
  // NoteRepository.instance.dbPath = inMemoryDatabasePath;
  // await NoteRepository.instance.database;

  unawaited(SyncService.instance.reset()); // Existing reset method
  SyncService.instance.noteRepository = NoteRepository.instance;
  SyncService.instance.firestoreRepository = FirestoreRepository.instance;

  // Stub TracingService (even for real tests, as it may lack native deps)
  final mockTracing = MockTracingService();
  TracingService.instance = mockTracing;
  when(() => mockTracing.startSpan(any())).thenReturn(MockSpan());
  when(() => mockTracing.tracer).thenReturn(MockTracer());
}

Future<void> tearDownTest() async {
  debugDefaultTargetPlatformOverride = null;
}

Future<void> pumpNotesScreen(
  WidgetTester tester, {
  UpdateService? updateService,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;

  final mockUpdate = updateService ?? MockUpdateService();
  if (updateService == null) {
    when(
      mockUpdate.checkForUpdate,
    ).thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));
  }

  await tester.pumpWidget(
    fluent.FluentApp(
      home: fluent.FluentTheme(
        data: fluent.FluentThemeData.light(),
        child: NotesScreen(updateService: mockUpdate),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
