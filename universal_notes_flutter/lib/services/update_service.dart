import 'dart:convert';

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
  error,
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

      // 🛡️ Sentinel: Add a timeout to prevent the request from hanging
      // indefinitely.
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // 🛡️ Sentinel: Safely decode JSON to prevent crashes from invalid
        // data.
        final dynamic decodedJson;
        try {
          decodedJson = jsonDecode(response.body);
        } on FormatException {
          return UpdateCheckResult(
            UpdateCheckStatus.error,
            errorMessage: 'Resposta de atualização inválida do servidor.',
          );
        }

        if (decodedJson is! Map<String, dynamic>) {
          return UpdateCheckResult(
            UpdateCheckStatus.error,
            errorMessage: 'Resposta de atualização inválida do servidor.',
          );
        }
        final json = decodedJson;

        String latestVersionStr;
        if (url.path.endsWith('/latest')) {
          // 🛡️ Sentinel: Safely access tag_name to prevent crashes.
          final tagName = json['tag_name'];
          if (tagName is! String) {
            return UpdateCheckResult(UpdateCheckStatus.noUpdate);
          }
          latestVersionStr =
              tagName.startsWith('v') ? tagName.substring(1) : tagName;
        } else {
          // 🛡️ Sentinel: Safely access body to prevent crashes.
          final body = json['body'];
          latestVersionStr = _parseVersionFromBody(body is String ? body : '');
          if (latestVersionStr.isEmpty) {
            return UpdateCheckResult(UpdateCheckStatus.noUpdate);
          }
        }

        if (isNewerVersion(latestVersionStr, currentVersionStr)) {
          // 🛡️ Sentinel: Safely access assets list to prevent crashes.
          final assets = json['assets'];
          if (assets is List && assets.isNotEmpty) {
            final fileExtension = getPlatformFileExtension();
            if (fileExtension == null) {
              return UpdateCheckResult(UpdateCheckStatus.noUpdate);
            }

            // 🛡️ Sentinel: Safely find and access release asset to prevent
            // crashes.
            final releaseAsset = assets.firstWhere(
              (dynamic asset) {
                if (asset is! Map<String, dynamic>) return false;
                final name = asset['name'];
                return name is String && name.endsWith(fileExtension);
              },
              orElse: () => null,
            );

            if (releaseAsset is Map<String, dynamic>) {
              final downloadUrl = releaseAsset['browser_download_url'];
              if (downloadUrl is String) {
                return UpdateCheckResult(
                  UpdateCheckStatus.updateAvailable,
                  updateInfo: UpdateInfo(
                    version: latestVersionStr,
                    downloadUrl: downloadUrl,
                  ),
                );
              }
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
    // 🛡️ Sentinel: Enforce HTTPS to prevent insecure connections.
    if (version.contains('-dev')) {
      return Uri.https(
        'api.github.com',
        '/repos/$_repo/releases/tags/dev-latest',
      );
    } else if (version.contains('-beta')) {
      return Uri.https(
        'api.github.com',
        '/repos/$_repo/releases/tags/beta-latest',
      );
    } else {
      return Uri.https(
        'api.github.com',
        '/repos/$_repo/releases/latest',
      );
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
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return '.exe';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
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
