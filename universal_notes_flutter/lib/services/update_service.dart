import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateService {
  static const String _repo = 'joaomagdaleno/Notes';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub API
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latestVersion = (json['tag_name'] as String).replaceAll('v', '');
        final assets = json['assets'] as List<dynamic>?;

        // Simple version comparison
        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (assets != null && assets.isNotEmpty) {
            final apkAsset = assets.firstWhere(
              (asset) => (asset['name'] as String).endsWith('.apk'),
              orElse: () => null,
            );

            if (apkAsset != null) {
              return UpdateInfo(
                version: latestVersion,
                downloadUrl: apkAsset['browser_download_url'] as String,
              );
            }
          }
        }
      }
    } catch (e) {
      // Handle exceptions, e.g., no internet connection
    }

    return null;
  }

  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = Version.parse(latestVersion);
      final current = Version.parse(currentVersion);
      return latest > current;
    } catch (e) {
      return false;
    }
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;

  UpdateInfo({required this.version, required this.downloadUrl});
}
