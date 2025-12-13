// test/main_fluent_test.dart

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Importação necessária para PointerDeviceKind
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';

// Importe o mock manual em vez do gerado
import 'mocks/mock_update_service_manual.dart';
import 'mocks/mocks.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockNoteRepository mockNoteRepository;
  late MockUpdateService mockUpdateService; // Agora usa o mock manual
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    mockUpdateService = MockUpdateService(); // Instancia o mock manual
    mockNavigatorObserver = MockNavigatorObserver();

    // Stub para o checkForUpdate usando o mock manual
    when(mockUpdateService.checkForUpdate())
        .thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      fluent.FluentApp(
        home: MyFluentApp(
          noteRepository: mockNoteRepository,
          updateService: mockUpdateService,
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group('MyFluentApp UI Tests', () {
    testWidgets('Deve renderizar a UI inicial com notas', (WidgetTester tester) async {
      final notes = [
        Note(id: '1', title: 'Nota Fluent 1', content: 'Conteúdo 1', date: DateTime.now()),
        Note(id: '2', title: 'Nota Fluent 2', content: 'Conteúdo 2', date: DateTime.now()),
      ];
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => notes);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.byType(NotesScreen), findsOneWidget);
      expect(find.text('Nota Fluent 1'), findsOneWidget);
      expect(find.text('Nota Fluent 2'), findsOneWidget);
      return; // CORREÇÃO: Adicionado return para satisfazer o linter
    });

    testWidgets('Deve alternar entre os modos de visualização', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      final viewButtonFinder = find.byIcon(fluent.FluentIcons.list);

      expect(viewButtonFinder, findsOneWidget);

      await tester.tap(viewButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byIcon(fluent.FluentIcons.grid), findsOneWidget);

      await tester.tap(find.byIcon(fluent.FluentIcons.grid));
      await tester.pumpAndSettle();
      expect(find.byIcon(fluent.FluentIcons.table), findsOneWidget);
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve navegar para a tela de nova nota ao clicar no botão', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => []);

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nova nota'));
      await tester.pumpAndSettle();

      verify(mockNavigatorObserver.didPush(any, any));
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve mover a nota para a lixeira com o menu de contexto', (WidgetTester tester) async {
      final note = Note(id: '1', title: 'Nota para Lixeira', content: 'Conteúdo', date: DateTime.now());
      when(mockNoteRepository.getAllNotes()).thenAnswer((_) async => [note]);
      when(mockNoteRepository.updateNote(any)).thenAnswer((_) async {});

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      final noteFinder = find.text('Nota para Lixeira');
      final gesture = await tester.startGesture(tester.getCenter(noteFinder), kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(fluent.MenuFlyoutItem, 'Move to Trash'));
      await tester.pumpAndSettle();

      final captured = verify(mockNoteRepository.updateNote(captureAny)).captured;
      expect(captured.single.isDeleted, isTrue);
      return; // CORREÇÃO: Adicionado return
    });

    testWidgets('Deve exibir SnackBar de erro se o carregamento de notas falhar', (WidgetTester tester) async {
      when(mockNoteRepository.getAllNotes()).thenThrow(Exception('Falha ao carregar'));

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erro ao carregar notas'), findsOneWidget);
      return; // CORREÇÃO: Adicionado return
    });
  });
}
