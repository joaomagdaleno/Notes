import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

void main() {
  group('UpdateService', () {
    late UpdateService updateService;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'universal_notes',
        packageName: 'com.example.universal_notes',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: '',
      );
    });

    test(
        'checkForUpdate returns updateAvailable when a new version is '
        'available', () {
      HttpOverrides.runZoned(() async {
        final mockClient = MockClient((request) async {
          final response = {
            'tag_name': 'v1.0.1',
            'assets': [
              {
                'name': 'test.apk',
                'browser_download_url': 'https://example.com/test.apk',
              }
            ]
          };
          return http.Response(jsonEncode(response), 200);
        });
        updateService = UpdateService(client: mockClient);
        final result = await updateService.checkForUpdate();
        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.updateInfo?.version, '1.0.1');
      }, createHttpClient: (context) {
        return MockClient((request) async {
          return http.Response('', 200);
        });
      });
    });

    test('checkForUpdate returns noUpdate when current version is the latest',
        () {
      HttpOverrides.runZoned(() async {
        PackageInfo.setMockInitialValues(
          appName: 'universal_notes',
          packageName: 'com.example.universal_notes',
          version: '1.0.1',
          buildNumber: '1',
          buildSignature: '',
          installerStore: '',
        );
        final mockClient = MockClient((request) async {
          final response = {
            'tag_name': 'v1.0.1',
            'assets': [
              {
                'name': 'test.apk',
                'browser_download_url': 'https://example.com/test.apk',
              }
            ]
          };
          return http.Response(jsonEncode(response), 200);
        });
        updateService = UpdateService(client: mockClient);
        final result = await updateService.checkForUpdate();
        expect(result.status, UpdateCheckStatus.noUpdate);
      }, createHttpClient: (context) {
        return MockClient((request) async {
          return http.Response('', 200);
        });
      });
    });

    test('checkForUpdate returns error on server error', () {
      HttpOverrides.runZoned(() async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });
        updateService = UpdateService(client: mockClient);
        final result = await updateService.checkForUpdate();
        expect(result.status, UpdateCheckStatus.error);
      }, createHttpClient: (context) {
        return MockClient((request) async {
          return http.Response('', 200);
        });
      });
    });
  });
}
