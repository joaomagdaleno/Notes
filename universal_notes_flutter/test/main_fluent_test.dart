import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/fluent_note_card.dart';

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

  // Helper to create the test widget.
  // The FluentApp needs to be wrapped in a MaterialApp and Scaffold to provide
  // the ScaffoldMessenger context that NotesScreen relies on.
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: fluent.FluentApp(
          home: child,
        ),
      ),
    );
  }

  group('MyFluentApp Tests', () {
    testWidgets('builds FluentApp with correct title and theme',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyFluentApp());

      // Verify that the app builds a FluentApp.
      final fluentApp =
          tester.widget<fluent.FluentApp>(find.byType(fluent.FluentApp));
      expect(fluentApp, isNotNull);
      expect(fluentApp.title, 'Universal Notes');
      expect(fluentApp.home, isA<NotesScreen>());
      expect(fluentApp.theme?.accentColor, fluent.Colors.blue);
    });
  });

  group('NotesScreen (Fluent UI) Tests', () {
    testWidgets('shows progress indicator and then empty message',
        (WidgetTester tester) async {
      // Arrange
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows, // Force Fluent UI
        ),
      ));

      // Assert - Check for progress indicator
      expect(find.byType(fluent.ProgressRing), findsOneWidget);

      // Act
      await tester.pumpAndSettle();

      // Assert - Check for the empty message
      expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
      expect(find.byType(fluent.NavigationView), findsOneWidget);
      verify(mockUpdateService.checkForUpdate()).called(1);
    });

    testWidgets('displays a list of notes using FluentNoteCard',
        (WidgetTester tester) async {
      // Arrange
      final notes = [
        Note(
          id: '1',
          title: 'Fluent Note 1',
          content: 'Content 1',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Fluent Note 2',
          content: 'Content 2',
          date: DateTime.now(),
        ),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Fluent Note 1'), findsOneWidget);
      expect(find.text('Fluent Note 2'), findsOneWidget);
      expect(find.byType(FluentNoteCard), findsNWidgets(2));
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
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();
      final viewModeButton =
          find.widgetWithText(fluent.CommandBarButton, 'Mudar Visualização');
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

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert: Initially shows 'All Note' and 'Favorite Note'
      expect(find.text('All Note'), findsOneWidget);
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);

      // Act: Tap on Favorites
      await tester.tap(find.widgetWithText(fluent.PaneItem, 'Favoritos'));
      await tester.pumpAndSettle();

      // Assert: Shows only 'Favorite Note'
      expect(find.text('All Note'), findsNothing);
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('Trash Note'), findsNothing);

      // Act: Tap on Trash
      await tester.tap(find.widgetWithText(fluent.PaneItem, 'Lixeira'));
      await tester.pumpAndSettle();

      // Assert: Shows only 'Trash Note'
      expect(find.text('All Note'), findsNothing);
      expect(find.text('Favorite Note'), findsNothing);
      expect(find.text('Trash Note'), findsOneWidget);
    });

    testWidgets('navigates to editor when "Nova nota" is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);
      when(mockNoteRepository.insertNote(any))
          .thenAnswer((_) async => 'new_id');

      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();

      // Act
      await tester
          .tap(find.widgetWithText(fluent.CommandBarButton, 'Nova nota'));
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
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FluentNoteCard));
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
          debugPlatform: TargetPlatform.windows,
        ),
      ));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error: Exception: Failed to load'), findsOneWidget);
    });
  });
}
