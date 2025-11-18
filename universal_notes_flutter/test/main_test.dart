import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

void main() {
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Use FFI database factory
    databaseFactory = databaseFactoryFfi;
    // Provide an in-memory database for testing
    NoteRepository.instance.dbPath = inMemoryDatabasePath;
  });

  testWidgets('MyApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the home page is displayed.
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  testWidgets('NotesScreen displays notes', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotesScreen()));
    await tester.pumpAndSettle();

    // Verify that the "No notes found" message is displayed.
    expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
  });
}
