// lib/utils/update_helper.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

/// A helper class for handling application updates.
class UpdateHelper {
  /// Checks for updates and prompts the user to install them.
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool isManual = false,
    UpdateService? updateService,
    bool? isAndroidOverride,
    http.Client? httpClient,
  }) async {
    if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando atualizações...')),
      );
    }

    final service = updateService ?? UpdateService();
    final result = await service.checkForUpdate();

    if (!context.mounted) return;

    if (isManual) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await _showUpdateDialog(
          context,
          result.updateInfo!,
          isAndroidOverride: isAndroidOverride,
          httpClient: httpClient,
        );
      case UpdateCheckStatus.noUpdate:
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você já tem a versão mais recente.'),
            ),
          );
        }
      case UpdateCheckStatus.error:
        if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? 'Ocorreu um erro desconhecido.',
              ),
            ),
          );
        }
    }
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo, {
    bool? isAndroidOverride,
    http.Client? httpClient,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (context) => AlertDialog(
        title: const Text('Atualização Disponível'),
        content: Text(
          'Uma nova versão (${updateInfo.version}) está disponível. '
          'Deseja baixar e instalar?',
        ),
        actions: [
          TextButton(
            child: const Text('Agora não'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Sim, atualizar'),
            // CHANGED: Made callback async and await the update process
            onPressed: () async {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              // AWAIT the update process instead of firing and forgetting.
              await _handleUpdate(
                context,
                updateInfo,
                isAndroidOverride: isAndroidOverride,
                httpClient: httpClient,
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _handleUpdate(
    BuildContext context,
    UpdateInfo updateInfo, {
    bool? isAndroidOverride,
    http.Client? httpClient,
  }) async {
    final isAndroid = isAndroidOverride ?? Platform.isAndroid;

    if (isAndroid) {
      final status = await Permission.requestInstallPackages.request();

      if (!context.mounted) return;

      if (status.isGranted) {
        await _downloadAndInstallUpdate(
          context,
          updateInfo,
          client: httpClient,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissão para instalar pacotes é necessária para a '
              'atualização.',
            ),
          ),
        );
      }
    }
  }

  static Future<void> _downloadAndInstallUpdate(
    BuildContext context,
    UpdateInfo updateInfo, {
    http.Client? client,
  }) async {
    final http.Client httpClient = client ?? http.Client();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Baixando atualização... Por favor, aguarde.'),
      ),
    );

    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/app-release.apk';

      final response = await httpClient.get(Uri.parse(updateInfo.downloadUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception(
            'Não foi possível abrir o arquivo de instalação: ${result.message}',
          );
        }
      } else {
        throw Exception('Falha no download. Status: ${response.statusCode}');
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na atualização: $e')),
        );
      }
    }
  }
}
