import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/models/coverage_report.dart';
import 'package:universal_notes_flutter/screens/coverage_report_screen.dart';
import 'package:universal_notes_flutter/services/coverage_service.dart';
import 'package:http/http.dart' as http;

import '../services/coverage_service_test.mocks.dart';

void main() {
  group('CoverageReportScreen', () {
    testWidgets('shows loading indicator and then data', (WidgetTester tester) async {
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

      when(client.get(any)).thenAnswer((_) async => http.Response(jsonResponse, 200));

      await tester.pumpWidget(MaterialApp(home: CoverageReportScreen(service: service)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Overall Coverage'), findsOneWidget);
      expect(find.byKey(const Key('overall_coverage_percentage')), findsOneWidget);
      expect(find.text('lib/test.dart'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (WidgetTester tester) async {
      final client = MockClient();
      final service = CoverageService(client: client);

      when(client.get(any)).thenAnswer((_) async => http.Response('Not Found', 404));

      await tester.pumpWidget(MaterialApp(home: CoverageReportScreen(service: service)));

      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
