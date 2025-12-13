// test/main_material_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';

// Importe o mock manual
import 'mocks/mock_update_service_manual.dart';
import 'mocks/mocks.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockNoteRepository mockNoteRepository;
  late MockUpdateService mockUpdateService; // Usa o mock manual
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockUpdateService = MockUpdateService(); // Instancia o mock manual
    mockNavigatorObserver = MockNavigatorObserver();

    // Stub para o checkForUpdate
    when(mockUpdateService.checkForUpdate())
        .thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(
          noteRepository: mockNoteRepository,
          updateService: mockUpdateService,
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group('MyApp Material UI Tests', () {
    testWidgets('Deve renderizar a UI inicial com notas', (WidgetTester tester) async {
      final notes = [
        Note(id: '1', title: 'Nota 1', content: 'Conteúdo 1', date: DateTime.now()),
        Note(id: '2', title: 'Nota 2', content: 'Conteúdo 2', date: DateTime.now()),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Nota 1'), findsOneWidget);
      expect(find.text('Nota 2'), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsOneWidget);
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve alternar entre os modos de visualização (lista -> grid)', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_list), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_module), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve navegar para a tela de nova nota ao pressionar o FAB', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      verify(mockNavigatorObserver.didPush(any, any));
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve navegar para a tela de edição de nota ao tocar em uma nota', (WidgetTester tester) async {
      final note = Note(id: '1', title: 'Nota Editável', content: 'Conteúdo', date: DateTime.now());
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nota Editável'));
      await tester.pumpAndSettle();

      verify(mockNavigatorObserver.didPush(any, any));
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve mover a nota para a lixeira ao usar o menu de contexto', (WidgetTester tester) async {
      final note = Note(id: '1', title: 'Nota para Lixeira', content: 'Conteúdo', date: DateTime.now());
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);
      when(mockNoteRepository.updateNote(any)).thenAnswer((_) async {});

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Nota para Lixeira'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      final captured = verify(mockNoteRepository.updateNote(captureAny)).captured;
      expect(captured.single.isDeleted, isTrue);
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve exibir uma mensagem de erro se o carregamento de notas falhar', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenThrow(Exception('Falha ao carregar'));

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar notas'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      return; // CORREÇÃO: Adicionado return
    });
  });
}
