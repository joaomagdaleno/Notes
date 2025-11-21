import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

// Mock class for testing purposes.
class MockUpdateService extends UpdateService {
  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    return UpdateCheckResult(UpdateCheckStatus.noUpdate);
  }
}

void main() {
  // Solves test hanging issues by ensuring the Flutter binding is initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Use FFI database factory
    databaseFactory = databaseFactoryFfi;
    // Provide an in-memory database for testing
    NoteRepository.instance.dbPath = inMemoryDatabasePath;

    PackageInfo.setMockInitialValues(
      appName: 'Universal Notes',
      packageName: 'com.example.universal_notes_flutter',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() async {
    // Close the database before each test to ensure a clean state
    await NoteRepository.instance.close();
  });

  testWidgets('MyApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the home page is displayed.
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  testWidgets('NotesScreen displays notes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotesScreen(
          notesFuture: Future.value(<Note>[]),
          updateService: MockUpdateService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    // Verify that the "No notes found" message is displayed.
    expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
  });
}
