import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  late MockNoteRepository mockNoteRepository;
  late MockUpdateService mockUpdateService;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockUpdateService = MockUpdateService();

    // Default stubs
    when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);
    when(mockUpdateService.checkForUpdate()).thenAnswer(
      (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
    );
  });

  // A helper function to create the widget tree with necessary ancestors
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child), // Ensure a Scaffold is present
    );
  }

  group('MyApp Tests', () {
    testWidgets('builds MaterialApp with correct title and theme',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app builds a MaterialApp.
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp, isNotNull);
      expect(materialApp.title, 'Universal Notes');
      expect(materialApp.home, isA<NotesScreen>());
      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });

  group('NotesScreen (Material UI) Tests', () {
    testWidgets('shows loading indicator and then empty message',
        (WidgetTester tester) async {
      // Arrange
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));

      // Assert - Check for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act - Let the future complete
      await tester.pumpAndSettle();

      // Assert - Check for the empty message
      expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
      verify(mockUpdateService.checkForUpdate()).called(1);
    });

    testWidgets('displays a list of notes', (WidgetTester tester) async {
      // Arrange
      final notes = [
        Note(
            id: '1',
            title: 'Test Note 1',
            content: 'Content 1',
            date: DateTime.now()),
        Note(
            id: '2',
            title: 'Test Note 2',
            content: 'Content 2',
            date: DateTime.now()),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.byType(NoteCard), findsNWidgets(2));
    });

    testWidgets('cycles through view modes correctly',
        (WidgetTester tester) async {
      // Arrange
      final notes = [
        Note(
            id: '1',
            title: 'Test Note',
            content: 'Content',
            date: DateTime.now())
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));
      await tester.pumpAndSettle();
      final viewModeButton = find.byIcon(Icons.view_agenda_outlined);
      expect(viewModeButton, findsOneWidget);

      // Act & Assert - Cycle through all view modes
      // Initial: gridMedium -> GridView
      expect(find.byType(GridView), findsOneWidget);
      // Tap 1: -> gridLarge -> GridView
      await tester.tap(viewModeButton);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      // Tap 2: -> list -> GridView
      await tester.tap(viewModeButton);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      // Tap 3: -> listSimple -> ListView
      await tester.tap(viewModeButton);
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
      // Tap 4: -> gridSmall -> GridView
      await tester.tap(viewModeButton);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('filters notes for Favorites and Trash',
        (WidgetTester tester) async {
      // Arrange
      final notes = [
        Note(
            id: '1',
            title: 'All Note',
            content: 'Content',
            date: DateTime.now()),
        Note(
            id: '2',
            title: 'Favorite Note',
            content: 'Content',
            isFavorite: true,
            date: DateTime.now()),
        Note(
            id: '3',
            title: 'Trash Note',
            content: 'Content',
            isInTrash: true,
            date: DateTime.now()),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: NotesScreen(
            notesFuture: mockNoteRepository.getAllNotes(),
            updateService: mockUpdateService,
            debugPlatform: TargetPlatform.android,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Assert: Initially shows 'All Note' and 'Favorite Note'
      expect(find.text('All Note'), findsOneWidget);
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);

      // Act: Tap on Favorites
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();

      // Assert: Shows only 'Favorite Note'
      expect(find.text('All Note'), findsNothing);
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);

      // Act: Tap on Trash
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lixeira'));
      await tester.pumpAndSettle();

      // Assert: Shows only 'Trash Note'
      expect(find.text('All Note'), findsNothing);
      expect(find.text('Favorite Note'), findsNothing);
      expect(find.text('Trash Note'), findsOneWidget);
    });

    testWidgets('navigates to editor when FAB is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);
      when(mockNoteRepository.insertNote(any))
          .thenAnswer((_) async => 'new_id');

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NoteEditorScreen), findsOneWidget);
    });

    testWidgets('navigates to editor when a note card is tapped',
        (WidgetTester tester) async {
      // Arrange
      final note = Note(
        id: '1',
        title: 'Test Note',
        content: 'Content',
        date: DateTime.now(),
      );
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(NoteCard));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NoteEditorScreen), findsOneWidget);
    });

    testWidgets('shows error message when loading notes fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockNoteRepository.getAllNotes())
          .thenThrow(Exception('Failed to load'));

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error: Exception: Failed to load'), findsOneWidget);
    });

    testWidgets('moves a note to trash via long-press context menu',
        (WidgetTester tester) async {
      // Arrange
      final note = Note(
        id: '1',
        title: 'Note to trash',
        content: 'Content',
        date: DateTime.now(),
      );
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);
      when(mockNoteRepository.updateNote(any)).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert: Note is initially present
      expect(find.text('Note to trash'), findsOneWidget);

      // Act
      await tester.longPress(find.byType(NoteCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para a lixeira'));
      await tester.pumpAndSettle();

      // Verify that updateNote was called correctly
      final captured =
          verify(mockNoteRepository.updateNote(captureAny)).captured;
      expect(captured.first.isInTrash, isTrue);
    });

    testWidgets('shows NavigationRail on larger screens',
        (WidgetTester tester) async {
      // Set screen size to simulate a tablet/desktop
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Arrange
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.android,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    });
  });
}
