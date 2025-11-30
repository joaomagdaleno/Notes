import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  group('AboutScreen General Tests', () {
    final mockPackageInfo = PackageInfo(
      appName: 'Universal Notes',
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'com.example.universal_notes',
    );

    setUp(() {
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
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();
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

      await tester.longPress(find.text('Versão atual: 1.0.0'));
      await tester.pump();

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

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

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

      // Encontra o widget Semantics específico que envolve o AboutScreen
      final aboutScreenFinder = find.byType(AboutScreen);
      final semanticsFinder = find.descendant(
        of: aboutScreenFinder,
        matching: find.bySemanticsLabel('About Universal Notes'),
      );

      expect(semanticsFinder, findsOneWidget);
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

    testWidgets('AboutScreen can be navigated to',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Home')),
                  body: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/about');
                      },
                      child: const Text('Go to About'),
                    ),
                  ),
                ),
            '/about': (context) => const AboutScreen(),
          },
        ),
      );

      await tester.tap(find.text('Go to About'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });
}
