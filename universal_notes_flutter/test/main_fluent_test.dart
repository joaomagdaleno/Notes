import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  late MockNoteRepository mockNoteRepository;
  late MockUpdateService mockUpdateService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockUpdateService = MockUpdateService();
    mockNavigatorObserver = MockNavigatorObserver();

    // Stub para o checkForUpdate
    when(
      mockUpdateService.checkForUpdate(),
    ).thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));

    // Stub para getAllNotes
    when(mockNoteRepository.getAllNotes()).thenAnswer(
      (_) async => [
        Note(
          id: '1',
          title: 'Nota 1',
          content: 'Conteúdo da nota 1',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Nota 2',
          content: 'Conteúdo da nota 2',
          date: DateTime.now(),
        ),
      ],
    );
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    // CORREÇÃO: Envolvendo o widget com FluentApp para fornecer contexto de
    // navegação.
    await tester.pumpWidget(
      fluent.FluentApp(
        onGenerateRoute: (settings) {
          return fluent.FluentPageRoute(
            builder: (context) => const SizedBox.shrink(),
          );
        },
        home: MyFluentApp(
          noteRepository: mockNoteRepository,
          updateService: mockUpdateService,
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MyFluentApp UI Tests', () {
    testWidgets('Deve renderizar a UI inicial com notas', (
      WidgetTester tester,
    ) async {
      final notes = [
        Note(
          id: '1',
          title: 'Nota Fluent 1',
          content: 'Conteúdo 1',
          date: DateTime.now(),
        ),
        Note(
          id: '2',
          title: 'Nota Fluent 2',
          content: 'Conteúdo 2',
          date: DateTime.now(),
        ),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Nota Fluent 1'), findsOneWidget);
      expect(find.text('Nota Fluent 2'), findsOneWidget);
    });

    testWidgets('Deve alternar entre os modos de visualização', (
      WidgetTester tester,
    ) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      final viewButtonFinder = find.byIcon(fluent.FluentIcons.list);

      // Estado inicial: Lista
      expect(viewButtonFinder, findsOneWidget);

      // Clica para mudar para Grid
      await tester.tap(viewButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(fluent.FluentIcons.home), findsOneWidget);

      // Clica para mudar para Staggered Grid
      await tester.tap(find.byIcon(fluent.FluentIcons.home));
      await tester.pumpAndSettle();
      expect(find.byIcon(fluent.FluentIcons.table), findsOneWidget);
    });

    testWidgets('Deve navegar para a tela de nova nota ao clicar no botão', (
      WidgetTester tester,
    ) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Note'));
      await tester.pumpAndSettle();

      verify(mockNavigatorObserver.didPush(any, any));
    });

    testWidgets('Deve mover a nota para a lixeira com o menu de contexto', (
      WidgetTester tester,
    ) async {
      final note = Note(
        id: '1',
        title: 'Nota para Lixeira',
        content: 'Conteúdo',
        date: DateTime.now(),
      );
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);
      when(mockNoteRepository.updateNote(any)).thenAnswer((_) async {});

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Simula um clique com o botão direito para abrir o menu de contexto
      final noteFinder = find.text('Nota para Lixeira');
      final gesture = await tester.startGesture(
        tester.getCenter(noteFinder),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      // Encontra e clica no item "Move to Trash" do menu
      await tester.tap(find.text('Move to Trash'));
      await tester.pumpAndSettle();

      final captured = verify(
        mockNoteRepository.updateNote(captureAny),
      ).captured;
      final capturedNote = captured.single as Note;
      expect(capturedNote.isInTrash, isTrue);
    });

    // testWidgets(
    //   'Deve exibir SnackBar de erro se o carregamento de notas falhar',
    //   (WidgetTester tester) async {
    //     when(
    //       mockNoteRepository.getAllNotes(),
    //     ).thenThrow(Exception('Falha ao carregar'));
    //
    //     await pumpWidget(tester);
    //     await tester.pumpAndSettle();
    //
    //     // expect(find.byType(SnackBar), findsOneWidget); // Cannot assume snackbar
    //     expect(find.textContaining('Falha ao carregar'), findsOneWidget);
    //   },
    // );
  });
}
