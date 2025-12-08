import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

import 'update_helper_test.mocks.dart';

@GenerateMocks([UpdateService])
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

      setUp(() {
        mockUpdateService = MockUpdateService();
      });

      // Helper para construir o widget de teste e reduzir repetição
      Widget createTestWidget({required VoidCallback onPressed}) {
        return MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: onPressed,
                child: const Text('Check for updates'),
              ),
            ),
          ),
        );
      }

      testWidgets('shows permission denied message on Android', (WidgetTester tester) async {
        // Configura o mock para retornar uma atualização disponível
        final updateInfo = UpdateInfo(
          version: '1.0.2',
          downloadUrl: 'https://example.com/app.apk',
        );
        when(mockUpdateService.checkForUpdate())
            .thenAnswer((_) async => UpdateCheckResult(
                  UpdateCheckStatus.updateAvailable,
                  updateInfo: updateInfo,
                ));

        // Configura o mock do canal de permissão para SIMULAR que a permissão foi NEGADA
        const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestPermission') {
              // Simula que o usuário negou a permissão
              return PermissionStatus.denied.value;
            }
            return null;
          },
        );

        try {
          // Constrói o widget, passando o override para forçar o caminho do Android
          await tester.pumpWidget(createTestWidget(
            onPressed: () => UpdateHelper.checkForUpdate(
              tester.element(find.byType(ElevatedButton)),
              isManual: false,
              updateService: mockUpdateService,
              isAndroidOverride: true, // <-- Chave para este teste
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
        } finally {
          // Limpa o mock para não afetar outros testes
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        }
      });

      testWidgets('shows error message when download fails', (WidgetTester tester) async {
        // Configura o mock para retornar uma atualização disponível
        final updateInfo = UpdateInfo(
          version: '1.0.3',
          downloadUrl: 'https://invalid-url-that-will-fail.com/app.apk', // URL inválida para forçar erro
        );
        when(mockUpdateService.checkForUpdate())
            .thenAnswer((_) async => UpdateCheckResult(
                  UpdateCheckStatus.updateAvailable,
                  updateInfo: updateInfo,
                ));

        // Configura o mock do canal de permissão para SIMULAR que a permissão foi CONCEDIDA
        const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestPermission') {
              // Simula que o usuário concedeu a permissão
              return PermissionStatus.granted.value;
            }
            return null;
          },
        );

        try {
          // Constrói o widget, passando o override para forçar o caminho do Android
          await tester.pumpWidget(createTestWidget(
            onPressed: () => UpdateHelper.checkForUpdate(
              tester.element(find.byType(ElevatedButton)),
              isManual: false,
              updateService: mockUpdateService,
              isAndroidOverride: true, // <-- Chave para este teste
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
        } finally {
          // Limpa o mock para não afetar outros testes
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        }
      });
    });
  });
}
