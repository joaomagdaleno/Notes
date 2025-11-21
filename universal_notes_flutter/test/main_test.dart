import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

// This mock is required for the test but isn't referenced from the main
// function, which would normally cause an "unreachable_from_main" lint error.
// ignore: unreachable_from_main
class MockUpdateService extends UpdateService {
  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    return UpdateCheckResult(UpdateCheckStatus.noUpdate);
  }
}

// This mock is required for the test but isn't referenced from the main
// function, which would normally cause an "unreachable_from_main" lint error.
// ignore: unreachable_from_main
class NotesScreenMock extends NotesScreen {
  final Future<List<Note>> mockNotes;

  const NotesScreenMock({
    required this.mockNotes,
    super.updateService,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenMockState();
}

// This mock is required for the test but isn't referenced from the main
// function, which would normally cause an "unreachable_from_main" lint error.
// ignore: unreachable_from_main
class _NotesScreenMockState extends _NotesScreenState {
  @override
  void initState() {
    _notesFuture = (widget as NotesScreenMock).mockNotes;
    super.initState();
  }
}

void main() {
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
        home: NotesScreenMock(
          mockNotes: Future.value([]),
          updateService: MockUpdateService(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
  });
}
