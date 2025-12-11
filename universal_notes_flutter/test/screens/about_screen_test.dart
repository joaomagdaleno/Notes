import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

class MockPackageInfo implements PackageInfo {
  @override
  final String appName = 'Universal Notes';

  @override
  final String buildNumber = '1';

  @override
  final String packageName = 'com.example.universal_notes';

  @override
  final String version = '1.0.0';

  @override
  final String buildSignature = 'test-signature';

  @override
  final Map<String, dynamic> data = {};

  @override
  final DateTime? installTime = DateTime.now();

  @override
  final String? installerStore = 'test-store';

  @override
  final DateTime? updateTime = DateTime.now();
}

void main() {
  // Mock do PackageInfo para ser usado em todos os testes
  final mockPackageInfo = MockPackageInfo();

  // Grupo de testes para a UI Material (Android/iOS)
  group('AboutScreen Material UI Tests', () {
    testWidgets('renders Material UI components correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os componentes da UI Material estão presentes
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Verificar Atualizações'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when checking for update',
        (WidgetTester tester) async {
      // Mock the UpdateService to simulate a long check.
      final mockUpdateService = MockUpdateService();
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 1)); // Simulate a long check.
          return UpdateCheckResult(UpdateCheckStatus.noUpdate);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            updateService: mockUpdateService,
            packageInfo: mockPackageInfo,
          ),
        ),
      );

      // Find and tap the update check button.
      final updateButton = find.byType(ElevatedButton);
      expect(updateButton, findsOneWidget);

      await tester.tap(updateButton);
      await tester.pump(); // Start the check.

      // FIX: Check if the CircularProgressIndicator appears.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // FIX: Check if the button is disabled.
      final button = tester.widget<ElevatedButton>(updateButton);
      expect(button.onPressed, isNull);

      // Complete the check.
      await tester.pumpAndSettle();

      // Check if the button is enabled again.
      final buttonAfter = tester.widget<ElevatedButton>(updateButton);
      expect(buttonAfter.onPressed, isNotNull);
    });
  });

  // Grupo de testes para a UI Fluent (Windows)
  group('AboutScreen Fluent UI (Windows) Tests', () {
    testWidgets('renders Fluent UI components correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: mockPackageInfo,
            debugPlatform: TargetPlatform.windows, // Force Windows UI
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os componentes da UI Fluent estão presentes
      expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
      expect(find.byType(fluent.PageHeader), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
      expect(find.byType(fluent.FilledButton), findsOneWidget);
      expect(find.text('Verificar Atualizações'), findsOneWidget);
    });

    testWidgets('shows ProgressRing when checking for update on Windows',
        (WidgetTester tester) async {
      // Mock the UpdateService to simulate a long check.
      final mockUpdateService = MockUpdateService();
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 1)); // Simulate a long check.
          return UpdateCheckResult(UpdateCheckStatus.noUpdate);
        },
      );

      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            updateService: mockUpdateService,
            packageInfo: mockPackageInfo,
            isWindows: true, // Ensure it's in Windows mode.
          ),
        ),
      );

      // Find and tap the update check button.
      final updateButton = find.byType(fluent.FilledButton);
      expect(updateButton, findsOneWidget);

      await tester.tap(updateButton);
      await tester.pump(); // Start the check.

      // FIX: Check if the ProgressRing appears.
      expect(find.byType(fluent.ProgressRing), findsOneWidget);

      // FIX: Check if the button is disabled.
      final button = tester.widget<fluent.FilledButton>(updateButton);
      expect(button.onPressed, isNull);

      // Complete the check.
      await tester.pumpAndSettle();

      // Check if the button is enabled again.
      final buttonAfter = tester.widget<fluent.FilledButton>(updateButton);
      expect(buttonAfter.onPressed, isNotNull);
    });
  });
}
