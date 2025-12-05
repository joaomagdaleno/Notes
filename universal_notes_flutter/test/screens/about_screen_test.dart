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

    testWidgets('shows CircularProgressIndicator when checking for update', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );

      // Tapa no botão para iniciar a verificação
      await tester.tap(find.byType(ElevatedButton));
      await tester
          .pump(); // Reconstrói o widget uma vez para mostrar o indicador

      // Verifica se o CircularProgressIndicator aparece
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
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

    testWidgets('shows ProgressRing when checking for update on Windows', (
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

      // Tapa no botão para iniciar a verificação
      await tester.tap(find.byType(fluent.FilledButton));
      await tester
          .pump(); // Reconstrói o widget uma vez para mostrar o indicador

      // Verifica se o ProgressRing aparece
      expect(find.byType(fluent.ProgressRing), findsOneWidget);
      expect(find.byType(fluent.FilledButton), findsNothing);
    });
  });
}
