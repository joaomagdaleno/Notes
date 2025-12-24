@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/editor_widget.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/editor/document.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

void main() {
  late PathProviderPlatform platform;

  setUpAll(() async {
    platform = FakePathProviderPlatform();
    PathProviderPlatform.instance = platform;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    NoteRepository.instance.dbPath = inMemoryDatabasePath;
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('EditorWidget types text', (WidgetTester tester) async {
    var currentDoc = DocumentModel.fromPlainText('');
    var currentSelection = const TextSelection.collapsed(offset: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorWidget(
            document: currentDoc,
            selection: currentSelection,
            onDocumentChanged: (doc) => currentDoc = doc,
            onSelectionChanged: (sel) => currentSelection = sel,
          ),
        ),
      ),
    );

    // Focus the editor
    final state = tester.state<EditorWidgetState>(find.byType(EditorWidget));
    state.focusNode.requestFocus();
    await tester.pump();

    // Type 'A'
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'A');
    await tester.pump();

    expect(currentDoc.toPlainText(), 'A');
    expect(currentSelection.baseOffset, 1);
  });

  testWidgets('EditorWidget handles backspace', (WidgetTester tester) async {
    var currentDoc = DocumentModel.fromPlainText('A');
    var currentSelection = const TextSelection.collapsed(offset: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorWidget(
            document: currentDoc,
            selection: currentSelection,
            onDocumentChanged: (doc) => currentDoc = doc,
            onSelectionChanged: (sel) => currentSelection = sel,
          ),
        ),
      ),
    );

    final state = tester.state<EditorWidgetState>(find.byType(EditorWidget));
    state.focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(currentDoc.toPlainText(), '');
    expect(currentSelection.baseOffset, 0);
  });

  testWidgets('EditorWidget triggers bold shortcut', (
    WidgetTester tester,
  ) async {
    var currentDoc = DocumentModel.fromPlainText('Text');
    TextSelection? currentSelection = const TextSelection(
      baseOffset: 0,
      extentOffset: 4,
    );
    StyleAttribute? toggledAttribute;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorWidget(
            document: currentDoc,
            selection: currentSelection,
            onDocumentChanged: (doc) => currentDoc = doc,
            onSelectionChanged: (sel) => currentSelection = sel,
            onStyleToggle: (attr) => toggledAttribute = attr,
          ),
        ),
      ),
    );

    final state = tester.state<EditorWidgetState>(find.byType(EditorWidget));
    state.focusNode.requestFocus();
    await tester.pump();

    // Ctrl+B
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();

    expect(toggledAttribute, StyleAttribute.bold);
  });
}

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      '/tmp/fake_app_documents';
  @override
  Future<String?> getTemporaryPath() async => '/tmp/fake_temp';
  @override
  Future<String?> getApplicationSupportPath() async => '/tmp/fake_app_support';
  @override
  Future<String?> getLibraryPath() async => '/tmp/fake_library';
  @override
  Future<String?> getApplicationCachePath() async => '/tmp/fake_cache';
  @override
  Future<String?> getExternalStoragePath() async =>
      '/tmp/fake_external_storage';
  @override
  Future<List<String>?> getExternalCachePaths() async => [
    '/tmp/fake_external_cache',
  ];
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['/tmp/fake_external_storage_path'];
  @override
  Future<String?> getDownloadsPath() async => '/tmp/fake_downloads';
}
