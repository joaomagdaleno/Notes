import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

import 'update_helper_test.mocks.dart';

@GenerateMocks([UpdateService])
void main() {
  group('UpdateHelper', () {
    late MockUpdateService mockUpdateService;

    setUp(() {
      mockUpdateService = MockUpdateService();
    });

    // Helper widget to test the UpdateHelper functionality
    Widget buildTestApp({required bool isManualCheck}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: isManualCheck,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for Update'),
            ),
          ),
        ),
      );
    }

    testWidgets(
        'shows update dialog when update is available (manual check)',
        (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: UpdateInfo(
            version: '1.0.1',
            downloadUrl: 'https://example.com/test.apk',
          ),
        ),
      );

      await tester.pumpWidget(buildTestApp(isManualCheck: true));

      await tester.tap(find.text('Check for Update'));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsOneWidget);
    });

    testWidgets(
        'shows "no update" snackbar on manual check',
        (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));

      await tester.pumpWidget(buildTestApp(isManualCheck: true));

      await tester.tap(find.text('Check for Update'));
      await tester.pumpAndSettle();

      expect(find.text('Você já tem a versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error snackbar on error (manual)',
        (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Failed to check',
        ),
      );

      await tester.pumpWidget(buildTestApp(isManualCheck: true));

      await tester.tap(find.text('Check for Update'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to check'), findsOneWidget);
    });

    testWidgets(
        'shows nothing when no update is available (automatic)',
        (WidgetTester tester) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));

      await tester.pumpWidget(buildTestApp(isManualCheck: false));

      await tester.tap(find.text('Check for Update'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
