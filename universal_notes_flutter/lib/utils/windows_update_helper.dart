import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

/// A helper class for handling application updates on Windows.
class WindowsUpdateHelper {
  /// Checks for updates and prompts the user to install them.
  static Future<void> checkForUpdate({
    required void Function(String) onStatusChange,
    required void Function(String) onError,
    required void Function() onNoUpdate,
    required void Function() onCheckFinished,
  }) async {
    onStatusChange('Verificando atualizações...');
    final updateService = UpdateService();
    final result = await updateService.checkForUpdate();

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        onStatusChange('Atualização encontrada. Baixando...');
        await _downloadAndInstallUpdate(
          result.updateInfo!,
          onStatusChange: onStatusChange,
          onError: onError,
          onCheckFinished: onCheckFinished,
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
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}\\notes_installer.exe';
      final response = await http.get(Uri.parse(updateInfo.downloadUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        onStatusChange('Download concluído. Instalando...');
        try {
          await Process.run(filePath, [], runInShell: true);
          exit(0); // App closes to allow the installer to run.
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
    }
  }
}
