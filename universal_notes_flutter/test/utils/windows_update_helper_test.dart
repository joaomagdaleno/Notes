// test/utils/windows_update_helper_test.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';

import 'windows_update_helper_test.mocks.dart';

@GenerateMocks([UpdateService, http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsUpdateHelper', () {
    late MockUpdateService mockUpdateService;
    late MockClient mockHttpClient;
    final testUpdateInfo = UpdateInfo(
      version: '1.0.1',
      downloadUrl: 'https://example.com/notes_installer.exe',
    );

    late List<String> statusChanges;
    late List<String> errors;
    late int noUpdateCount;
    late int checkFinishedCount;
    late int exitCode;
    late List<String> processesRun;

    setUp(() {
      mockUpdateService = MockUpdateService();
      mockHttpClient = MockClient();
      statusChanges = [];
      errors = [];
      noUpdateCount = 0;
      checkFinishedCount = 0;
      exitCode = -1;
      processesRun = [];

      // Mock path_provider MethodChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              return Directory.systemTemp.path;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
    });

    // Mock process runner that succeeds
    Future<ProcessResult> mockProcessRunner(
      String executable,
      List<String> arguments, {
      bool runInShell = false,
    }) async {
      processesRun.add(executable);
      return ProcessResult(0, 0, '', '');
    }

    // Mock process runner that throws
    Future<ProcessResult> mockProcessRunnerThatThrows(
      String executable,
      List<String> arguments, {
      bool runInShell = false,
    }) async {
      throw Exception('Process failed to start');
    }

    // Mock exit handler
    void mockExitHandler(int code) {
      exitCode = code;
    }

    // --- checkForUpdate Method Tests ---

    group('checkForUpdate', () {
      test('shows "Verificando atualizações..." status on start', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
        );

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
        );

        expect(statusChanges.first, 'Verificando atualizações...');
      });

      test(
        'calls onNoUpdate and onCheckFinished when no update available',
        () async {
          when(mockUpdateService.checkForUpdate()).thenAnswer(
            (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
          );

          await WindowsUpdateHelper.checkForUpdate(
            onStatusChange: statusChanges.add,
            onError: errors.add,
            onNoUpdate: () => noUpdateCount++,
            onCheckFinished: () => checkFinishedCount++,
            updateService: mockUpdateService,
          );

          expect(noUpdateCount, 1);
          expect(checkFinishedCount, 1);
          expect(errors, isEmpty);
        },
      );

      test('calls onError with message and onCheckFinished on error', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.error,
            errorMessage: 'Falha na conexão',
          ),
        );

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
        );

        expect(errors, ['Falha na conexão']);
        expect(checkFinishedCount, 1);
        expect(noUpdateCount, 0);
      });

      test(
        'calls onError with default message when errorMessage is null',
        () async {
          when(mockUpdateService.checkForUpdate()).thenAnswer(
            (_) async => UpdateCheckResult(UpdateCheckStatus.error),
          );

          await WindowsUpdateHelper.checkForUpdate(
            onStatusChange: statusChanges.add,
            onError: errors.add,
            onNoUpdate: () => noUpdateCount++,
            onCheckFinished: () => checkFinishedCount++,
            updateService: mockUpdateService,
          );

          expect(errors, ['Ocorreu um erro desconhecido.']);
          expect(checkFinishedCount, 1);
        },
      );
    });

    // --- _downloadAndInstallUpdate Method Tests ---

    group('_downloadAndInstallUpdate (via checkForUpdate)', () {
      test('successful download, process run, and exit', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: testUpdateInfo,
          ),
        );

        when(
          mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
        ).thenAnswer((_) async => http.Response('fake exe content', 200));

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
          httpClient: mockHttpClient,
          processRunner: mockProcessRunner,
          exitHandler: mockExitHandler,
        );

        expect(statusChanges, contains('Verificando atualizações...'));
        expect(statusChanges, contains('Atualização encontrada. Baixando...'));
        expect(statusChanges, contains('Download concluído. Instalando...'));
        expect(processesRun.length, 1);
        expect(processesRun.first, contains('notes_installer.exe'));
        expect(exitCode, 0);
        expect(errors, isEmpty);
      });

      test('calls onError when HTTP returns non-200 status', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: testUpdateInfo,
          ),
        );

        when(
          mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
          httpClient: mockHttpClient,
          processRunner: mockProcessRunner,
          exitHandler: mockExitHandler,
        );

        expect(errors.length, 1);
        expect(errors.first, contains('Erro durante o download'));
        expect(errors.first, contains('Status 404'));
        expect(checkFinishedCount, 1);
        expect(exitCode, -1); // Exit should not be called
      });

      test('calls onError when HTTP request throws exception', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: testUpdateInfo,
          ),
        );

        when(
          mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
        ).thenThrow(const SocketException('No internet'));

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
          httpClient: mockHttpClient,
          processRunner: mockProcessRunner,
          exitHandler: mockExitHandler,
        );

        expect(errors.length, 1);
        expect(errors.first, contains('Erro durante o download'));
        expect(checkFinishedCount, 1);
      });

      test('calls onError when process runner throws exception', () async {
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: testUpdateInfo,
          ),
        );

        when(
          mockHttpClient.get(Uri.parse(testUpdateInfo.downloadUrl)),
        ).thenAnswer((_) async => http.Response('fake exe content', 200));

        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
          httpClient: mockHttpClient,
          processRunner: mockProcessRunnerThatThrows,
          exitHandler: mockExitHandler,
        );

        expect(errors.length, 1);
        expect(errors.first, contains('Falha ao iniciar o instalador'));
        expect(checkFinishedCount, 1);
        expect(exitCode, -1); // Exit should not be called on failure
      });

      test('uses internal client and handles cleanup', () async {
        final badInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: 'http://invalid-url.local/installer.exe',
        );

        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: badInfo,
          ),
        );

        // We do NOT pass httpClient, so it creates one.
        // We use bad URL so it fails (or times out)
        await WindowsUpdateHelper.checkForUpdate(
          onStatusChange: statusChanges.add,
          onError: errors.add,
          onNoUpdate: () => noUpdateCount++,
          onCheckFinished: () => checkFinishedCount++,
          updateService: mockUpdateService,
          // no httpClient
          processRunner: mockProcessRunner,
          exitHandler: mockExitHandler,
        );

        // It should fail due to bad URL
        expect(errors, isNotEmpty);
        expect(checkFinishedCount, 1);
        // The fact it finished means finally block ran.
        // Coverage should show the 'if (client == null) { client.close() }'
        // executed.
      });
    });
  });
}
