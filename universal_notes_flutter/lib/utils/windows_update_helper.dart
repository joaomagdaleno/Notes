import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_notes_flutter/services/update_service.dart';

class WindowsUpdateHelper {
  static Future<void> checkForUpdate(
    BuildContext context, {
    required VoidCallback onCheckStarted,
    required VoidCallback onCheckFinished,
  }) async {
    onCheckStarted();

    final updateService = UpdateService();
    final result = await updateService.checkForUpdate();

    if (!context.mounted) {
      onCheckFinished();
      return;
    }

    onCheckFinished(); // Stop the loading indicator before showing the result dialog

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        _showUpdateDialog(context, result.updateInfo!);
        break;
      case UpdateCheckStatus.noUpdate:
        _showNoUpdateDialog(context);
        break;
      case UpdateCheckStatus.error:
        _showErrorDialog(context, result.errorMessage);
        break;
    }
  }

  static void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('Nova versão disponível: ${updateInfo.version}'),
        content: const Text('Deseja baixar e instalar a nova versão?'),
        actions: [
          Button(
            child: const Text('Agora não'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Sim'),
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(context, updateInfo);
            },
          ),
        ],
      ),
    );
  }

  static void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Nenhuma atualização encontrada'),
        content: const Text('Você já está com a versão mais recente.'),
        actions: [
          FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String? message) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Erro ao verificar atualizações'),
        content: Text(message ?? 'Ocorreu um erro desconhecido.'),
        actions: [
          FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstallUpdate(BuildContext context, UpdateInfo updateInfo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ContentDialog(
        title: Text('Baixando atualização...'),
        content: ProgressRing(),
      ),
    );

    try {
      final tempDir = await getTemporaryDirectory();
      await tempDir.create(recursive: true); // Ensure the directory exists
      final filePath = '${tempDir.path}\\notes_installer.exe';

      final response = await http.get(Uri.parse(updateInfo.downloadUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (!context.mounted) return;
        Navigator.pop(context); // Dismiss download dialog

        // Show installation dialog
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Pronto para instalar'),
            content: const Text('A atualização foi baixada. O aplicativo será fechado para iniciar a instalação.'),
            actions: [
              FilledButton(
                child: const Text('Instalar agora'),
                onPressed: () async {
                  await Process.run(filePath, [], runInShell: true);
                  exit(0);
                },
              ),
            ],
          ),
        );
      } else {
        throw Exception('Falha ao baixar o arquivo.');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss download dialog
      _showErrorDialog(context, 'Erro durante o download: $e');
    }
  }
}
