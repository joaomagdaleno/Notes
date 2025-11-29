import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  group('AboutScreen General Tests', () {
    // Mock PackageInfo data
    final mockPackageInfo = PackageInfo(
      appName: 'Universal Notes',
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'com.example.universal_notes',
    );

    setUp(() {
      // Mock the fromPlatform method to return our mock data
      TestWidgetsFlutterBinding.ensureInitialized();
      PackageInfo.setMockInitialValues(
        appName: mockPackageInfo.appName,
        packageName: mockPackageInfo.packageName,
        version: mockPackageInfo.version,
        buildNumber: mockPackageInfo.buildNumber,
        buildSignature: '',
      );
    });

    testWidgets('AboutScreen renders correctly in light and dark themes',
        (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle(); // Wait for version to load
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle(); // Wait for version to load
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
    });

    testWidgets('AboutScreen displays social media links if they exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Since there are no social media icons, we expect not to find them.
      // This test is conditional, as discussed.
      final githubIcon = find.byIcon(Icons.code);
      final twitterIcon = find.byIcon(Icons.alternate_email);

      expect(githubIcon, findsNothing);
      expect(twitterIcon, findsNothing);
    });

    testWidgets('AboutScreen handles long press actions without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Test long press on the version text
      await tester.longPress(find.text('Versão atual: 1.0.0'));
      await tester.pump();

      // Verify that no errors or unexpected behaviors occurred
      expect(tester.takeException(), isNull);
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  group('AboutScreen Platform and Accessibility Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PackageInfo.setMockInitialValues(
        appName: 'Universal Notes',
        packageName: 'com.example.universal_notes',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    testWidgets('AboutScreen displays Material Design on Android',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Material Design specific elements
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Clean up the platform override
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('AboutScreen displays Fluent UI on Windows',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(
        const fluent.FluentApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Fluent UI specific elements
      expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
      expect(find.byType(fluent.FilledButton), findsOneWidget);

      // Clean up the platform override
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('AboutScreen has correct accessibility label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the Semantics label we added
      expect(find.bySemanticsLabel('About Universal Notes'), findsOneWidget);
    });
  });

  group('AboutScreen Integration Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      PackageInfo.setMockInitialValues(
        appName: 'Universal Notes',
        packageName: 'com.example.universal_notes',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    testWidgets('AboutScreen can be navigated to', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Home')),
                  body: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/about');
                      },
                      child: const Text('Go to About'),
                    ),
                  ),
                ),
            '/about': (context) => const AboutScreen(),
          },
        ),
      );

      // Navigate to the About screen
      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      // Verify that the About screen was loaded
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
    });
  });
}
