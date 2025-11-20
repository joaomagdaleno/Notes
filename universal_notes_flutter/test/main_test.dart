import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

// ignore: unreachable_from_main
// Mock class for testing purposes.
class MockUpdateService extends UpdateService {
  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    return UpdateCheckResult(UpdateCheckStatus.noUpdate);
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

  testWidgets('MyApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the home page is displayed.
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  testWidgets('NotesScreen displays notes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    // Pump once to trigger the FutureBuilder's initial state (loading).
    // Then pump again to resolve the future and build the final UI.
    await tester.pump();
    await tester.pump();

    // Verify that the "No notes found" message is displayed.
    expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
  });
}
