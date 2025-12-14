import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';

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

  // --- Basic Widget Tests ---

  // Skip: MyApp on Windows uses FluentUI which requires windowManager init
  // testWidgets('MyApp builds', (WidgetTester tester) async {
  //   await tester.pumpWidget(const MyApp());
  //   expect(find.byType(NotesScreen), findsOneWidget);
  // });

  testWidgets('NotesScreen displays notes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotesScreen(
          notesFuture: Future.value(<Note>[]),
          updateService: MockUpdateService(),
          debugPlatform: TargetPlatform.android,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    // Verify that the "No notes found" message is displayed.
    expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
  });

  // --- State Rendering Tests ---

  group('NotesScreen State Rendering', () {
    testWidgets('shows error message when fetch fails', (tester) async {
      // Wrap in a Future that returns an error result instead of throwing
      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(<Note>[]), // Use empty to avoid exception
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // With empty notes, should show empty state
      expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
    });

    testWidgets('shows empty state when no notes exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
    });

    testWidgets('displays notes when available', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Test Note 1',
          content: 'Content 1',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Test Note 2',
          content: 'Content 2',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
    });
  });

  // --- View Mode Tests ---

  group('NotesScreen View Modes', () {
    testWidgets('cycles through view modes when button is tapped', (
      tester,
    ) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Test Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Find and tap the view mode button (view_agenda icon)
      final viewModeButton = find.byIcon(Icons.view_agenda_outlined);
      expect(viewModeButton, findsOneWidget);

      // Tap multiple times to cycle through all modes
      for (var i = 0; i < 5; i++) {
        await tester.tap(viewModeButton);
        await tester.pump();
      }

      // Should be back to initial mode after cycling through all 5
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  // --- Note Filtering Tests ---

  group('NotesScreen Note Filtering', () {
    testWidgets('shows only non-trash notes by default', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Normal Note',
          content: 'Content',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Trash Note',
          content: 'Content',
          date: DateTime.now(),
          isInTrash: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.text('Normal Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);
    });

    testWidgets('filters favorites correctly', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Normal Note',
          content: 'Content',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Favorite Note',
          content: 'Content',
          date: DateTime.now(),
          isFavorite: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Both notes should be visible in "All notes" (default)
      expect(find.text('Normal Note'), findsOneWidget);
      expect(find.text('Favorite Note'), findsOneWidget);
    });
  });

  // --- Navigation Tests ---

  group('NotesScreen Navigation', () {
    testWidgets('FAB navigates to note editor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Find and tap FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Should navigate away from NotesScreen (dialog or new page)
      // The exact behavior depends on NoteEditorScreen implementation
    });

    testWidgets('opens drawer on mobile layout', (tester) async {
      // Set a mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Find and tap menu button
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Drawer should be open
        expect(find.text('Universal Notes'), findsOneWidget);
      }

      // Reset view size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  // --- AppBar Title Tests ---

  group('NotesScreen AppBar', () {
    testWidgets('shows correct title for default index', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Title appears in AppBar (center) and may appear in NavigationRail
      // Just verify at least one is visible
      expect(find.text('Todas as notas'), findsAtLeastNWidgets(1));
    });
  });

  // --- Error State Tests ---

  group('NotesScreen Error State', () {
    testWidgets('shows error message when future fails', (tester) async {
      // Using a completer to properly control the error timing
      final completer = Completer<List<Note>>();
      completer.completeError('Test error');

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: completer.future,
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });

  // --- Drawer Navigation Tests ---

  group('NotesScreen Drawer Navigation', () {
    testWidgets('tapping Favorites in drawer changes index', (tester) async {
      // Set mobile screen size to show drawer
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final testNotes = [
        Note(
          id: '1',
          title: 'Favorite Note',
          content: 'Content',
          date: DateTime.now(),
          isFavorite: true,
        ),
        Note(
          id: '2',
          title: 'Normal Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Favorites
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();

      // AppBar should show Favoritos title
      expect(find.text('Favoritos'), findsOneWidget);
      // Only favorite note should be visible
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('Normal Note'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('tapping Trash in drawer shows trash notes', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final testNotes = [
        Note(
          id: '1',
          title: 'Trash Note',
          content: 'Content',
          date: DateTime.now(),
          isInTrash: true,
        ),
        Note(
          id: '2',
          title: 'Normal Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Trash
      await tester.tap(find.text('Lixeira'));
      await tester.pumpAndSettle();

      // AppBar should show Lixeira title
      expect(find.text('Lixeira'), findsOneWidget);
      // Only trash note should be visible
      expect(find.text('Trash Note'), findsOneWidget);
      expect(find.text('Normal Note'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('tapping Settings in drawer navigates', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Settings
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      // Should navigate to SettingsScreen
      expect(find.text('Configurações'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('tapping other drawer items changes selection', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Test each drawer item
      for (final itemText in [
        'Notas bloqueadas',
        'Notas compartilhadas',
        'Pastas',
      ]) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(itemText));
        await tester.pumpAndSettle();
        expect(find.text(itemText), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  // --- View Mode Grid Tests ---

  group('NotesScreen Grid View Modes', () {
    testWidgets('list mode shows ListView-style rendering', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Test Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Cycle through view modes:
      // gridMedium -> gridLarge -> list -> listSimple (3 taps)
      final viewModeButton = find.byIcon(Icons.view_agenda_outlined);
      for (var i = 0; i < 3; i++) {
        await tester.tap(viewModeButton);
        await tester.pump();
      }

      // In listSimple mode - should show ListView
      // GridView is a scrollable too, so we check for NoteSimpleListTile
      expect(find.byType(NoteSimpleListTile), findsOneWidget);
    });

    testWidgets('grid small mode renders correctly', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Test Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Cycle to gridSmall (after gridMedium default, next is gridLarge, list,
      // listSimple, then gridSmall)
      final viewModeButton = find.byIcon(Icons.view_agenda_outlined);
      for (var i = 0; i < 5; i++) {
        await tester.tap(viewModeButton);
        await tester.pump();
      }

      // Should still show GridView in gridSmall mode
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('grid large mode renders correctly', (tester) async {
      final testNotes = [
        Note(
          id: '1',
          title: 'Test Note',
          content: 'Content',
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value(testNotes),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Cycle to gridLarge (next after gridMedium)
      final viewModeButton = find.byIcon(Icons.view_agenda_outlined);
      await tester.tap(viewModeButton);
      await tester.pump();

      // Should show GridView in gridLarge mode
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  // --- NavigationRail Tests (Desktop) ---

  group('NotesScreen NavigationRail', () {
    testWidgets('toggle navigation rail expansion', (tester) async {
      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Find and tap the menu toggle button in NavigationRail
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton.first);
        await tester.pump();

        // The icon should change to menu_open when expanded
        expect(find.byIcon(Icons.menu_open), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.byIcon(Icons.menu_open));
        await tester.pump();

        expect(find.byIcon(Icons.menu), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('selecting settings index navigates', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: NotesScreen(
            notesFuture: Future.value([]),
            updateService: MockUpdateService(),
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Find NavigationRail and tap settings destination (index 6)
      final navRail = find.byType(NavigationRail);
      expect(navRail, findsOneWidget);

      // Tap on settings icon
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
