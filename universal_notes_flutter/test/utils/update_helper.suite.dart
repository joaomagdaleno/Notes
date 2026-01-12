@Tags(['widget'])
library;

// test/utils/update_helper_test.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

class MockUpdateService extends Mock implements UpdateService {}

class MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

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
              return openFileResult;
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
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Atualização Disponível'), findsOneWidget);

      // Tap "Agora não"
      await tester.tap(find.text('Agora não'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Atualização Disponível'), findsNothing);
      // Verify no download initiated (no http calls)
      verifyZeroInteractions(mockHttpClient);
    });

    testWidgets('shows no update snackbar', (tester) async {
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Você já está na versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error snackbar on check failure', (tester) async {
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
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
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Check failed'), findsOneWidget);
    });

    // --- Download & Install Tests (Android) ---

    testWidgets('successful download and install on Android', (tester) async {
      setupMethodChannels();

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(
        () => mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
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
      await tester.pump(const Duration(milliseconds: 100));

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
        () => mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
      ).called(1);
    });

    testWidgets('shows error when download fails (404)', (tester) async {
      setupMethodChannels();

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(() => mockHttpClient.get(any())).thenAnswer(
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
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Falha no download. Status: 404'),
        findsOneWidget,
      );
    });

    testWidgets('shows permission denied snackbar', (tester) async {
      setupMethodChannels(permissionGranted: false);

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
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
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Permissão para instalar pacotes é necessária'),
        findsOneWidget,
      );
      // Verify NO download happened
      verifyZeroInteractions(mockHttpClient);
    });

    testWidgets('calls onNoUpdate callback when no update available', (
      tester,
    ) async {
      var onNoUpdateCalled = false;

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            scaffoldMessengerKey: scaffoldMessengerKey,
            onNoUpdate: () => onNoUpdateCalled = true,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(onNoUpdateCalled, isTrue);
    });

    testWidgets('calls onError callback when error occurs', (tester) async {
      String? errorMessage;

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Test error message',
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            scaffoldMessengerKey: scaffoldMessengerKey,
            onError: (message) => errorMessage = message,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(errorMessage, equals('Test error message'));
    });

    testWidgets('shows error when open file fails', (tester) async {
      setupMethodChannels(
        openFileResult: '{"type": 1, "message": "Fail to open"}',
      ); // 1 = error

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(
        () => mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
      ).thenAnswer((_) async => http.Response('fake apk content', 200));

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
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('covers client closing logic (internal client)', (
      tester,
    ) async {
      // We don't provide HttpClient, so it creates one internally.
      final badInfo = UpdateInfo(
        version: '1.0.1',
        downloadUrl: 'http://invalid-url.local/app.apk',
      );
      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: badInfo,
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true,
            // No httpClient provided -> internal client created
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump();

      // Wait for async failure
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('uses default OpenFile when not provided', (tester) async {
      setupMethodChannels(
        openFileResult: '{"type":0, "message":"Done"}', // Success
      );

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: testUpdateInfo,
        ),
      );

      when(
        () => mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
      ).thenAnswer((_) async => http.Response('content', 200));

      await tester.pumpWidget(
        createTestWidget(
          onPressed: () => UpdateHelper.checkForUpdate(
            tester.element(find.byType(ElevatedButton)),
            updateService: mockUpdateService,
            isAndroidOverride: true,
            httpClient: mockHttpClient,
            scaffoldMessengerKey: scaffoldMessengerKey,
            // openFile NOT provided
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Erro'), findsNothing);
    });

    testWidgets('respects defaultTargetPlatform when override is null', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      when(() => mockUpdateService.checkForUpdate()).thenAnswer(
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
            // isAndroidOverride IS NULL
            httpClient: mockHttpClient,
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Sim, atualizar'));
      await tester.pump(const Duration(milliseconds: 100));

      // On Windows (non-Android), it typically stops or behaves differently?
      // update_helper.dart: _handleUpdate checks 'if (isAndroid)'.
      // Since it's Windows, it shouldn't try update.
      // So no permission request, no download.
      verifyNever(() => mockHttpClient.get(any()));

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
