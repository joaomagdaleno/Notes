import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:notes_hub/services/update_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Function signature for running a process.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  bool runInShell,
});

/// Function signature for exiting the application.
typedef ExitHandler = void Function(int code);

/// A helper class for handling application updates on Windows.
class WindowsUpdateHelper {
  /// Checks for updates and prompts the user to install them.
  static Future<void> checkForUpdate({
    required void Function(String) onStatusChange,
    required void Function(String) onError,
    required void Function() onNoUpdate,
    required void Function() onCheckFinished,
    UpdateService? updateService,
    http.Client? httpClient,
    ProcessRunner? processRunner,
    ExitHandler? exitHandler,
  }) async {
    onStatusChange('Verificando atualizações...');
    final service = updateService ?? UpdateService();
    final result = await service.checkForUpdate();

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        onStatusChange('Atualização encontrada. Baixando...');
        await _downloadAndInstallUpdate(
          result.updateInfo!,
          onStatusChange: onStatusChange,
          onError: onError,
          onCheckFinished: onCheckFinished,
          httpClient: httpClient,
          processRunner: processRunner,
          exitHandler: exitHandler,
        );
      case UpdateCheckStatus.noUpdate:
        onNoUpdate();
        onCheckFinished();
      case UpdateCheckStatus.error:
        onError(result.errorMessage ?? 'Ocorreu um erro desconhecido.');
        onCheckFinished();
    }
  }

  static Future<void> _downloadAndInstallUpdate(
    UpdateInfo updateInfo, {
    required void Function(String) onStatusChange,
    required void Function(String) onError,
    required void Function() onCheckFinished,
    http.Client? httpClient,
    ProcessRunner? processRunner,
    ExitHandler? exitHandler,
  }) async {
    final client = httpClient ?? http.Client();
    final runProcess = processRunner ?? Process.run;
    final exitApp = exitHandler ?? exit;

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, 'notes_installer.exe');
      final response = await client.get(Uri.parse(updateInfo.downloadUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        onStatusChange('Download concluído. Instalando...');
        try {
          await runProcess(filePath, [], runInShell: true);
          exitApp(0); // App closes to allow the installer to run.
        } on Exception catch (e) {
          onError('Falha ao iniciar o instalador: $e');
          onCheckFinished();
        }
      } else {
        throw Exception(
          'Falha ao baixar o arquivo: Status ${response.statusCode}',
        );
      }
    } on Exception catch (e) {
      onError('Erro durante o download: $e');
      onCheckFinished();
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
