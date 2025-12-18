import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

import 'chaos_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService Resilience (Chaos)', () {
    late ChaosHttpClient chaosClient;
    late UpdateService updateService;

    setUp(() {
      final mockInner = MockClient((request) async {
        return http.Response('{"tag_name": "v2.0.0"}', 200);
      });
      chaosClient = ChaosHttpClient(mockInner);
      updateService = UpdateService(
        client: chaosClient,
        packageInfo: PackageInfo(
          appName: 'Notes',
          packageName: 'com.example.notes',
          version: '1.0.0',
          buildNumber: '1',
        ),
      );
    });

    test('handles timeout gracefully', () async {
      chaosClient.forceTimeout = true;

      final result = await updateService.checkForUpdate();

      expect(result.status, UpdateCheckStatus.error);
      expect(result.errorMessage, contains('Não foi possível verificar'));
    });

    test('handles server 500 errors gracefully', () async {
      chaosClient
        ..injectFailures = true
        ..failureRate = 1.0; // Force failure

      final result = await updateService.checkForUpdate();

      expect(result.status, UpdateCheckStatus.error);
      expect(result.errorMessage, contains('Falha ao comunicar'));
    });
  });
}
