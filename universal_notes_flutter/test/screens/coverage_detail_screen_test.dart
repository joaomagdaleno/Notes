import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/models/coverage_report.dart';
import 'package:universal_notes_flutter/screens/coverage_detail_screen.dart';

import '../services/coverage_service_test.mocks.dart';

void main() {
  group('CoverageDetailScreen', () {
    final mockFileCoverage = FileCoverage(
      file: 'lib/test.dart',
      functions: CoverageDetails(hit: 1, found: 1, details: []),
      lines: CoverageDetails(hit: 1, found: 2, details: [
        LineDetail(line: 1, hit: 1),
        LineDetail(line: 2, hit: 0),
      ]),
    );

    testWidgets('shows loading indicator and then displays syntax view', (WidgetTester tester) async {
      final client = MockClient();
      const sourceCode = 'void main() {\n  print("hello");\n}';
      final url = 'https://raw.githubusercontent.com/joaomagdaleno/Notes/main/lib/test.dart';

      when(client.get(Uri.parse(url))).thenAnswer((_) async => http.Response(sourceCode, 200));

      await tester.pumpWidget(MaterialApp(
        home: CoverageDetailScreen(
          fileCoverage: mockFileCoverage,
          client: client,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('void main() {'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (WidgetTester tester) async {
      final client = MockClient();
      final url = 'https://raw.githubusercontent.com/joaomagdaleno/Notes/main/lib/test.dart';

      when(client.get(Uri.parse(url))).thenAnswer((_) async => http.Response('Not Found', 404));

      await tester.pumpWidget(MaterialApp(
        home: CoverageDetailScreen(
          fileCoverage: mockFileCoverage,
          client: client,
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}
