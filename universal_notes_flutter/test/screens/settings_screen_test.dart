import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    // We set up the mock data using the named argument method.
    // This is simpler and avoids constructor issues.
    setUpAll(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Universal Notes',
        packageName: 'com.example.universal_notes',
        version: '1.0.0-test',
        buildNumber: '1',
      );
    });

    testWidgets('builds Material UI on Android', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('navigates to AboutScreen on Android',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

        // Tap the ListTile itself, not just the text
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();

        // Now we can safely look for the AboutScreen by its type
        expect(find.byType(AboutScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('builds Fluent UI on Windows', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('navigates to AboutScreen on Windows',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));

        // Tap the ListTile itself, not just the text
        await tester.tap(find.byType(fluent.ListTile));
        await tester.pumpAndSettle();

        // Now we can safely look for the AboutScreen by its type
        expect(find.byType(AboutScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });
  });
}
