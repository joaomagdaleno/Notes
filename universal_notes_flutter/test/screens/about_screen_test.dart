import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  group('AboutScreen Tests', () {
    testWidgets('AboutScreen displays app information', (WidgetTester tester) async {
      const mockPackageInfo = PackageInfo(
        appName: 'Universal Notes',
        version: '1.0.0',
        buildNumber: '1',
        packageName: 'com.example.universal_notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );

      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
    });

    testWidgets('AboutScreen has correct accessibility label',
        (WidgetTester tester) async {
      const mockPackageInfo = PackageInfo(
        appName: 'Universal Notes',
        version: '1.0.0',
        buildNumber: '1',
        packageName: 'com.example.universal_notes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(packageInfo: mockPackageInfo),
        ),
      );

      // Verifica se o AboutScreen está presente
      expect(find.byType(AboutScreen), findsOneWidget);

      // Encontra todos os widgets Semantics
      final semanticsWidgets = find.byType(Semantics);
      expect(semanticsWidgets, findsWidgets);

      // Verifica se algum deles tem o rótulo correto
      var foundCorrectLabel = false;
      for (final element in semanticsWidgets.evaluate()) {
        final semantics = element.widget as Semantics;
        if (semantics.properties.label == 'About Universal Notes') {
          foundCorrectLabel = true;
          break;
        }
      }

      expect(foundCorrectLabel, isTrue,
          reason: 'Nenhum widget Semantics com rótulo "About Universal Notes" foi encontrado');
    });
  });
}