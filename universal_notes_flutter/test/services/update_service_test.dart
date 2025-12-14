import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

class TestUpdateService extends UpdateService {
  TestUpdateService({super.client, super.packageInfo});

  @override
  String? getPlatformFileExtension() {
    return '.apk';
  }
}

class UnsupportedPlatformUpdateService extends UpdateService {
  UnsupportedPlatformUpdateService({super.client, super.packageInfo});

  @override
  String? getPlatformFileExtension() {
    return null;
  }
}

void main() {
  group('UpdateService', () {
    late http.Client mockClient;

    // Helper to create a mock response for a specific channel
    http.Response mockReleaseResponse({
      String tagName = 'v1.0.0',
      String body = '',
      String assetName = 'test.apk',
    }) {
      return http.Response(
        jsonEncode({
          'tag_name': tagName,
          'body': body,
          'assets': [
            {
              'name': assetName,
              'browser_download_url': 'https://example.com/$assetName',
            },
          ],
        }),
        200,
      );
    }

    group('Stable Channel', () {
      test('returns updateAvailable when a newer stable version is '
          'available', () async {
        final packageInfo = PackageInfo(
          version: '1.0.0',
          appName: '',
          buildNumber: '',
          packageName: '',
        );
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/latest'));
          return mockReleaseResponse(tagName: 'v1.0.1');
        });
        final service = TestUpdateService(
          client: mockClient,
          packageInfo: packageInfo,
        );
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.updateInfo?.version, '1.0.1');
      });

      test(
        'returns noUpdate when a newer version has no matching asset',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.0',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            return mockReleaseResponse(
              tagName: 'v1.0.1',
              assetName: 'test.zip',
            );
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.noUpdate);
        },
      );

      test(
        'returns noUpdate when the current stable version is the latest',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.1',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            expect(request.url.path, contains('/releases/latest'));
            return mockReleaseResponse(tagName: 'v1.0.1');
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.noUpdate);
        },
      );

      test('returns noUpdate for unsupported platform', () async {
        final packageInfo = PackageInfo(
          version: '1.0.0',
          appName: '',
          buildNumber: '',
          packageName: '',
        );
        mockClient = MockClient((request) async {
          return mockReleaseResponse(tagName: 'v1.0.1');
        });
        final service = UnsupportedPlatformUpdateService(
          client: mockClient,
          packageInfo: packageInfo,
        );
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      });
    });

    group('Dev Channel', () {
      test(
        'returns updateAvailable when a newer dev build is available',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.0-dev.123',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            expect(request.url.path, contains('/releases/tags/dev-latest'));
            return mockReleaseResponse(body: 'Version: 1.0.0-dev.124');
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.updateAvailable);
          expect(result.updateInfo?.version, '1.0.0-dev.124');
        },
      );

      test(
        'returns noUpdate when the current dev build is the latest',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.0-dev.124',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            expect(request.url.path, contains('/releases/tags/dev-latest'));
            return mockReleaseResponse(
              tagName: 'dev-latest',
              body: 'Version: 1.0.0-dev.124',
            );
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.noUpdate);
        },
      );

      test('returns noUpdate when the release body has no version', () async {
        final packageInfo = PackageInfo(
          version: '1.0.0-dev.123',
          appName: '',
          buildNumber: '',
          packageName: '',
        );
        mockClient = MockClient((request) async {
          return mockReleaseResponse();
        });
        final service = TestUpdateService(
          client: mockClient,
          packageInfo: packageInfo,
        );
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      });
    });
    group('Beta Channel', () {
      test(
        'returns updateAvailable when a newer beta build is available',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.0-beta.123',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            expect(request.url.path, contains('/releases/tags/beta-latest'));
            return mockReleaseResponse(
              tagName: 'beta-latest',
              body: 'Version: 1.0.0-beta.124',
            );
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.updateAvailable);
          expect(result.updateInfo?.version, '1.0.0-beta.124');
        },
      );
      test(
        'returns noUpdate when the current beta build is the latest',
        () async {
          final packageInfo = PackageInfo(
            version: '1.0.0-beta.124',
            appName: '',
            buildNumber: '',
            packageName: '',
          );
          mockClient = MockClient((request) async {
            expect(request.url.path, contains('/releases/tags/beta-latest'));
            return mockReleaseResponse(
              tagName: 'beta-latest',
              body: 'Version: 1.0.0-beta.124',
            );
          });
          final service = TestUpdateService(
            client: mockClient,
            packageInfo: packageInfo,
          );
          final result = await service.checkForUpdate();
          expect(result.status, UpdateCheckStatus.noUpdate);
        },
      );
    });

    test('returns error on server error', () async {
      final packageInfo = PackageInfo(
        version: '1.0.0',
        appName: '',
        buildNumber: '',
        packageName: '',
      );
      mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
      final service = TestUpdateService(
        client: mockClient,
        packageInfo: packageInfo,
      );
      final result = await service.checkForUpdate();
      expect(result.status, UpdateCheckStatus.error);
      expect(result.errorMessage, isNotNull);
    });

    test('returns error on network error', () async {
      final packageInfo = PackageInfo(
        version: '1.0.0',
        appName: '',
        buildNumber: '',
        packageName: '',
      );
      mockClient = MockClient((request) async {
        throw http.ClientException('Network error');
      });
      final service = TestUpdateService(
        client: mockClient,
        packageInfo: packageInfo,
      );
      final result = await service.checkForUpdate();
      expect(result.status, UpdateCheckStatus.error);
      expect(result.errorMessage, isNotNull);
    });

    test('isNewerVersion returns false for invalid version strings', () {
      final packageInfo = PackageInfo(
        version: '1.0.0',
        appName: '',
        buildNumber: '',
        packageName: '',
      );
      final service = TestUpdateService(packageInfo: packageInfo);

      // Invalid format should return false, not throw
      expect(service.isNewerVersion('invalid', '1.0.0'), isFalse);
      expect(service.isNewerVersion('1.0.0', 'invalid'), isFalse);
      expect(
        service.isNewerVersion('not-a-version', 'also-not-a-version'),
        isFalse,
      );
    });
  });
}
