import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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

    testWidgets('shows update dialog when update is available', (WidgetTester tester) async {
      // Create a mock update info
      final updateInfo = UpdateInfo(
        version: '1.0.1',
        downloadUrl: 'https://example.com/app.apk',
      );

      // Configure the mock to return an update available result
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(
                UpdateCheckStatus.updateAvailable,
                updateInfo: updateInfo,
              ));

      // Build the app with a Scaffold
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: false,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      // Tap the button to trigger the update check
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the update dialog is shown
      expect(find.text('Atualização Disponível'), findsOneWidget);
      expect(find.text('Uma nova versão (1.0.1) está disponível. Deseja baixar e instalar?'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
      expect(find.text('Sim, atualizar'), findsOneWidget);
    });

    testWidgets('shows no update message when no update is available', (WidgetTester tester) async {
      // Configure the mock to return no update
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate));

      // Build the app with a Scaffold
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: true,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      // Tap the button to trigger the update check
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the no update message is shown
      expect(find.text('Você já tem a versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error message when update check fails', (WidgetTester tester) async {
      // Configure the mock to return an error
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => UpdateCheckResult(
                UpdateCheckStatus.error,
                errorMessage: 'Network error',
              ));

      // Build the app with a Scaffold
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UpdateHelper.checkForUpdate(
                context,
                isManual: true,
                updateService: mockUpdateService,
              ),
              child: const Text('Check for updates'),
            ),
          ),
        ),
      ));

      // Tap the button to trigger the update check
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the error message is shown
      expect(find.text('Network error'), findsOneWidget);
    });
  });
}
