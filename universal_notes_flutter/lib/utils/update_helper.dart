import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import '../services/update_service.dart';
import '../updater.dart';

class UpdateHelper {
  static const _channel = MethodChannel('com.example.universal_notes_flutter/installer');

  static Future<void> checkForUpdate(BuildContext context, {bool isManual = false}) async {
    if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando atualizações...')),
      );
    }

    final updateService = UpdateService();
    final result = await updateService.checkForUpdate();

    if (!context.mounted) return;

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
          onPressed: () => _handleUpdate(context, updateInfo),
        ),
      ),
    );
  }

  static Future<void> _handleUpdate(BuildContext context, UpdateInfo updateInfo) async {
    if (Platform.isAndroid) {
      final canInstall = await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
      if (canInstall) {
        _downloadUpdate(context, updateInfo);
      } else {
        _requestInstallPermission(context);
      }
    }
  }

  static void _requestInstallPermission(BuildContext context) async {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissão Necessária'),
          content: const Text('Para instalar a atualização, precisamos que você habilite a permissão para "instalar apps desconhecidos". Você será redirecionado para as configurações.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Abrir Configurações'),
              onPressed: () {
                const intent = AndroidIntent(
                  action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
                  data: 'package:com.example.universal_notes_flutter',
                );
                intent.launch();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  static Future<void> _downloadUpdate(BuildContext context, UpdateInfo updateInfo) async {
    final cacheDirs = await getExternalCacheDirectories();
    if (cacheDirs == null || cacheDirs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível encontrar o diretório de cache.')),
        );
      }
      return;
    }
    final saveDir = cacheDirs.first.path;

    await FlutterDownloader.enqueue(
      url: updateInfo.downloadUrl,
      savedDir: saveDir,
      fileName: 'app-release.apk',
      showNotification: true,
      openFileFromNotification: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download da atualização iniciado...')),
      );
    }
  }
}
