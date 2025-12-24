import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/notes_screen.dart';
import 'package:universal_notes_flutter/services/firebase_service.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:window_manager/window_manager.dart';

class MockUpdateService extends Mock implements UpdateService {
  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    return UpdateCheckResult(UpdateCheckStatus.noUpdate);
  }
}

class MockFirestoreRepository extends Mock implements FirestoreRepository {
  @override
  Stream<List<Note>> notesStream({
    bool? isFavorite,
    bool? isInTrash,
    String? tag,
    String? folderId,
    int limit = 20,
    dynamic lastDocument,
  }) {
    return super.noSuchMethod(
          Invocation.method(#notesStream, [], {
            #isFavorite: isFavorite,
            #isInTrash: isInTrash,
            #tag: tag,
            #folderId: folderId,
            #limit: limit,
            #lastDocument: lastDocument,
          }),
          returnValue: Stream.value(<Note>[]),
          returnValueForMissingStub: Stream.value(<Note>[]),
        )
        as Stream<List<Note>>;
  }

  @override
  Future<Note> addNote({required String title, required String content}) {
    return super.noSuchMethod(
          Invocation.method(#addNote, [], {#title: title, #content: content}),
          returnValue: Future.value(
            Note(
              id: '1',
              title: title,
              content: content,
              createdAt: DateTime.now(),
              lastModified: DateTime.now(),
              ownerId: 'user1',
            ),
          ),
        )
        as Future<Note>;
  }

  @override
  Future<void> updateNote(Note? note) => Future.value();
  @override
  Future<void> deleteNote(String? id) => Future.value();
  @override
  Future<String> getNoteContent(String? noteId) => Future.value('');
}

class MockWindowManager extends Mock implements WindowManager {
  @override
  void addListener(WindowListener listener) {}
  @override
  void removeListener(WindowListener listener) {}
  @override
  Future<void> destroy() async {}
}

class MockFirebaseService extends Mock implements FirebaseService {
  @override
  void dispose() {}
}

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
    mockRepo.notesStream(
      isFavorite: anyNamed('isFavorite'),
      isInTrash: anyNamed('isInTrash'),
      tag: anyNamed('tag'),
      folderId: anyNamed('folderId'),
      lastDocument: anyNamed('lastDocument'),
    ),
  ).thenAnswer((_) => Stream.value(defaultNotes));
  when(mockRepo.notesStream()).thenAnswer((_) => Stream.value(defaultNotes));
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
  await tester.pumpWidget(
    fluent.FluentApp(
      home: fluent.FluentTheme(
        data: fluent.FluentThemeData.light(),
        child: NotesScreen(updateService: updateService ?? MockUpdateService()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50)); // Reduced duration
}
