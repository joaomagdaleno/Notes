import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Material UI (Android)', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('builds and displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('navigates to AboutScreen on tap', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  group('SettingsScreen Fluent UI (Windows)', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('builds and displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));

      expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.byIcon(fluent.FluentIcons.info), findsOneWidget);
    });

    testWidgets('navigates to AboutScreen on tap', (WidgetTester tester) async {
      await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));

      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });
}
