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
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) async {
    final messenger =
        scaffoldMessengerKey?.currentState ?? ScaffoldMessenger.of(context);

    if (isManual) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Verificando atualizações...')),
      );
    }

    final service = updateService ?? UpdateService();
    final result = await service.checkForUpdate();

    if (!context.mounted) return;

    if (isManual) {
      messenger.hideCurrentSnackBar();
    }

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await _showUpdateDialog(
          context,
          result.updateInfo!,
          isAndroidOverride: isAndroidOverride,
          httpClient: httpClient,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      case UpdateCheckStatus.noUpdate:
        if (isManual) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Você já tem a versão mais recente.'),
            ),
          );
        }
      case UpdateCheckStatus.error:
        if (isManual) {
          messenger.showSnackBar(
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
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
            onPressed: () async {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              await _handleUpdate(
                context,
                updateInfo,
                isAndroidOverride: isAndroidOverride,
                httpClient: httpClient,
                scaffoldMessengerKey: scaffoldMessengerKey,
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
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) async {
    final isAndroid = isAndroidOverride ?? Platform.isAndroid;

    if (isAndroid) {
      final status = await Permission.requestInstallPackages.request();

      if (!context.mounted) return;

      if (status.isGranted) {
        await _downloadAndInstallUpdate(
          updateInfo,
          client: httpClient,
          scaffoldMessengerKey: scaffoldMessengerKey!,
        );
      } else {
        final messenger =
            scaffoldMessengerKey?.currentState ?? ScaffoldMessenger.of(context);
        messenger.showSnackBar(
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
    UpdateInfo updateInfo, {
    http.Client? client,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) async {
    final httpClient = client ?? http.Client();
    final messenger = scaffoldMessengerKey.currentState!;

    messenger.showSnackBar(
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

        messenger.hideCurrentSnackBar();

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
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Erro na atualização: $e')));
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
