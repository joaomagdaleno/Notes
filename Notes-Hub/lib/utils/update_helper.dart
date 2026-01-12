// lib/utils/update_helper.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:notes_hub/services/update_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

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
    Future<OpenResult> Function(String)? openFile,
    void Function()? onNoUpdate,
    void Function(String)? onError,
  }) async {
    final messenger = scaffoldMessengerKey?.currentState ??
        ScaffoldMessenger.maybeOf(context);

    if (isManual && onError == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Verificando atualizações...')),
      );
    }

    final service = updateService ?? UpdateService();
    final result = await service.checkForUpdate();

    if (!context.mounted) return;

    if (isManual && onError == null) {
      messenger?.hideCurrentSnackBar();
    }

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await _showUpdateDialog(
          context,
          result.updateInfo!,
          isAndroidOverride: isAndroidOverride,
          httpClient: httpClient,
          scaffoldMessengerKey: scaffoldMessengerKey,
          openFile: openFile,
        );
      case UpdateCheckStatus.noUpdate:
        if (onNoUpdate != null) {
          onNoUpdate();
        } else if (isManual) {
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('Você já está na versão mais recente.'),
            ),
          );
        }
      case UpdateCheckStatus.error:
        final message = result.errorMessage ?? 'Ocorreu um erro desconhecido.';
        if (onError != null) {
          onError(message);
        } else if (isManual) {
          messenger?.showSnackBar(
            SnackBar(
              content: Text(message),
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
    Future<OpenResult> Function(String)? openFile,
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
                openFile: openFile,
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
    Future<OpenResult> Function(String)? openFile,
  }) async {
    final isAndroid =
        isAndroidOverride ?? (defaultTargetPlatform == TargetPlatform.android);

    if (isAndroid) {
      final status = await Permission.requestInstallPackages.request();

      if (!context.mounted) return;

      if (status.isGranted) {
        await _downloadAndInstallUpdate(
          updateInfo,
          client: httpClient,
          scaffoldMessengerKey: scaffoldMessengerKey!,
          openFile: openFile,
        );
      } else {
        (scaffoldMessengerKey?.currentState ?? ScaffoldMessenger.of(context))
            .showSnackBar(
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
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
    http.Client? client,
    Future<OpenResult> Function(String)? openFile,
  }) async {
    final httpClient = client ?? http.Client();
    final messenger = scaffoldMessengerKey.currentState!
      ..showSnackBar(
        const SnackBar(
          content: Text('Baixando atualização... Por favor, aguarde.'),
        ),
      );

    try {
      final directory = await getTemporaryDirectory();
      // 🛡️ Sentinel: Use a random filename to prevent a race condition where
      // a malicious app could replace the update file before installation.
      final randomFileName = '${const Uuid().v4()}.apk';
      final filePath = '${directory.path}/$randomFileName';

      // 🛡️ Sentinel: Add a timeout to prevent the request from hanging
      // indefinitely, which could lead to a denial-of-service (DoS) attack.
      final response = await httpClient
          .get(Uri.parse(updateInfo.downloadUrl))
          .timeout(const Duration(seconds: 600));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        messenger.hideCurrentSnackBar();

        final result =
            await (openFile?.call(filePath) ?? OpenFile.open(filePath));
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
