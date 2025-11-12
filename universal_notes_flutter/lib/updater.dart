import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

/// A class that handles application updates.
class Updater {
  /// Checks for updates and prompts the user to install them.
  Future<void> checkForUpdates({
    required BuildContext context,
    required void Function(String) onStatusChange,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version.split('+').first);

      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/joaomagdaleno/Notes/releases/latest',
        ),
      );

      if (response.statusCode == 404) {
        throw Exception('Nenhum release encontrado. '
            'Verifique se um release público foi criado no repositório.');
      } else if (response.statusCode != 200) {
        throw Exception(
            'Falha ao verificar atualizações. Código de status: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String;
      // Remove 'v' prefix if present (e.g., 'v1.0.0' -> '1.0.0')
      final latestVersionStr =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final latestVersion = Version.parse(latestVersionStr);

      if (latestVersion <= currentVersion) {
        onStatusChange('Você já está na versão mais recente.');
        return;
      }

      final assets = json['assets'] as List;
      Map<String, dynamic> asset;
      try {
        asset = assets.firstWhere(
          (dynamic asset) =>
              (asset['name'] as String).startsWith('UniversalNotesSetup-'),
        ) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('No installer found for the latest version');
      }

      final downloadUrl = asset['browser_download_url'] as String;

      // ignore: use_build_context_synchronously
      if (!context.mounted) return;

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Atualização Disponível'),
          content: Text(
            'Uma nova versão ($latestVersionStr) está disponível. Deseja atualizar agora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );

      if (shouldUpdate != true) {
        onStatusChange('');
        return;
      }

      onStatusChange('Baixando atualização...');
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${asset['name'] as String}';
      final downloadResponse = await http.get(Uri.parse(downloadUrl));

      if (downloadResponse.statusCode != 200) {
        throw Exception('Failed to download update');
      }

      final file = File(filePath);
      await file.writeAsBytes(downloadResponse.bodyBytes);

      onStatusChange('Atualização baixada. Pronto para instalar.');

      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch installer');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      onStatusChange('Erro: $errorMessage');
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro de Atualização'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
