import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class Updater {
  Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/diegolima362/universal_notes_flutter/releases/latest'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latestVersionStr = (json['tag_name'] as String).substring(1);
        final latestVersion = Version.parse(latestVersionStr);

        if (latestVersion > currentVersion) {
          final assets = json['assets'] as List;
          final asset = assets.firstWhere(
            (asset) =>
                (asset['name'] as String).startsWith('UniversalNotesSetup-'),
            orElse: () => null,
          );

          if (asset != null) {
            final downloadUrl = asset['browser_download_url'] as String;
            final tempDir = await getTemporaryDirectory();
            final filePath = '${tempDir.path}/${asset['name']}';
            final response = await http.get(Uri.parse(downloadUrl));

            if (response.statusCode == 200) {
              final file = File(filePath);
              await file.writeAsBytes(response.bodyBytes);
              await Process.run(filePath, ['/SILENT', '/NORESTART']);
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors for now, as this is a background process.
    }
  }
}
