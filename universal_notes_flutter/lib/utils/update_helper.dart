import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/update_service.dart';

class UpdateHelper {
  static Future<void> checkForUpdate(BuildContext context, {bool isManual = false}) async {
    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdate();

    if (context.mounted) {
      if (updateInfo != null) {
        _showUpdateSnackbar(context, updateInfo);
      } else {
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você já tem a versão mais recente.')),
          );
        }
      }
    }
  }

  static void _showUpdateSnackbar(BuildContext context, UpdateInfo updateInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nova versão disponível: ${updateInfo.version}'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'ATUALIZAR',
          onPressed: () => _downloadUpdate(context, updateInfo),
        ),
      ),
    );
  }

  static Future<void> _downloadUpdate(BuildContext context, UpdateInfo updateInfo) async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        await FlutterDownloader.enqueue(
          url: updateInfo.downloadUrl,
          savedDir: externalDir.path,
          fileName: 'app-release.apk',
          showNotification: true,
          openFileFromNotification: true,
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de armazenamento negada.')),
        );
      }
    }
  }
}
