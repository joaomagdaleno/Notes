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
  final PackageInfo? packageInfo;

  static const String _repo = 'joaomagdaleno/Notes';

  /// Checks for updates.
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // 1. Get current app version info
      final info = packageInfo ?? await PackageInfo.fromPlatform();
      final currentVersionStr = info.version; // e.g., 1.0.0+123-dev

      // 2. Determine channel and build URL
      final channel = getChannel(currentVersionStr);
      final url = _getUpdateUrl(channel);

      // 3. Fetch latest release from GitHub API
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // 4. Extract latest version info from release
        String latestVersionStr;
        if (channel == 'stable') {
          final tagName = json['tag_name'] as String;
          latestVersionStr =
              tagName.startsWith('v') ? tagName.substring(1) : tagName;
        } else {
          // For dev/beta, parse from the release body, which will be added in CI
          final body = json['body'] as String? ?? '';
          latestVersionStr = _parseVersionFromBody(body);
          if (latestVersionStr.isEmpty) {
            return UpdateCheckResult(UpdateCheckStatus.noUpdate);
          }
        }

        // 5. Compare versions
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
                  downloadUrl: releaseAsset['browser_download_url'] as String,
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

  @visibleForTesting
  String getChannel(String version) {
    if (version.endsWith('-dev')) {
      return 'dev';
    } else if (version.endsWith('-beta')) {
      return 'beta';
    } else {
      return 'stable';
    }
  }

  Uri _getUpdateUrl(String channel) {
    if (channel == 'dev') {
      return Uri.parse(
          'https://api.github.com/repos/$_repo/releases/tags/dev-latest');
    } else if (channel == 'beta') {
      return Uri.parse(
          'https://api.github.com/repos/$_repo/releases/tags/beta-latest');
    } else {
      return Uri.parse('https://api.github.com/repos/$_repo/releases/latest');
    }
  }

  String _parseVersionFromBody(String body) {
    final match = RegExp(r'Version: ([\w\.\+\-]+)').firstMatch(body);
    return match?.group(1) ?? '';
  }

  @visibleForTesting
  bool isNewerVersion(String latestVersionStr, String currentVersionStr) {
    try {
      final currentChannel = getChannel(currentVersionStr);
      final latestChannel = getChannel(latestVersionStr);

      if (currentChannel != latestChannel) return false;

      if (currentChannel == 'stable') {
        final latest = Version.parse(latestVersionStr.split('+').first);
        final current = Version.parse(currentVersionStr.split('+').first);
        return latest > current;
      } else {
        final latestBuild =
            int.parse(latestVersionStr.split('+').last.split('-').first);
        final currentBuild =
            int.parse(currentVersionStr.split('+').last.split('-').first);
        return latestBuild > currentBuild;
      }
    } on Exception {
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
