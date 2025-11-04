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
    // 1. Request Storage Permission
    var storageStatus = await Permission.storage.request();

    // Handle denied or permanently denied storage permission
    if (!storageStatus.isGranted) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissão Necessária'),
            content: const Text('Para baixar a atualização, precisamos de permissão para acessar seu armazenamento. Por favor, conceda a permissão nas configurações do aplicativo.'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Abrir Configurações'),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
      return; // Stop if storage permission is not granted
    }

    // 2. Request Install Packages Permission
    var installStatus = await Permission.requestInstallPackages.request();
    if (!installStatus.isGranted) {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Permissão para instalar aplicativos desconhecidos negada.')),
         );
       }
       return; // Stop if install permission is not granted
    }

    // 3. Proceed with Download
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      await FlutterDownloader.enqueue(
        url: updateInfo.downloadUrl,
        savedDir: externalDir.path,
        fileName: 'app-release.apk',
        showNotification: true,
        openFileFromNotification: true,
      );
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Download da atualização iniciado...')),
         );
       }
    } else {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Não foi possível encontrar o diretório para download.')),
         );
       }
    }
  }
}
