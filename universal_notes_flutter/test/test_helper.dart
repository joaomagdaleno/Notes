import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Switching to mocktail for easier setup without code gen
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_event.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/notes_screen.dart';
import 'package:universal_notes_flutter/services/firebase_service.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:window_manager/window_manager.dart';

class MockUpdateService extends Mock implements UpdateService {}

class MockFirestoreRepository extends Mock implements FirestoreRepository {}

class MockWindowManager extends Mock implements WindowManager {}

class MockFirebaseService extends Mock implements FirebaseService {}

MockFirestoreRepository createDefaultMockRepository([List<Note>? notes]) {
  final mockRepo = MockFirestoreRepository();
  final defaultNotes =
      notes ??
      [
        Note(
          id: '1',
          title: 'Test Note 1',
          content: 'Content 1',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'user1',
        ),
        Note(
          id: '2',
          title: 'Test Note 2',
          content: 'Content 2',
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
          ownerId: 'user1',
        ),
      ];

  when(
    () => mockRepo.notesStream(
      isFavorite: any(named: 'isFavorite'),
      isInTrash: any(named: 'isInTrash'),
      tag: any(named: 'tag'),
      folderId: any(named: 'folderId'),
      limit: any(named: 'limit'),
      lastDocument: any(named: 'lastDocument'),
    ),
  ).thenAnswer((_) => Stream.value(defaultNotes));

  when(
    () => mockRepo.notesStream(),
  ).thenAnswer((_) => Stream.value(defaultNotes));

  when(
    () => mockRepo.addNote(
      title: any(named: 'title'),
      content: any(named: 'content'),
    ),
  ).thenAnswer((_) async {
    print('DEBUG: MockFirestoreRepository.addNote called');
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

Future<void> setupTestEnvironment() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  NoteRepository.instance.dbPath = inMemoryDatabasePath;
  PackageInfo.setMockInitialValues(
    appName: 'Universal Notes',
    packageName: 'com.example',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues({});

  // Register fallback values for mocktail
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
      type: NoteEventType.added,
      timestamp: DateTime.now(),
      data: {},
    ),
  );

  await NoteRepository.instance.initDB();
}

Future<void> setupTest() async {
  await SyncService.instance.reset();
  final db = await NoteRepository.instance.database;
  await db.transaction((txn) async {
    await txn.delete('notes');
    await txn.delete('folders');
    await txn.delete('tags');
  });
  SyncService.instance.firestoreRepository = createDefaultMockRepository();
  NoteRepository.instance.firebaseService = MockFirebaseService();
  await SyncService.instance.init();
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
      () => mockUpdate.checkForUpdate(),
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
