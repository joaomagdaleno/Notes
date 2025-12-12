// test/utils/update_helper_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

import 'update_helper_test.mocks.dart';

@GenerateMocks([UpdateService, http.Client])
void main() {
  group('UpdateHelper', () {
    late MockUpdateService mockUpdateService;
    late MockClient mockHttpClient;
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    final testUpdateInfo = UpdateInfo(
      version: '1.0.1',
      downloadUrl: 'https://example.com/app.apk',
    );

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockHttpClient = MockClient();
    });

    // --- Helper to setup MethodChannel mocks ---
    void setupMethodChannels({
      bool permissionGranted = true,
      String tempPath = '.',
      String openFileResult =
          '{"type":0, "message": "done"}', // 0 = ResultType.done
    }) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'requestPermission') {
                // 1 = granted, 0 = denied (simplified)
                return {
                  Permission.requestInstallPackages.value: permissionGranted
                      ? 1
                      : 0,
                };
              }
              return {
                Permission.requestInstallPackages.value: permissionGranted
                    ? 1
                    : 0,
              };
            },
          );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              return Directory.systemTemp.path;
            },
          );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('open_file'),
            (MethodCall methodCall) async {
              return jsonDecode(openFileResult);
            },
          );
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter.baseflow.com/permissions/methods'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('open_file'),
            null,
          );
    });

    Widget createTestWidget({required VoidCallback onPressed}) {
      return MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
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

    // --- Interaction Tests ---

    testWidgets('cancelling dialog does not trigger download', (tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsOneWidget);

      // Tap "Agora não"
      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsNothing);
      // Verify no download initiated (no http calls)
      verifyZeroInteractions(mockHttpClient);
    });

    testWidgets('shows no update snackbar', (tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            isManual: true,
            updateService: mockUpdateService,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Você já tem a versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error snackbar on check failure', (tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Check failed',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            isManual: true,
            updateService: mockUpdateService,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Check failed'), findsOneWidget);
    });

    // --- Download & Install Tests (Android) ---

    testWidgets('successful download and install on Android', (tester) async {
      setupMethodChannels();

      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(
        mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
      ).thenAnswer(
        (_) async => http.Response('fake apk content', 200),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true, // Force Android path
            httpClient: mockHttpClient,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Confirm update
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump(); // Close dialog
      await tester.pump(); // Start Async

      // Verify "Downloading" snackbar
      expect(
        find.text('Baixando atualização... Por favor, aguarde.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 100)); // Allow IO

      // Verify HTTP call
      verify(
        mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
      ).called(1);
    });

    testWidgets('shows error when download fails (404)', (tester) async {
      setupMethodChannels();

      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true,
            httpClient: mockHttpClient,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Falha no download. Status: 404'),
        findsOneWidget,
      );
    });

    // TODO(test): Skip - async dialog callback doesn't complete in test env
    testWidgets('shows error when OpenFile fails', skip: true, (tester) async {
      // Mock injected openFile function
      Future<OpenResult> mockOpenFile(String path) async {
        return OpenResult(type: ResultType.error, message: 'cannot open');
      }

      setupMethodChannels();

      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(mockHttpClient.get(any)).thenAnswer(
        (_) async => http.Response('content', 200),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true,
            httpClient: mockHttpClient,
            scaffoldMessengerKey: scaffoldMessengerKey,
            openFile: mockOpenFile,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Tap update button inside dialog
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump(); // Start the onPressed callback

      // Use runAsync to allow real async operations to complete
      await tester.runAsync(() async {
        // Give async operations time to complete
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });

      await tester.pump(); // Rebuild after async completes

      // Error should be visible now
      expect(
        find.textContaining('Erro na atualização'),
        findsOneWidget,
      );
    });

    testWidgets('shows permission denied snackbar', (tester) async {
      setupMethodChannels(permissionGranted: false);

      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Permissão para instalar pacotes é necessária'),
        findsOneWidget,
      );
      // Verify NO download happened
      verifyZeroInteractions(mockHttpClient);
    });
  });
}
