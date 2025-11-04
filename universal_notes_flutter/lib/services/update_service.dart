import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

enum UpdateCheckStatus { updateAvailable, noUpdate, error }

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final UpdateInfo? updateInfo;
  final String? errorMessage;

  UpdateCheckResult(this.status, {this.updateInfo, this.errorMessage});
}

class UpdateService {
  static const String _repo = 'joaomagdaleno/Notes';

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.split('+').first;

      // Fetch latest release from GitHub API
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final tagName = json['tag_name'] as String;
        // Remove 'v' prefix if present (e.g., 'v1.0.0' -> '1.0.0')
        final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final assets = json['assets'] as List<dynamic>?;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (assets != null && assets.isNotEmpty) {
            final apkAsset = assets.firstWhere(
              (asset) => (asset['name'] as String).endsWith('.apk'),
              orElse: () => null,
            );

            if (apkAsset != null) {
              return UpdateCheckResult(
                UpdateCheckStatus.updateAvailable,
                updateInfo: UpdateInfo(
                  version: latestVersion,
                  downloadUrl: apkAsset['browser_download_url'] as String,
                ),
              );
            } catch (e) {
              // No APK asset found, return null
            }
          }
        }
        // If we reach here, no update is available or the asset wasn't found
        return UpdateCheckResult(UpdateCheckStatus.noUpdate);
      } else {
        // Handle non-200 responses as errors
        return UpdateCheckResult(UpdateCheckStatus.error, errorMessage: 'Falha ao comunicar com o servidor de atualização.');
      }
    } catch (e) {
      // Handle exceptions, e.g., no internet connection
      return UpdateCheckResult(UpdateCheckStatus.error, errorMessage: 'Não foi possível verificar as atualizações. Verifique sua conexão com a internet.');
    }
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
