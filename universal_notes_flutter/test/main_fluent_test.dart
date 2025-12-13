import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
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

  Widget createTestWidget(Widget child) {
    return fluent.FluentApp(
      home: child,
    );
  }

  group('MyFluentApp Tests', () {
    testWidgets('builds FluentApp with correct title and theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyFluentApp());
      final fluentApp =
          tester.widget<fluent.FluentApp>(find.byType(fluent.FluentApp));
      expect(fluentApp.title, 'Universal Notes');
      expect(fluentApp.home, isA<ScaffoldMessenger>());
    });
  });

  group('NotesScreen (Fluent UI) Tests', () {
    testWidgets('shows progress indicator and then empty message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      expect(find.byType(fluent.ProgressRing), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma nota encontrada.'), findsOneWidget);
      verify(mockUpdateService.checkForUpdate()).called(1);
    });

    testWidgets('displays a list of notes using FluentNoteCard',
        (WidgetTester tester) async {
      final notes = [
        Note(
            id: '1',
            title: 'Fluent Note 1',
            content: 'Content 1',
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
      expect(find.text('Fluent Note 1'), findsOneWidget);
      expect(find.byType(FluentNoteCard), findsOneWidget);
    });

    testWidgets('navigates to editor when "Nova nota" is tapped',
        (WidgetTester tester) async {
      when(mockNoteRepository.insertNote(any))
          .thenAnswer((_) async => 'new_id');
      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();
      final buttonFinder = find.widgetWithText(fluent.CommandBarButton, 'Nova nota');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorScreen), findsOneWidget);
    });

    testWidgets('cycles through view modes correctly',
        (WidgetTester tester) async {
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
      final viewModeButtonFinder = find.widgetWithText(fluent.CommandBarButton, 'Mudar Visualização');
      expect(viewModeButtonFinder, findsOneWidget);

      // Initial: gridMedium -> GridView
      expect(find.byType(GridView), findsOneWidget);
      // Tap 1: -> gridLarge -> GridView
      await tester.tap(viewModeButtonFinder);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      // Tap 2: -> list -> GridView
      await tester.tap(viewModeButtonFinder);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      // Tap 3: -> listSimple -> ListView
      await tester.tap(viewModeButtonFinder);
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
      // Tap 4: -> gridSmall -> GridView
      await tester.tap(viewModeButtonFinder);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('filters notes for Favorites and Trash',
        (WidgetTester tester) async {
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
      await tester.tap(find.widgetWithText(fluent.PaneItem, 'Favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('Favorite Note'), findsOneWidget);
      expect(find.text('All Note'), findsNothing);
    });

    testWidgets('navigates to editor when a note card is tapped',
        (WidgetTester tester) async {
      final note = Note(
          id: '1',
          title: 'Test Note',
          content: 'Content',
          date: DateTime.now());
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);
      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FluentNoteCard));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorScreen), findsOneWidget);
    });

    testWidgets('shows error message when loading notes fails',
        (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes())
          .thenThrow(Exception('Failed to load'));
      await tester.pumpWidget(createTestWidget(
        NotesScreen(
          notesFuture: mockNoteRepository.getAllNotes(),
          updateService: mockUpdateService,
          debugPlatform: TargetPlatform.windows,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Error: Exception: Failed to load'), findsOneWidget);
    });
  });
}
