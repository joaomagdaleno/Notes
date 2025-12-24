@Tags(['widget'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await tearDownTest());

  group('NotesScreen Data Operations', () {
    testWidgets('displays notes when available', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final testNote = Note(
        id: '2',
        title: 'Test Note 2',
        content: 'Content',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        ownerId: 'user1',
      );

      SyncService.instance.firestoreRepository = createDefaultMockRepository([
        testNote,
      ]);
      await SyncService.instance.init();

      await pumpNotesScreen(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Note 2'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
