import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

// Gerar o mock
class MockUpdateHelper extends Mock implements UpdateHelper {}

void main() {
  group('AboutScreen', () {
    // Configurar o mock para o PackageInfo
    setUpAll(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Universal Notes',
        packageName: 'com.example.universal_notes',
        version: '1.0.0-test',
        buildNumber: '1',
        buildSignature: 'test-signature',
      );
    });

    testWidgets('renders Material UI components correctly',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AboutScreen(
              updateHelper: MockUpdateHelper(), // Usar o mock aqui
              packageInfo: PackageInfo(
                appName: 'Universal Notes',
                packageName: 'com.example.universal_notes',
                version: '1.0.0-test',
                buildNumber: '1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sobre'), findsOneWidget);
        expect(find.text('Versão atual: 1.0.0-test'), findsOneWidget);
        expect(find.text('Verificar Atualizações'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('shows CircularProgressIndicator when checking for update',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final mockUpdateHelper = MockUpdateHelper();

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AboutScreen(
              updateHelper: mockUpdateHelper, // Usar o mock aqui
              packageInfo: PackageInfo(
                appName: 'Universal Notes',
                packageName: 'com.example.universal_notes',
                version: '1.0.0-test',
                buildNumber: '1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final button = find.text('Verificar Atualizações');
        expect(button, findsOneWidget);

        // Configurar o mock para retornar um Future<void>
        when(mockUpdateHelper.checkForUpdate(any))
            .thenAnswer((_) async {});

        await tester.tap(button);
        await tester.pump(); // Pump uma vez para mostrar o indicador

        // Verificar se o indicador de progresso aparece
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('renders Fluent UI components correctly',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final mockUpdateHelper = MockUpdateHelper();

      try {
        await tester.pumpWidget(
          fluent.FluentApp(
            home: AboutScreen(
              updateHelper: mockUpdateHelper, // Usar o mock aqui
              packageInfo: PackageInfo(
                appName: 'Universal Notes',
                packageName: 'com.example.universal_notes',
                version: '1.0.0-test',
                buildNumber: '1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sobre'), findsOneWidget);
        expect(find.text('Versão atual: 1.0.0-test'), findsOneWidget);
        expect(find.text('Verificar Atualizações'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('shows ProgressRing when checking for update on Windows',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final mockUpdateHelper = MockUpdateHelper();

      try {
        await tester.pumpWidget(
          fluent.FluentApp(
            home: AboutScreen(
              updateHelper: mockUpdateHelper, // Usar o mock aqui
              packageInfo: PackageInfo(
                appName: 'Universal Notes',
                packageName: 'com.example.universal_notes',
                version: '1.0.0-test',
                buildNumber: '1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final button = find.text('Verificar Atualizações');
        expect(button, findsOneWidget);

        // Configurar o mock para retornar um Future<void>
        when(mockUpdateHelper.checkForUpdate(any))
            .thenAnswer((_) async {});

        await tester.tap(button);
        await tester.pump(); // Pump uma vez para mostrar o indicador

        // Verificar se o indicador de progresso aparece
        expect(find.byType(fluent.ProgressRing), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });
  });
}
