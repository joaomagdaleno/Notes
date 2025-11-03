import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/update_service.dart';
import '../updater.dart';

class UpdateHelper {
  static Future<void> checkForUpdate(BuildContext context, {bool isManual = false}) async {
    // Show initial feedback
    if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando atualizações...')),
      );
    }

    final updateService = UpdateService();
    final result = await updateService.checkForUpdate();

    if (!context.mounted) return; // Always check mounted status after async gap

    // Hide the "checking" snackbar if it's there
    if (isManual) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        _showUpdateSnackbar(context, result.updateInfo!);
        break;
      case UpdateCheckStatus.noUpdate:
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você já tem a versão mais recente.')),
          );
        }
        break;
      case UpdateCheckStatus.error:
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'Ocorreu um erro desconhecido.')),
          );
        }
        break;
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
