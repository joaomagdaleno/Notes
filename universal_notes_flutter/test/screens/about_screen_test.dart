import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  group('AboutScreen', () {
    testWidgets('renders Material UI components correctly',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AboutScreen(
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

        // Verifica se os componentes principais existem
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

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AboutScreen(
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

        // Tenta encontrar o botão e clica nele
        final button = find.text('Verificar Atualizações');
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Verifica se o indicador de progresso aparece
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('renders Fluent UI components correctly',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(
          fluent.FluentApp(
            home: AboutScreen(
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

        // Verifica se os componentes principais existem
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

      try {
        await tester.pumpWidget(
          fluent.FluentApp(
            home: AboutScreen(
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

        // Tenta encontrar o botão e clica nele
        final button = find.text('Verificar Atualizações');
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Verifica se o indicador de progresso aparece
        expect(find.byType(fluent.ProgressRing), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });
  });
}
