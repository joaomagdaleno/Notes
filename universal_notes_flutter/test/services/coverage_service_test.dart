import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/models/coverage_report.dart';
import 'package:universal_notes_flutter/services/coverage_service.dart';

import 'coverage_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('CoverageService', () {
    test('returns a CoverageReport if the http call completes successfully', () async {
      final client = MockClient();
      final service = CoverageService(client: client);
      const jsonResponse = '''
      {
        "totalLines": 12,
        "totalHit": 10,
        "percentage": 83.33,
        "files": [
          {
            "title": "Test File",
            "file": "lib/test.dart",
            "functions": {"hit": 1, "found": 1, "details": []},
            "lines": {"hit": 10, "found": 12, "details": [{"line": 1, "hit": 1}]}
          }
        ]
      }
      ''';

      when(client.get(Uri.parse('https://raw.githubusercontent.com/joaomagdaleno/Notes/coverage-data/coverage.json')))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final report = await service.getCoverageReport();

      expect(report, isA<CoverageReport>());
      expect(report.totalLines, 12);
      expect(report.totalHit, 10);
      expect(report.percentage, 83.33);
      expect(report.files.length, 1);
      expect(report.files.first.file, 'lib/test.dart');
    });

    test('throws an exception if the http call completes with an error', () {
      final client = MockClient();
      final service = CoverageService(client: client);

      when(client.get(Uri.parse('https://raw.githubusercontent.com/joaomagdaleno/Notes/coverage-data/coverage.json')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(service.getCoverageReport(), throwsException);
    });
  });
}
