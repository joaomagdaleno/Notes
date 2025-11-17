import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

import 'update_service_test.mocks.dart';

@GenerateMocks([PackageInfo])
void main() {
  group('UpdateService', () {
    late UpdateService updateService;
    late MockClient mockClient;
    late MockPackageInfo mockPackageInfo;

    setUp(() {
      updateService = UpdateService();
      mockClient = MockClient((request) async {
        if (request.url.toString() ==
            'https://api.github.com/repos/joaomagdaleno/Notes/releases/latest') {
          return http.Response(
              '{"tag_name": "v1.0.1", "assets": [{"name": "test.apk", "browser_download_url": "https://example.com/test.apk"}]}',
              200);
        }
        return http.Response('Not Found', 404);
      });
      mockPackageInfo = MockPackageInfo();
      PackageInfo.setMockInitialValues(
          appName: 'universal_notes',
          packageName: 'com.example.universal_notes',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
          installerStore: '');
    });

    test('checkForUpdate returns updateAvailable when a new version is available',
        () async {
      final result = await updateService.checkForUpdate();
      expect(result.status, UpdateCheckStatus.updateAvailable);
      expect(result.updateInfo?.version, '1.0.1');
    });

    test('checkForUpdate returns noUpdate when current version is the latest',
        () async {
      PackageInfo.setMockInitialValues(
          appName: 'universal_notes',
          packageName: 'com.example.universal_notes',
          version: '1.0.1',
          buildNumber: '1',
          buildSignature: '',
          installerStore: '');
      final result = await updateService.checkForUpdate();
      expect(result.status, UpdateCheckStatus.noUpdate);
    });

    test('checkForUpdate returns error on server error', () async {
      mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });
      final result = await updateService.checkForUpdate();
      expect(result.status, UpdateCheckStatus.error);
    });
  });
}
