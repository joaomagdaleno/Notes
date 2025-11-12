import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

/// The status of the update check.
enum UpdateCheckStatus {
  /// An update is available.
  updateAvailable,
  /// No update is available.
  noUpdate,
  /// An error occurred during the update check.
  error
}

/// The result of an update check.
class UpdateCheckResult {
  /// The status of the update check.
  final UpdateCheckStatus status;
  /// Information about the update, if available.
  final UpdateInfo? updateInfo;
  /// The error message, if an error occurred.
  final String? errorMessage;

  /// Creates a new instance of [UpdateCheckResult].
  UpdateCheckResult(this.status, {this.updateInfo, this.errorMessage});
}

/// A service for checking for updates.
class UpdateService {
  static const String _repo = 'joaomagdaleno/Notes';

  /// Checks for updates.
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.split('+').first;

      // Fetch latest release from GitHub API
      final url = Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = json['tag_name'] as String;
        // Remove 'v' prefix if present (e.g., 'v1.0.0' -> '1.0.0')
        final latestVersion =
            tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final assets = json['assets'] as List<dynamic>?;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          if (assets != null && assets.isNotEmpty) {
            final String fileExtension;
            if (Platform.isWindows) {
              fileExtension = '.exe';
            } else if (Platform.isAndroid) {
              fileExtension = '.apk';
            } else {
              // Platform not supported for updates, so no update is available.
              return UpdateCheckResult(UpdateCheckStatus.noUpdate);
            }

            final releaseAsset = assets.firstWhere(
              (dynamic asset) =>
                  (asset['name'] as String).endsWith(fileExtension),
              orElse: () => null,
            ) as Map<String, dynamic>?;

            if (releaseAsset != null) {
              return UpdateCheckResult(
                UpdateCheckStatus.updateAvailable,
                updateInfo: UpdateInfo(
                  version: latestVersion,
                  downloadUrl: releaseAsset['browser_download_url'] as String,
                ),
              );
            }
          }
        }
        // If we reach here, no update is available or the asset wasn't found
        return UpdateCheckResult(UpdateCheckStatus.noUpdate);
      } else {
        // Handle non-200 responses as errors
        return UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Falha ao comunicar com o servidor de atualização.',
        );
      }
    } catch (e) {
      // Handle exceptions, e.g., no internet connection
      return UpdateCheckResult(
        UpdateCheckStatus.error,
        errorMessage:
            'Não foi possível verificar as atualizações. Verifique sua conexão com a internet.',
      );
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

/// Information about an update.
class UpdateInfo {
  /// The version of the update.
  final String version;
  /// The URL to download the update from.
  final String downloadUrl;

  /// Creates a new instance of [UpdateInfo].
  UpdateInfo({required this.version, required this.downloadUrl});
}
