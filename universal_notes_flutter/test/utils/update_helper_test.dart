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

    testWidgets('shows update dialog when update is available', (
      WidgetTester tester,
    ) async {
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: UpdateInfo(
            version: '1.0.1',
            downloadUrl: 'https://example.com/test.apk',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => UpdateHelper.checkForUpdate(
                  context,
                  updateService: mockUpdateService,
                ),
                child: const Text('Check for Update'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check for Update'));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsOneWidget);
    });
  });
}
