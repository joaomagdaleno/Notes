import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

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
            }
          ],
        }),
        200,
      );
    }

    group('Stable Channel', () {
      test(
          'returns updateAvailable when a newer stable version is '
          'available', () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+1', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/latest'));
          return mockReleaseResponse(tagName: 'v1.0.1');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.updateInfo?.version, '1.0.1');
      });

      test('returns noUpdate when the current stable version is the latest',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.1+2', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/latest'));
          return mockReleaseResponse(tagName: 'v1.0.1');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      });
    });

    group('Dev Channel', () {
      test('returns updateAvailable when a newer dev build is available',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+123-dev', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/tags/dev-latest'));
          return mockReleaseResponse(
              tagName: 'dev-latest', body: 'Version: 1.0.0+124-dev');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.updateInfo?.version, '1.0.0+124-dev');
      });

      test('returns noUpdate when the current dev build is the latest',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+124-dev', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/tags/dev-latest'));
          return mockReleaseResponse(
              tagName: 'dev-latest', body: 'Version: 1.0.0+124-dev');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      });

       test('returns noUpdate when a stable release is newer by semver but on a different channel',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+123-dev', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          // This should never be called, as the dev channel has its own URL
           return mockReleaseResponse(tagName: 'v1.1.0');
        });
         final service = UpdateService(client: mockClient, packageInfo: packageInfo);
         // Manually check the logic, as the mock will direct to the correct URL
         final isNewer = service.testIsNewerVersion('1.1.0', '1.0.0+123-dev');
        expect(isNewer, isFalse);
      });
    });
     group('Beta Channel', () {
      test('returns updateAvailable when a newer beta build is available',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+123-beta', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/tags/beta-latest'));
          return mockReleaseResponse(
              tagName: 'beta-latest', body: 'Version: 1.0.0+124-beta');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.updateInfo?.version, '1.0.0+124-beta');
      });
       test('returns noUpdate when the current beta build is the latest',
          () async {
        final packageInfo = PackageInfo(
            version: '1.0.0+124-beta', appName: '', buildNumber: '', packageName: '');
        mockClient = MockClient((request) async {
          expect(request.url.path, contains('/releases/tags/beta-latest'));
          return mockReleaseResponse(
              tagName: 'beta-latest', body: 'Version: 1.0.0+124-beta');
        });
        final service = UpdateService(client: mockClient, packageInfo: packageInfo);
        final result = await service.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      });
    });

    test('returns error on server error', () async {
       final packageInfo = PackageInfo(
          version: '1.0.0+1', appName: '', buildNumber: '', packageName: '');
      mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
       final service = UpdateService(client: mockClient, packageInfo: packageInfo);
      final result = await service.checkForUpdate();
      expect(result.status, UpdateCheckStatus.error);
    });
  });
}
// Helper extension to access the private method for testing
extension TestUpdateService on UpdateService {
  bool testIsNewerVersion(String latest, String current) {
    // ignore: invalid_use_of_visible_for_testing_member
    return isNewerVersion(latest, current);
  }
}
