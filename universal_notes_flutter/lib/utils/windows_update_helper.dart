import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

class WindowsUpdateHelper {
  static Future<void> checkForUpdate({
    required Function(String) onStatusChange,
    required Function(String) onError,
    required Function() onNoUpdate,
    required Function() onCheckFinished,
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
        break;
      case UpdateCheckStatus.noUpdate:
        onNoUpdate();
        onCheckFinished();
        break;
      case UpdateCheckStatus.error:
        onError(result.errorMessage ?? 'Ocorreu um erro desconhecido.');
        onCheckFinished();
        break;
    }
  }

  static Future<void> _downloadAndInstallUpdate(
    UpdateInfo updateInfo, {
    required Function(String) onStatusChange,
    required Function(String) onError,
    required Function() onCheckFinished,
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
        } catch (e) {
          onError('Falha ao iniciar o instalador: $e');
          onCheckFinished();
        }
      } else {
        throw Exception('Falha ao baixar o arquivo: Status ${response.statusCode}');
      }
    } catch (e) {
      onError('Erro durante o download: $e');
      onCheckFinished();
    }
  }
}
