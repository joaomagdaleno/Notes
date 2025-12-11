import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  /// Creates a new instance of [UpdateCheckResult].
  UpdateCheckResult(this.status, {this.updateInfo, this.errorMessage});

  /// The status of the update check.
  final UpdateCheckStatus status;
  /// Information about the update, if available.
  final UpdateInfo? updateInfo;
  /// The error message, if an error occurred.
  final String? errorMessage;
}

/// A service for checking for updates.
class UpdateService {
  /// Creates a new instance of [UpdateService].
  UpdateService({http.Client? client, this.packageInfo})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Information about the package.
  final PackageInfo? packageInfo;

  static const String _repo = 'joaomagdaleno/Notes';

  /// Checks for available updates and returns an UpdateResult
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final info = packageInfo ?? await PackageInfo.fromPlatform();
      final currentVersionStr = info.version;

      final url = _getUpdateUrl(currentVersionStr);

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        String latestVersionStr;
        if (url.path.endsWith('/latest')) {
          final tagName = json['tag_name'] as String;
          latestVersionStr =
              tagName.startsWith('v') ? tagName.substring(1) : tagName;
        } else {
          final body = json['body'] as String? ?? '';
          latestVersionStr = _parseVersionFromBody(body);
          if (latestVersionStr.isEmpty) {
            return UpdateCheckResult(UpdateCheckStatus.noUpdate);
          }
        }

        if (isNewerVersion(latestVersionStr, currentVersionStr)) {
          final assets = json['assets'] as List<dynamic>?;
          if (assets != null && assets.isNotEmpty) {
            final fileExtension = getPlatformFileExtension();
            if (fileExtension == null) {
              return UpdateCheckResult(UpdateCheckStatus.noUpdate);
            }

            final releaseAsset = assets.firstWhere(
              (dynamic asset) =>
                  ((asset as Map<String, dynamic>)['name'] as String)
                      .endsWith(fileExtension),
              orElse: () => null,
            ) as Map<String, dynamic>?;

            if (releaseAsset != null) {
              return UpdateCheckResult(
                UpdateCheckStatus.updateAvailable,
                updateInfo: UpdateInfo(
                  version: latestVersionStr,
                  downloadUrl:
                      releaseAsset['browser_download_url'] as String,
                ),
              );
            }
          }
        }
        return UpdateCheckResult(UpdateCheckStatus.noUpdate);
      } else {
        return UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Falha ao comunicar com o servidor de atualização.',
        );
      }
    } on Exception {
      return UpdateCheckResult(
        UpdateCheckStatus.error,
        errorMessage: 'Não foi possível verificar as atualizações. '
            'Verifique sua conexão com a internet.',
      );
    }
  }

  Uri _getUpdateUrl(String version) {
    // 🛡️ Sentinel: Using Uri.https to enforce HTTPS and prevent insecure connections.
    if (version.contains('-dev')) {
      return Uri.https('api.github.com', '/repos/$_repo/releases/tags/dev-latest');
    } else if (version.contains('-beta')) {
      return Uri.https('api.github.com', '/repos/$_repo/releases/tags/beta-latest');
    } else {
      return Uri.https('api.github.com', '/repos/$_repo/releases/latest');
    }
  }

  String _parseVersionFromBody(String body) {
    final match = RegExp(r'Version: ([\w\.\-\+]+)').firstMatch(body);
    return match?.group(1) ?? '';
  }

  /// Compares two version strings to see if the latest version is newer.
  @visibleForTesting
  bool isNewerVersion(String latestVersionStr, String currentVersionStr) {
    try {
      final latest = Version.parse(latestVersionStr);
      final current = Version.parse(currentVersionStr);
      return latest > current;
    } on FormatException {
      // If the version string is invalid, treat as not newer.
      return false;
    }
  }

  /// Returns the file extension for the current platform.
  String? getPlatformFileExtension() {
    if (Platform.isWindows) {
      return '.exe';
    } else if (Platform.isAndroid) {
      return '.apk';
    } else {
      return null;
    }
  }
}

/// Information about an update.
class UpdateInfo {
  /// Creates a new instance of [UpdateInfo].
  UpdateInfo({required this.version, required this.downloadUrl});

  /// The version of the update.
  final String version;
  /// The URL to download the update from.
  final String downloadUrl;
}
