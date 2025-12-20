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
        buildSignature: 'test-signature',
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

    testWidgets('navigates to AboutScreen on Android', (
      WidgetTester tester,
    ) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle(); // Wait for initial build and _packageInfo

        // Tap the ListTile itself, not just the text
        final listTileFinder = find.byType(ListTile);
        expect(listTileFinder, findsOneWidget);
        await tester.tap(listTileFinder);
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

    testWidgets('navigates to AboutScreen on Windows', (
      WidgetTester tester,
    ) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
        await tester.pumpAndSettle(); // Wait for initial build and _packageInfo

        // Tap the ListTile itself, not just the text
        final listTileFinder = find.byType(fluent.ListTile);
        expect(listTileFinder, findsOneWidget);
        await tester.tap(listTileFinder);
        await tester.pumpAndSettle();

        // Now we can safely look for the AboutScreen by its type
        expect(find.byType(AboutScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('returns to SettingsScreen after navigating back on Android', (
      WidgetTester tester,
    ) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();

        // Navigate to AboutScreen
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(find.byType(AboutScreen), findsOneWidget);

        // Navigate back
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should be back at SettingsScreen with loading reset
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('returns to SettingsScreen after navigating back on Windows', (
      tester,
    ) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
        await tester.pumpAndSettle();

        // Navigate to AboutScreen
        await tester.tap(find.byType(fluent.ListTile));
        await tester.pumpAndSettle();
        expect(find.byType(AboutScreen), findsOneWidget);

        // Navigate back
        await tester.tap(find.byIcon(fluent.FluentIcons.back));
        await tester.pumpAndSettle();

        // Check if AboutScreen is gone
        expect(find.byType(AboutScreen), findsNothing);

        // Should be back
        // Using skipOffstage: false to debug if it's there but hidden
        expect(
          find.byType(SettingsScreen, skipOffstage: false),
          findsOneWidget,
        );
        expect(find.byType(fluent.ProgressRing), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });
  });
}
