import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('builds Material UI on Android', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = original;
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('navigates to AboutScreen on Android',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = original;
      });

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });

    testWidgets('builds Fluent UI on Windows', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = original;
      });

      await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
    });

    testWidgets('navigates to AboutScreen on Windows',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = original;
      });

      await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });
}
