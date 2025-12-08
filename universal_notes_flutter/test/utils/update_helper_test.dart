import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'dart:io';

import 'update_helper_test.mocks.dart';

// Gera mocks para as classes que vamos precisar simular
@GenerateMocks([http.Client, UpdateService])
void main() {
  group('UpdateHelper', () {
    late MockUpdateService mockUpdateService;

    setUp(() {
      mockUpdateService = MockUpdateService();
    });

    // --- Testes existentes (que já estavam cobertos) ---

    testWidgets('shows update dialog when update is available', (WidgetTester tester) async {
      final updateInfo = UpdateInfo(
        version: '1.0.1',
        downloadUrl: 'https://example.com/app.apk',
      );

      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(
                UpdateCheckStatus.updateAvailable,
                updateInfo: updateInfo,
              ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: false,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsOneWidget);
      expect(find.text('Uma nova versão (1.0.1) está disponível. Deseja baixar e instalar?'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
      expect(find.text('Sim, atualizar'), findsOneWidget);
    });

    testWidgets('shows no update message when no update is available', (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: true,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Você já tem a versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error message when update check fails', (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(
                UpdateCheckStatus.error,
                errorMessage: 'Network error',
              ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: true,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Network error'), findsOneWidget);
    });

    // --- Novos Testes para Aumentar a Cobertura ---

    group('Update Installation Flow', () {
      late MockUpdateService mockUpdateService;
      late MockClient mockHttpClient;

      setUp(() {
        mockUpdateService = MockUpdateService();
        mockHttpClient = MockClient();
      });

      testWidgets('shows permission denied message on Android', (WidgetTester tester) async {
        // Simula que uma atualização está disponível
        final updateInfo = UpdateInfo(
          version: '1.0.2',
          downloadUrl: 'https://example.com/app.apk',
        );
        when(mockUpdateService.checkForUpdate())
            .thenAnswer((_) async => UpdateCheckResult(
                  UpdateCheckStatus.updateAvailable,
                  updateInfo: updateInfo,
                ));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpdateHelper.checkForUpdate(
                  context,
                  isManual: false,
                  updateService: mockUpdateService,
                ),
                child: const Text('Check for updates'),
              ),
            ),
          ),
        ));

        // 1. Abre o diálogo de atualização
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(find.text('Atualização Disponível'), findsOneWidget);

        // 2. Toca no botão para atualizar
        await tester.tap(find.text('Sim, atualizar'));
        await tester.pumpAndSettle();

        // 3. Verifica se a mensagem de permissão negada é exibida
        expect(find.text('Permissão para instalar pacotes é necessária para a atualização.'), findsOneWidget);
      });

      testWidgets('shows error message when download fails', (WidgetTester tester) async {
        // Simula que uma atualização está disponível
        final updateInfo = UpdateInfo(
          version: '1.0.3',
          downloadUrl: 'https://example.com/help.apk',
        );
        when(mockUpdateService.checkForUpdate())
            .thenAnswer((_) async => UpdateCheckResult(
                  UpdateCheckStatus.updateAvailable,
                  updateInfo: updateInfo,
                ));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpdateHelper.checkForUpdate(
                  context,
                  isManual: false,
                  updateService: mockUpdateService,
                ),
                child: const Text('Check for updates'),
              ),
            ),
          ),
        ));

        // 1. Abre o diálogo de atualização
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // 2. Toca no botão para atualizar
        await tester.tap(find.text('Sim, atualizar'));
        await tester.pumpAndSettle();

        // 3. Verifica se a mensagem de erro de download é exibida
        // (Isso cobre o bloco `catch` em `_downloadAndInstallUpdate`)
        expect(find.textContaining('Erro na atualização:'), findsOneWidget);
      });
    });
  });
}
